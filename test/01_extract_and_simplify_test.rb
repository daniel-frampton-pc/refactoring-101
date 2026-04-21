# frozen_string_literal: true

require_relative "test_helper"

# =============================================================================
# Step 01: Extract & Simplify
# =============================================================================
#
# GOAL: Add a transfer_registration method that moves an attendee from one
# event to another -- cancelling, promoting the next waitlisted person,
# registering at the new event, and sending all the right notifications.
#
# Try building that now with the inlined code. You can't reuse anything --
# you'd have to copy-paste pricing logic, notification logic, and waitlist
# promotion logic out of register and cancel_registration. That's 50+ lines
# of duplicated, error-prone code.
#
# Instead, first make the change easy: extract well-named methods so each
# piece of logic lives in one place. Then transfer_registration(attendee,
# from_event, to_event) can simply compose the methods you already have.
#
# Suggested extractions:
#   - calculate_price(event)
#   - send_registration_notification(event, attendee, final_price)
#   - send_waitlist_notification(event, attendee)
#   - send_cancellation_notification(event, attendee, registration)
#   - promote_from_waitlist(event)
#
# =============================================================================

class ExtractAndSimplifyTest < Minitest::Test
  def setup
    @system = RegistrationSystem.new
    @system.create_event("Workshop A", :workshop, 2, 50)
    @system.create_event("Workshop B", :workshop, 10, 75, 60)
  end

  def test_transfer_moves_attendee_to_new_event
    # skip "Compose extracted methods into transfer_registration(attendee, from_event, to_event)"

    @system.register("Alice", "alice@example.com", "Workshop A", "555-0101")
    from_event = @system.events["Workshop A"]
    to_event = @system.events["Workshop B"]
    attendee = from_event[:registered].find { |r| r[:email] == "alice@example.com" }

    result = @system.transfer_registration(attendee, from_event, to_event)

    assert_equal true, result[:success]
    assert_equal :confirmed, result[:status]
    assert_equal 0, from_event[:registered].size
    assert_equal 1, to_event[:registered].size
  end

  def test_transfer_sends_cancellation_and_registration_notifications
    # skip "transfer_registration sends cancellation and registration notifications"

    @system.register("Alice", "alice@example.com", "Workshop A", "555-0101")
    from_event = @system.events["Workshop A"]
    to_event = @system.events["Workshop B"]
    attendee = from_event[:registered].find { |r| r[:email] == "alice@example.com" }
    @system.notifications_sent.clear

    @system.transfer_registration(attendee, from_event, to_event)

    cancel_email = @system.notifications_sent.find { |n| n.include?("alice@example.com") && n.include?("cancelled") && n.include?("Workshop A") }
    register_email = @system.notifications_sent.find { |n| n.include?("alice@example.com") && n.include?("Registration confirmed") && n.include?("Workshop B") }
    assert cancel_email, "Expected cancellation email for Workshop A"
    assert register_email, "Expected registration email for Workshop B"
  end

  def test_transfer_promotes_from_waitlist_on_old_event
    skip "transfer_registration promotes the next waitlisted person on the old event"

    @system.register("Alice", "alice@example.com", "Workshop A")
    @system.register("Bob", "bob@example.com", "Workshop A")
    @system.register("Charlie", "charlie@example.com", "Workshop A", "555-0103")
    from_event = @system.events["Workshop A"]
    to_event = @system.events["Workshop B"]
    attendee = from_event[:registered].find { |r| r[:email] == "alice@example.com" }

    @system.transfer_registration(attendee, from_event, to_event)

    assert_equal 2, from_event[:registered].size
    promotion_email = @system.notifications_sent.find { |n| n.include?("charlie@example.com") && n.include?("promoted") }
    assert promotion_email, "Expected promotion notification for Charlie"
  end

  def test_transfer_calculates_price_for_new_event
    skip "transfer_registration uses calculate_price for the new event"

    @system.register("Alice", "alice@example.com", "Workshop A")
    from_event = @system.events["Workshop A"]
    to_event = @system.events["Workshop B"]
    attendee = from_event[:registered].find { |r| r[:email] == "alice@example.com" }

    result = @system.transfer_registration(attendee, from_event, to_event)

    assert_equal 60, result[:price]
  end
end
