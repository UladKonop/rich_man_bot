class FetchLatestTendersJob < CronJob
  self.cron_expression = '* * * * *'

  def perform
    # FetchLatestTendersService.new.call
  end
end
