class PaymentsController <  ActionController::Base
  append_view_path Rails.root.join("/app/views")
  layout 'application'
  
  def new
    chat_id = params[:chat_id]
    @subscriptions = Subscription.plans.map do |plan|
      OpenStruct.new(
        plan.merge(label: JSON(subscription_type: plan[:type], chat_id: chat_id))
      )
    end
  end
end
