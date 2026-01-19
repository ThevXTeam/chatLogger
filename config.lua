-- chatLogger configuration
return {
  -- Local storage directory (absolute path)
  logDir = "/chatlogs",

  -- Event name to listen for. Common values: "chat_message" or "chat".
  chatEventName = "chat_message",

  -- Remote upload settings
  remote = {
    enabled = false, -- set true to enable remote uploads
    method = "webhook", -- "webhook" or "paste"
    -- For webhook (Discord style): set your webhook URL
    webhookURL = "",
    -- For paste: Hastebin-like endpoint (no auth)
    pasteUrl = "https://hastebin.com/documents",
    pasteBase = "https://hastebin.com/",
    -- Webhook presentation defaults
    color = 8392720,
    flags = 4096,
  },
}
