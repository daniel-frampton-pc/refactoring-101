# frozen_string_literal: true

require_relative "test_helper"

# =============================================================================
# Step 05: Interface Segregation Principle (ISP)
# =============================================================================
#
# No client should be forced to depend on methods it doesn't use.
#
# After the OCP refactoring, Notifier probably delegates to event type objects
# for channel selection. But try adding Slack: it doesn't need a contact
# address at all, it posts to a channel name.
# SMS doesn't need price info. Each channel has fundamentally different data
# needs, yet they're all crammed into one class.
#
# First make the change easy: split Notifier into EmailNotifier and
# SmsNotifier. Each class extracts only the data it needs from the event and
# attendee hashes. All notifiers share the same method signatures -- this
# makes them interchangeable and will enable polymorphic dispatch later.
#
# Now make the easy change: add a SlackNotifier that posts to #events and
# ignores contact info entirely. Wire it into conference events so they
# notify via email, SMS, and Slack.
#
# HINT: Let the tests be your guide. Each notifier exposes its own
# `notifications` array, and the original Notifier class goes away entirely.
#
# HINT: The safety-net tests still expect RegistrationSystem#notifications_sent
# to contain everything. Think about how you'll aggregate notifications from
# individual notifiers back into that single array.
#
# =============================================================================

class InterfaceSegregationTest < Minitest::Test
  # -- EmailNotifier sends email-formatted notifications ----------------------

  def test_email_notifier_sends_registration_notification
    # skip "Split Notifier into focused, single-channel classes"

    notifier = EmailNotifier.new
    event = { name: "Workshop" }
    attendee = { email: "alice@example.com" }

    notifier.send_registration(event, attendee, 50)

    assert_equal 1, notifier.notifications.size
    assert_match(/\AEMAIL: alice@example.com/, notifier.notifications[0])
  end

  # -- SmsNotifier sends SMS-formatted notifications --------------------------

  def test_sms_notifier_sends_registration_notification
    # skip "Split Notifier into focused, single-channel classes"

    notifier = SmsNotifier.new
    event = { name: "Workshop" }
    attendee = { phone: "555-0101" }

    notifier.send_registration(event, attendee, 50)

    assert_equal 1, notifier.notifications.size
    assert_match(/\ASMS: 555-0101/, notifier.notifications[0])
  end

  # -- SlackNotifier sends Slack-formatted registration notifications ---------

  def test_slack_notifier_sends_registration_notification
    # skip "Add a SlackNotifier that sends SLACK: #events - ... messages"

    notifier = SlackNotifier.new
    event = { name: "Workshop" }
    attendee = {}

    notifier.send_registration(event, attendee, 50)

    assert_equal 1, notifier.notifications.size
    assert_match(/\ASLACK: #events - /, notifier.notifications[0])
  end

  # -- SlackNotifier produces no email or SMS ---------------------------------

  def test_slack_notifier_produces_no_email_or_sms
    skip "SlackNotifier produces only SLACK: messages, never EMAIL: or SMS:"

    notifier = SlackNotifier.new
    event = { name: "Workshop" }
    attendee = {}

    notifier.send_registration(event, attendee, 50)
    notifier.send_waitlist(event, attendee)
    notifier.send_cancellation(event, attendee, "")
    notifier.send_promotion(event, attendee, 50)

    refute notifier.notifications.any? { |n| n.start_with?("EMAIL:") },
           "SlackNotifier should NOT produce EMAIL: notifications"
    refute notifier.notifications.any? { |n| n.start_with?("SMS:") },
           "SlackNotifier should NOT produce SMS: notifications"
  end

  # -- Full system: conference with Slack produces all three channels ----------

  def test_conference_registration_sends_email_sms_and_slack
    skip "Wire SlackNotifier into the system -- conference events use all three channels"

    system = RegistrationSystem.new
    system.create_event("Tech Conference", :conference, 12, 300, 200)

    system.register("Alice", "alice@example.com", "Tech Conference", "555-0101")

    assert_equal 3, system.notifications_sent.size
    assert_match(/^EMAIL: alice@example.com/, system.notifications_sent[0])
    assert_match(/^SMS: 555-0101/, system.notifications_sent[1])
    assert_match(/^SLACK: #events/, system.notifications_sent[2])
  end

  # -- Splitting the notifier didn't break existing behavior ------------------

  def test_existing_notifications_unchanged
    skip "Workshop registration still produces exactly 2 notifications (EMAIL + SMS)"

    system = RegistrationSystem.new
    system.create_event("Workshop", :workshop, 20, 50)

    system.register("Alice", "alice@example.com", "Workshop", "555-0101")

    assert_equal 2, system.notifications_sent.size
    assert_match(/^EMAIL:/, system.notifications_sent[0])
    assert_match(/^SMS:/, system.notifications_sent[1])
  end
end
