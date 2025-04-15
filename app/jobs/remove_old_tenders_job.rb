class RemoveOldTendersJob < CronJob
  self.cron_expression = '0 5 */2 * *'

  def perform
	  RemoveOldTendersService.new.call
  end
end
