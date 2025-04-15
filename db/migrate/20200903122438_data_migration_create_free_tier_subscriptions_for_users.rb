class DataMigrationCreateFreeTierSubscriptionsForUsers < ActiveRecord::Migration[7.1]
  def up
    users_without_subscripton = User
                                .left_outer_joins(:subscription)
                                .where(subscriptions: { id: nil })

    users_without_subscripton.ids.each do |user_id|
      Subscription.build_with_free_tier(user_id).save
    end
  end

  def down; end
end
