class SmsNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, attendee, _final_price)
    message = "You're registered for #{event[:name]}!"
    notifications << "SMS: #{attendee[:phone]} - #{message}"
  end

  def send_waitlist(event, attendee)
    message = "Waitlisted for #{event[:name]}."
    notifications << "SMS: #{attendee[:phone]} - #{message}"
  end

  def send_cancellation(event, attendee, cancellation_message)
    message = "Cancelled: #{event[:name]}."
    notifications << "SMS: #{attendee[:phone]} - #{message}"
  end

  def send_promotion(event, attendee, price)
    message = "Promoted from waitlist: #{event[:name]}!"
    notifications << "SMS: #{attendee[:phone]} - #{message}"
  end
end
