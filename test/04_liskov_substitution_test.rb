# frozen_string_literal: true

require_relative "test_helper"

# =============================================================================
# Step 04: Liskov Substitution Principle (LSP)
# =============================================================================
#
# Subtypes must be substitutable for their base types without breaking the
# program.
#
# After replacing case/when with polymorphic event types, each event type
# class should honor the same contract so callers can treat them
# interchangeably. But it's easy for ServiceEvent -- the simplest type --
# to cut corners: returning nil where others return an Array or String,
# or skipping methods that don't seem to apply to free events.
#
# The goal is for registration and cancellation to work the same way for
# EVERY event type -- no nil guards, no type checks, no rescue blocks.
# Fix your event types so they all respond to the same interface with
# compatible return types, then a generic dispatcher works cleanly for
# every event type -- no special cases.
#
# =============================================================================

class LiskovSubstitutionTest < Minitest::Test
  def setup
    @system = RegistrationSystem.new
  end

  # -- ServiceEvent works through the same generic path as every other type ---

  def test_service_event_registration_works_generically
    # skip "Fix ServiceEvent so registration dispatches based on channels -- no nil guards"

    @system.create_event("Sunday Service", :service, 100, 0)

    @system.register("Alice", "alice@example.com", "Sunday Service", "555-0101")

    assert_equal 1, @system.notifications_sent.size
    assert_match(/^EMAIL: alice@example.com/, @system.notifications_sent[0])
  end

  # -- Every event type produces the right notification count -----------------

  def test_all_event_types_produce_correct_notification_counts
    # skip "All event types dispatch through the same code path based on channels"

    @system.create_event("Service", :service, 100, 0)
    @system.create_event("Workshop", :workshop, 20, 50)
    @system.create_event("Retreat", :retreat, 20, 200)

    @system.register("A1", "a1@example.com", "Service", "555-0001")
    service_count = @system.notifications_sent.size

    @system.register("A2", "a2@example.com", "Workshop", "555-0002")
    workshop_count = @system.notifications_sent.size - service_count

    @system.register("A3", "a3@example.com", "Retreat", "555-0003")
    retreat_count = @system.notifications_sent.size - service_count - workshop_count

    assert_equal 1, service_count
    assert_equal 2, workshop_count
    assert_equal 2, retreat_count
  end

  # -- ServiceEvent cancellation works without rescuing errors ----------------

  def test_service_event_cancellation_works_generically
    # skip "Fix ServiceEvent#cancellation_policy so cancellation works without rescue"

    @system.create_event("Sunday Service", :service, 100, 0)
    @system.register("Alice", "alice@example.com", "Sunday Service")

    event = @system.events["Sunday Service"]
    attendee = event[:registered].find { |r| r[:email] == "alice@example.com" }
    @system.cancel_registration(attendee, event)

    cancel_email = @system.notifications_sent.find { |n| n.include?("alice@example.com") && n.include?("cancelled") }
    assert cancel_email, "Expected a cancellation email for service event"
    refute_match(/refund/i, cancel_email)
  end

  # -- Cancel-and-promote works generically for every event type --------------

  def test_cancel_and_promote_works_for_all_event_types
    # skip "The entire cancel-and-promote flow works generically for all event types"

    %i[service workshop retreat].each do |type|
      system = RegistrationSystem.new
      event_name = "#{type.capitalize} Event"
      price = type == :service ? 0 : 100

      system.create_event(event_name, type, 1, price)
      system.register("First", "first@example.com", event_name)
      system.register("Second", "second@example.com", event_name)

      event = system.events[event_name]
      attendee = event[:registered].find { |r| r[:email] == "first@example.com" }
      system.cancel_registration(attendee, event)

      promotion = system.notifications_sent.find { |n| n.include?("second@example.com") && n.include?("promoted") }
      assert promotion, "Expected promotion notification for #{type} event"
    end
  end
end
