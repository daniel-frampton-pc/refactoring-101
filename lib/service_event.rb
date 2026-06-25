require_relative './event'
class ServiceEvent < Event
  def calculate_price
    price
  end

  def registration_notification_formats
    [ :email ]
  end
end
