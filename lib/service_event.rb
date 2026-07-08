require_relative './event'
class ServiceEvent < Event
  def calculate_price
    price
  end

  def registration_notification_formats
    [ :email ]
  end

  def waitlist_notification_formats
    [ :email ]
  end

  def cancellation_notification_formats
    [ :email ]
  end
end
