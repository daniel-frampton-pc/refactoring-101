require_relative './event'
class WorkshopEvent < Event
  def calculate_price
    if early_bird_price && registered.size <= (capacity / 2)
      early_bird_price
    else
      price
    end
  end

  def registration_notification_formats
    [ :email, :sms ]
  end

  def waitlist_notification_formats
    [ :email, :sms ]
  end

  def cancellation_notification_formats
    [ :email, :sms ]
  end
end
