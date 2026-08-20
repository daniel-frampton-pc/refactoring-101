class EmailNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, attendee, final_price)
    message = "Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
    full_msg = "EMAIL: #{attendee[:email]} - #{message}"
    notifications << full_msg
    full_msg
  end

  def send_waitlist(event, attendee)
    message = "You're on the waitlist for #{event[:name]}."
    full_msg = "EMAIL: #{attendee[:email]} - #{message}"
    notifications << full_msg
    full_msg
  end

  def send_cancellation(event, attendee, cancellation_message)
    message = "Registration cancelled for #{event[:name]}."
    message += " #{cancellation_message}" if cancellation_message

    full_msg = "EMAIL: #{attendee[:email]} - #{message}"
    notifications << full_msg
    full_msg
  end

  def send_promotion(event, attendee, price)
    message = "You've been promoted from the waitlist for #{event[:name]}! Amount: $#{price}"
    full_msg = "EMAIL: #{attendee[:email]} - #{message}"
    notifications << full_msg
    full_msg
  end
end
