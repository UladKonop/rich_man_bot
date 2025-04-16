namespace :subscription do
  desc "Create free tier subscriptions for users who don't have one"
  task create_free_tier: :environment do
    users_without_subscription = User
                                .left_outer_joins(:subscription)
                                .where(subscriptions: { id: nil })

    count = 0
    users_without_subscription.ids.each do |user_id|
      if Subscription.build_with_free_tier(user_id).save
        count += 1
      end
    end

    puts "Created #{count} free tier subscriptions"
  end

  desc "Extend user's subscription period by specified number of days"
  task :extend, [:user_id, :days] => :environment do |_task, args|
    unless args[:user_id] && args[:days]
      puts "Usage: rake subscription:extend[user_id,days]"
      exit 1
    end

    user = User.find_by(id: args[:user_id])
    unless user
      puts "User with ID #{args[:user_id]} not found"
      exit 1
    end

    subscription = user.subscription
    unless subscription
      puts "User #{user.id} doesn't have a subscription"
      exit 1
    end

    days = args[:days].to_i
    if days <= 0
      puts "Days must be a positive number"
      exit 1
    end

    new_end_date = subscription.end_date + days.days
    if subscription.update(end_date: new_end_date)
      puts "Successfully extended subscription for user #{user.id} by #{days} days"
      puts "New end date: #{new_end_date}"
    else
      puts "Failed to extend subscription: #{subscription.errors.full_messages.join(', ')}"
    end
  end

  desc "Expire user's subscription immediately"
  task :expire, [:user_id] => :environment do |_task, args|
    unless args[:user_id]
      puts "Usage: rake subscription:expire[user_id]"
      exit 1
    end

    user = User.find_by(id: args[:user_id])
    unless user
      puts "User with ID #{args[:user_id]} not found"
      exit 1
    end

    subscription = user.subscription
    unless subscription
      puts "User #{user.id} doesn't have a subscription"
      exit 1
    end

    if subscription.update(end_date: Time.current)
      puts "Successfully expired subscription for user #{user.id}"
    else
      puts "Failed to expire subscription: #{subscription.errors.full_messages.join(', ')}"
    end
  end
end 