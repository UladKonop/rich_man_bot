# README

* Deployment instructions
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml exec web rails db:migrate
docker-compose -f docker-compose.prod.yml exec web bin/delayed_job start
docker-compose -f docker-compose.prod.yml exec web rake telegram:bot:set_webhook

docker-compose down --remove-orphans 

# poller startup
# docker-compose -f docker-compose.prod.yml exec web bin/telegram_bot start
# docker-compose -f docker-compose.prod.yml exec web bin/rails telegram:bot:poller

# poller startup alternative
# docker-compose -f docker-compose.prod.yml exec web rails c
#   Telegram::Bot::UpdatesPoller.new(Telegram.bots[:default], TelegramWebhooksController).start

# or just uncomment poller section in docker.compose.prod.yml  

https://api.telegram.org/botTOKEN/setWebhook - remove webhook for poller using

* webhooks setup
https://core.telegram.org/bots/webhooks
https://github.com/steveltn/https-portal
```ruby
url = "https://richmanbot.space/telegram/TOKEN"
Telegram.bot.set_webhook(url: url)
Telegram.bot.set_webhook(url: url, certificate: File.open('./YOURPUBLIC.pem'))
Telegram.bot.delete_webhook
Telegram.bot.get_webhook_info
```
* ...

User.joins(:expenses).where('expenses.date >= ?', 30.days.ago.to_date).group(:id).pluck(:id, 'COUNT(expenses.id)')

# TODO
- скрыть кнопку "предыдущие периоды" если таких не было
- добавить возможность редактировать дату растраты
- выводить общую сумму после каждого ввода за текущий период
- обновить локали, добавить лучшее описание функций
- сделать инструкцию
- придумать название для бота и иконку
- придумать описание для бота
- добавить парсер для ввода всегда
- добавить синонимы-сокращения к категории
- добавить экспорт
- импорт?
- перенести сумму по категории вниз(может уже и не нужно, потому что внешний вид внутри категории уже сильно компактнее стал)
- решить как будет работать удаление категории(только пустая или как-то ещё)