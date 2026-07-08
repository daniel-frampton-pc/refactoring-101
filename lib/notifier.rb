class Notifier
  attr_accessor :notifications_sent

  def initialize
    @notifications_sent = []
  end

  def send_registration_notifications(event, attendee, final_price)
    email_message = "Registration confirmed for #{event.name}. Amount: $#{final_price}"
    sms_message = "You're registered for #{event.name}!"

    event.registration_notification_formats.each do |format|
      next if format == :sms && !attendee[:phone]

      contact = format == :email ? attendee[:email] : attendee[:phone]
      message = format == :sms ? sms_message : email_message

      notifications_sent << "#{format.upcase}: #{contact} - #{message}"
    end
  end

  def send_waitlist_notifications(event, attendee)
    email_message = "You're on the waitlist for #{event.name}."
    sms_message = "Waitlisted for #{event.name}."

    event.waitlist_notification_formats.each do |format|
      next if format == :sms && !attendee[:phone]

      contact = format == :email ? attendee[:email] : attendee[:phone]
      message = format == :sms ? sms_message : email_message

      notifications_sent << "#{format.upcase}: #{contact} - #{message}"
    end
  end

  def send_cancellation_notifications(event, attendee, registration)
    case event[:event_type]
    when :service
      notifications_sent << "EMAIL: #{attendee[:email]} - Registration cancelled for #{event[:name]}"
    when :workshop
      notifications_sent << "EMAIL: #{attendee[:email]} - Registration cancelled for #{event[:name]}"
      notifications_sent << "SMS: #{attendee[:phone]} - Cancelled: #{event[:name]}" if attendee[:phone]
    when :retreat
      refund_info = " Refund of $#{registration[:price]} will be processed within 5-7 business days."
      notifications_sent << "EMAIL: #{attendee[:email]} - Registration cancelled for #{event[:name]}.#{refund_info}"
      notifications_sent << "SMS: #{attendee[:phone]} - Cancelled: #{event[:name]}" if attendee[:phone]
    end
  end

  def send_promote_from_waitlist_notification(event, attendee)
    notifications_sent << "EMAIL: #{attendee[:email]} - You've been promoted from the waitlist for #{event[:name]}! Amount: $#{event[:price]}"
    notifications_sent << "SMS: #{attendee[:phone]} - Promoted from waitlist: #{event[:name]}!" if attendee[:phone]
  end

  def send_remove_from_waitlist_notification(event, attendee)
    notifications_sent << "EMAIL: #{attendee[:email]} - Removed from waitlist for #{event[:name]}"
  end

  private

  def build_message(format, recipient, content)
     "#{format.to_s.upcase}: #{recipient} - #{content}"
  end
end
