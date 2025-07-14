# Rich Man Bot

Rich Man Bot is a personal finance assistant Telegram bot designed to help you track your expenses, manage categories, and analyze your spending habits. With features like period-based summaries, category management, and export/import options, it makes budgeting and financial tracking simple and accessible right from your chat.

👉 Try it on Telegram: [@treasure_tracker_bot](https://t.me/treasure_tracker_bot)

## 🚀 Deployment Instructions

```bash
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml exec web rails db:migrate
docker-compose -f docker-compose.prod.yml exec web bin/delayed_job start
docker-compose -f docker-compose.prod.yml exec web rake telegram:bot:set_webhook

# To stop and remove containers:
docker-compose down --remove-orphans 
```

---

## 🤖 Telegram Bot Setup

### Webhook Setup

- [Telegram Webhooks Documentation](https://core.telegram.org/bots/webhooks)
- [https-portal (SSL)](https://github.com/steveltn/https-portal)

```ruby
url = "https://richmanbot.space/telegram/TOKEN"
Telegram.bot.set_webhook(url: url)
Telegram.bot.set_webhook(url: url, certificate: File.open('./YOURPUBLIC.pem'))
Telegram.bot.delete_webhook
Telegram.bot.get_webhook_info
```

### Poller Startup

```bash
# Option 1
docker-compose -f docker-compose.prod.yml exec web bin/telegram_bot start
docker-compose -f docker-compose.prod.yml exec web bin/rails telegram:bot:poller

# Option 2
docker-compose -f docker-compose.prod.yml exec web rails c
# In Rails console:
Telegram::Bot::UpdatesPoller.new(Telegram.bots[:default], TelegramWebhooksController).start
```

> 💡 You can also uncomment the poller section in `docker-compose.prod.yml` for automatic startup.

### Remove Webhook for Poller Mode

- Use: `https://api.telegram.org/botTOKEN/setWebhook`

---

## 🛠️ Useful Commands

### Get User IDs with Expense Count (Last 30 Days)

```ruby
User.joins(:expenses)
    .where('expenses.date >= ?', 30.days.ago.to_date)
    .group(:id)
    .pluck(:id, 'COUNT(expenses.id)')
```

### Restore Database from Production to Local

```bash
psql -d rich_man_bot_development -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
psql -d rich_man_bot_development < ./15-06-2025-rich-man-bot-backup.sql 
```

---

## 📋 TODO

- [ ] Hide the "Previous Periods" button if there are no previous periods
- [ ] Add the ability to edit the expense date
- [ ] Display the total sum after each entry for the current period
- [ ] Update locales and improve function descriptions
- [ ] Write a user guide/instructions
- [ ] Come up with a name and icon for the bot
- [ ] Write a description for the bot
- [ ] Always enable the input parser
- [ ] Add synonyms/abbreviations for categories
- [ ] Add export functionality
- [ ] Import functionality?
- [ ] Move the category total to the bottom (may not be needed anymore due to compact view)
- [ ] Decide how category deletion should work (only if empty, or otherwise?)
