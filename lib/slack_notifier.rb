class SlackNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, _attendee, final_price)
    message = "#{intro} Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
    notifications << message
    message
  end

  def send_waitlist(event, _attendee)
    message = "#{intro} You're on the waitlist for #{event[:name]}."
    notifications << message
    message
  end

  def send_cancellation(event, attendee, cancellation_message)
    message = "#{intro} Registration cancelled for #{event[:name]}"
    message += " #{cancellation_message}" if cancellation_message

    notifications << message
    message
  end

  def send_promotion(event, attendee, price)
    message = "#{intro} You've been promoted from the waitlist for #{event[:name]}! Amount: $#{price}"
    notifications << message
    message
  end

  def intro
    "SLACK: #events -"
  end
end
