class SlackNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, _attendee, final_price)
    message = "Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
    notifications << "SLACK: #events - #{message}"
  end
end
