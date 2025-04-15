class RemoveOldTendersService
	OLD = 8.days.ago

	def call
		Tender
			.where(Tender.arel_table[:created_at].lt(OLD))
			.destroy_all
	end
end
