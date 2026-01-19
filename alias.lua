-- create a `chatLogger` alias that delegates to `bg /vx/chatLogger/main.lua` when available
if fs.exists("/vx/chatLogger/main.lua") then
  pcall(function() shell.setAlias("chatLogger", "background /vx/chatLogger/main.lua") end)
else
  print("No chatLogger script found at /vx/chatLogger/main.lua")
end