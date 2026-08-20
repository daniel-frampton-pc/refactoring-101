require './lib/email_notifier.rb'
require './lib/sms_notifier.rb'
require './lib/slack_notifier.rb'

class Notifier
  attr_accessor :notifications_sent

  def initialize
    @notifications_sent = []
  end

  FORMAT_TO_NOTIFIER_CLASS = {
    email: EmailNotifier.new,
    sms: SmsNotifier.new,
    slack: SlackNotifier.new
  }.freeze

  def send_registration_notifications(event, attendee, final_price)
    event.registration_notification_formats.each do |format|
      next if format == :sms && !attendee[:phone]

      notifier = FORMAT_TO_NOTIFIER_CLASS[format]
      sent = notifier.send_registration({name: event.name}, attendee, final_price)

      notifications_sent << sent
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
    cancellation_message = event.cancellation_policy
    email_message += " #{cancellation_message}" if cancellation_message
    sms_message = "Cancelled: #{event.name}."

    event.cancellation_notification_formats.each do |format|
      next if format == :sms && !attendee[:phone]

      contact = format == :email ? attendee[:email] : attendee[:phone]
      message = format == :sms ? sms_message : email_message

      notifications_sent << "#{format.upcase}: #{contact} - #{message}"
    end
  end

  def send_promote_from_waitlist_notification(event, attendee)
    email_message = "You've been promoted from the waitlist for #{event.name}! Amount: $#{event.price}"
    sms_message = "Promoted from waitlist: #{event.name}!"

    event.promote_from_waitlist_notification_formats.each do |format|
      next if format == :sms && !attendee[:phone]

      contact = format == :email ? attendee[:email] : attendee[:phone]
      message = format == :sms ? sms_message : email_message

      notifications_sent << "#{format.upcase}: #{contact} - #{message}"
    end
  end

  def send_remove_from_waitlist_notification(event, attendee)
    email_message = "You've been removed from the waitlist for #{event.name}."

    event.remove_from_waitlist_notification_formats.each do |format|
      contact = attendee[:email]
      message = email_message

      notifications_sent << "#{format.upcase}: #{contact} - #{message}"
    end
  end

  private

  def build_message(format, recipient, content)
     "#{format.to_s.upcase}: #{recipient} - #{content}"
  end
end
