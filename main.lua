local textutils = textutils

-- Robust config loading: try require, then common file locations
local config = nil
do
	local ok, c = pcall(require, "config")
	if ok and type(c) == "table" then
		config = c
	else
		local tried = {"/repos/chatLogger/config.lua", "repos/chatLogger/config.lua", "config.lua"}
		for _, p in ipairs(tried) do
			if fs.exists(p) then
				local ok2, c2 = pcall(dofile, p)
				if ok2 and type(c2) == "table" then config = c2 break end
			end
		end
	end
	if not config then
		config = { logDir = "/chatlogs", chatEventName = "chat", remote = { enabled = false } }
	end
end

term.clear()
print("chatLogger starting...")
print("Config: remote.enabled=" .. tostring((config.remote and config.remote.enabled) and true or false))

local function ensureDir(path)
	if not fs.exists(path) then
		fs.makeDir(path)
	end
end

local function timestamp()
	if os and os.date then
		return os.date("%Y-%m-%d %H:%M:%S")
	end
	return tostring(os.time and os.time() or math.floor(os.clock()))
end

local function appendToFile(line)
	local dir = config.logDir or "/chatlogs"
	ensureDir(dir)
	local filename = dir .. "/" .. (os.date and os.date("%Y-%m-%d") or "log") .. ".log"
	local fh = fs.open(filename, "a")
	if fh then
		fh.writeLine(line)
		fh.close()
	else
		print("Failed to open log file: " .. filename)
	end
end

local function sendWebhook(url, username, content, uuid, ts)
	if not http then return false, "http unavailable" end
	print("[chatLogger] Posting webhook to: " .. tostring(url))
	local color = (config.remote and config.remote.color) or 8392720
	local flags = (config.remote and config.remote.flags) or 4096
	local embed = {
		title = tostring(content or ""),
		description = tostring((ts or timestamp()) .. (uuid and (" - " .. uuid) or "")),
		color = color,
		author = { name = tostring(username or "unknown"), icon_url = "https://mc-heads.net/avatar/" .. (username or "") }
	}
	local embed_array = textutils and textutils.serializeJSON and textutils.serializeJSON({embed}) or '[]'
	-- Build final payload JSON with content:null, embeds, attachments empty, and flags
	local payload = '{"content":null,"embeds":' .. embed_array .. ',"attachments":[],"flags":' .. tostring(flags) .. '}'
	local headers = { ["Content-Type"] = "application/json" }
	print("[chatLogger] webhook payload: " .. tostring(payload))
    local ok, resp = pcall(http.post, url, payload, headers)
    
	if not ok or not resp then
		print("[chatLogger] webhook http.post failed: " .. tostring(resp))
		return false, tostring(resp)
	end
	local body = nil
	if resp.readAll then body = resp.readAll() end
	print("[chatLogger] webhook response: " .. tostring(body))
	return true, body or resp
end

local function sendPaste(content)
	if not http then return false, "http unavailable" end
	-- try Hastebin-like endpoint (no auth)
	local ok, resp = pcall(http.post, config.remote.pasteUrl or "https://hastebin.com/documents", content)
	if not ok or not resp then return false, tostring(resp) end
	-- resp should be JSON like {key="..."}
	local body = resp.readAll and resp.readAll() or tostring(resp)
	local ok2, j = pcall(textutils.unserializeJSON, body)
	if ok2 and j and j.key then
		return true, (config.remote.pasteBase or "https://hastebin.com/") .. j.key
	end
	return false, body
end

local function sendRemote(username, message, uuid)
	if not config.remote or not config.remote.enabled then return end
	if config.remote.method == "webhook" and config.remote.webhookURL and config.remote.webhookURL ~= "" then
		local ok, resp = sendWebhook(config.remote.webhookURL, username, message, uuid)
		if not ok then print("Remote webhook failed: " .. tostring(resp)) end
	elseif config.remote.method == "paste" then
		local ok, resp = sendPaste(string.format("[%s] <%s> %s", timestamp(), username, message))
		if ok then print("Pasted: " .. tostring(resp)) else print("Paste failed: " .. tostring(resp)) end
	end
end

print("chatLogger running. Logging to: " .. (config.logDir or "/chatlogs"))
while true do
	local ev = { os.pullEvent() }
	local name = ev[1]

	-- AdvancedPeripherals 'chat' event signature: username, message, uuid, isHidden
	if name == "chat" or (config.chatEventName and name == config.chatEventName) then
		local username = ev[2] or "unknown"
		local message = ev[3] or ""
		local uuid = ev[4]
		local isHidden = ev[5]

		if config.ignoreHidden and isHidden then
			-- skip hidden messages
		else
			local line = string.format("[%s] <%s> %s", timestamp(), username, message)
			if uuid then line = line .. string.format(" (uuid=%s)", uuid) end
			appendToFile(line)
			sendRemote(username, message)
		end

	elseif name == "chat_message" then
		-- fallback for other systems that may emit different chat events
		local author = ev[2] or "unknown"
		local message = ev[3] or ""
		local line = string.format("[%s] <%s> %s", timestamp(), author, message)
		appendToFile(line)
		sendRemote(author, message)
	end
end
