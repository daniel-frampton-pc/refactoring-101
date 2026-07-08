class Notifier
  attr_accessor :notifications_sent

  RETREAT_EVENT_TYPE = :retreat

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
    email_message = "Registration cancelled for #{event.name}."
    email_message += " Refund of $#{registration[:price]} will be processed within 5-7 business days." if is_retreat_event?(event)
    sms_message = "Cancelled: #{event.name}."

    event.cancellation_notification_formats.each do |format|
      next if format == :sms && !attendee[:phone]

      contact = format == :email ? attendee[:email] : attendee[:phone]
      message = format == :sms ? sms_message : email_message

      notifications_sent << "#{format.upcase}: #{contact} - #{message}"
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

  def is_retreat_event?(event)
    event.type == RETREAT_EVENT_TYPE
  end
end
