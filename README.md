# Printer telegram bot
For printing, just attach pdf document to telegram bot.<br>
I am using singleboard computer for home automation. The computer runs on debian and has installed printer drivers. The bot uses default printer and prints only files attached from Master.  Master can be Telegram group.
I use this bot to print documents from phone, or away from home. With [Notebloc](https://play.google.com/store/apps/details?id=com.notebloc.app) it is an easy document copier.<br>

1. Create a New Bot for Telegram, or use your existing bot.
2. Creafe file config.ini with content:
 <pre>
  [general]
  botKey = "telegram bot key"
  master = "master id, can be a group"
  </pre>
3. Execute `printer_bot.sh`
