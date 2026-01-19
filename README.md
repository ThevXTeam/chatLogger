# chatLogger

The goal of this project is to log minecraft chat messages using the chatbox from AdvancedPeripherals.

Usage
-
1. Edit `repos/chatLogger/config.lua` to set `remote.enabled` and provide a `webhookURL` if using webhooks.
2. Run the program inside a CraftOS/CC:Tweaked computer (or emulator):

```lua
shell.run("/repos/chatLogger/main.lua")
```

What it does
-
- Appends chat lines to a daily file under `/chatlogs/YYYY-MM-DD.log`.
- Optionally posts each message to a remote endpoint:
	- `webhook`: send JSON {content: "<line>"} (works with Discord webhooks)
	- `paste`: POSTs content to a Hastebin-like `/documents` endpoint and prints the returned URL.

Notes
-
- No API keys are required for the paste method (uses public Hastebin endpoint).
- Ensure HTTP is enabled in your emulator settings to allow remote uploads.
- If the chatbox produces a different event name, change `chatEventName` in `config.lua`.

Files
-
- [repos/chatLogger/main.lua](repos/chatLogger/main.lua#L1-L200)
- [repos/chatLogger/config.lua](repos/chatLogger/config.lua#L1-L200)