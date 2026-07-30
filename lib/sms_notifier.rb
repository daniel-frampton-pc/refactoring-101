class SmsNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, attendee, _final_price)
    message = "You're registered for #{event[:name]}!"
    notifications << "SMS: #{attendee[:phone]} - #{message}"
  end
end
