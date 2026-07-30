class EmailNotifier
  attr_accessor :notifications

  def initialize
    @notifications = []
  end

  def send_registration(event, attendee, final_price)
    message = "Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
    notifications << "EMAIL: #{attendee[:email]} - #{message}"
  end
end
