class SmsNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, attendee, _final_price)
    full_msg = "SMS: #{attendee[:phone]} - You're registered for #{event[:name]}!"
    notifications << full_msg
    full_msg
  end

  def send_waitlist(event, attendee)
    full_msg = "SMS: #{attendee[:phone]} - Waitlisted for #{event[:name]}."
    notifications << full_msg
    full_msg
  end

  def send_cancellation(event, attendee, cancellation_message)
    full_msg = "SMS: #{attendee[:phone]} - Cancelled: #{event[:name]}."
    notifications << full_msg
    full_msg
  end

  def send_promotion(event, attendee, price)
    full_msg = "SMS: #{attendee[:phone]} - Promoted from waitlist: #{event[:name]}!"
    notifications << full_msg
    full_msg
  end
end
