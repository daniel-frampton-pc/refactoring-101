class SlackNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, _attendee, final_price)
    message = "Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
    notifications << "SLACK: #events - #{message}"
  end

  def send_waitlist(event, _attendee)
     message = "You're on the waitlist for #{event[:name]}."
     notifications << "SLACK: #events - #{message}"
  end

  def send_cancellation(event, attendee, cancellation_message)
    message = "Registration cancelled for #{event[:name]}"
    message += " #{cancellation_message}" if cancellation_message

    notifications << "SLACK: #events - #{message}"
  end

  def send_promotion(event, attendee, price)
    message = "You've been promoted from the waitlist for #{event[:name]}! Amount: $#{price}"
    notifications << "SLACK: #events - #{message}"
  end
end
