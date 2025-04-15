class NewTendersNotifyerJob < CronJob
  self.cron_expression = '* * * * *'

  def perform
    NewTenderNotifyerService.new.call
  end
end
