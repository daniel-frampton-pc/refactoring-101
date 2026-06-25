# frozen_string_literal: true

require_relative "test_helper"

# =============================================================================
# Step 03: Open/Closed Principle (OCP)
# =============================================================================
#
# Software should be open for extension but closed for modification.
#
# Responsibilities are well-separated now, but Notifier (and potentially
# other classes) use `case event_type` to branch on :service, :workshop,
# or :retreat. Adding a new event type means cracking open every class that
# switches on the symbol -- the system is NOT closed for modification.
#
# First make the change easy: replace case/when with polymorphic event type
# classes (ServiceEvent, WorkshopEvent, RetreatEvent). Each class should
# know how to calculate its price, which notification channels it uses
# (e.g. [:email] or [:email, :sms]), and its cancellation policy (a
# human-readable String). Notifier and PriceCalculator delegate to the
# event type object instead of switching on a symbol.
#
# Now make the easy change: add a :conference event type by creating a
# ConferenceEvent class. Early bird pricing kicks in at or below one-quarter
# capacity, notifications go to email + SMS, and the cancellation policy is
# "50% refund". No existing class needs to change.
#
# HINT: The event hash still holds capacity and registered counts. Does the
# event type object need its own state, or can each method just receive what
# it needs?
#
# HINT: Safety-net tests read `event_report(...)[:event_type]` and expect a
# Symbol. If you replace the symbol with an object, what breaks? What's the
# smallest change that keeps both worlds happy?
#
# HINT: Retreat's cancellation message mentions the refund amount. Can a
# single plain-String policy carry that, or does the method need more
# information to do its job?
#
# =============================================================================

# NOTE TO OURSELVES:
# We left off at refactoring Notifier to use polymorphism.
# Caroline has as an optimistic goal to finish refactoring Notifier.
# Next time, we plan to pick up with creating ConferenceEvent.

class OpenClosedTest < Minitest::Test
  def test_conference_registration_with_early_bird_pricing
    skip "Add :conference event type -- replace case/when with polymorphism first"

    system = RegistrationSystem.new
    system.create_event("Tech Conference", :conference, 12, 300, 200)

    result = system.register("Alice", "alice@example.com", "Tech Conference")

    assert_equal 200, result[:price]
  end

  def test_conference_registration_regular_pricing
    skip "Add :conference event type -- replace case/when with polymorphism first"

    system = RegistrationSystem.new
    system.create_event("Tech Conference", :conference, 12, 300, 200)
    3.times do |i|
      system.register("A#{i}", "a#{i}@example.com", "Tech Conference")
    end

    result = system.register("Late", "late@example.com", "Tech Conference")

    assert_equal 300, result[:price]
  end

  def test_conference_sends_email_and_sms
    skip "Add :conference event type -- replace case/when with polymorphism first"

    system = RegistrationSystem.new
    system.create_event("Tech Conference", :conference, 12, 300, 200)

    system.register("Alice", "alice@example.com", "Tech Conference", "555-0101")

    assert_match(/^EMAIL: alice@example.com/, system.notifications_sent[0])
    assert_match(/^SMS: 555-0101/, system.notifications_sent[1])
  end

  def test_conference_cancellation_policy
    skip "Add :conference event type -- replace case/when with polymorphism first"

    system = RegistrationSystem.new
    system.create_event("Tech Conference", :conference, 12, 300, 200)
    system.register("Alice", "alice@example.com", "Tech Conference", "555-0101")

    event = system.events["Tech Conference"]
    attendee = event[:registered].find { |r| r[:email] == "alice@example.com" }
    system.cancel_registration(attendee, event)

    cancel_email = system.notifications_sent.find { |n| n.include?("alice@example.com") && n.include?("cancelled") }
    assert cancel_email, "Expected cancellation email for Tech Conference"
    assert_match(/50% refund/, cancel_email)
  end

  def test_existing_event_types_still_work
    skip "Add :conference event type -- replace case/when with polymorphism first"

    system = RegistrationSystem.new
    system.create_event("Workshop", :workshop, 10, 50, 35)

    result = system.register("Alice", "alice@example.com", "Workshop", "555-0101")

    assert_equal 35, result[:price]
    assert_equal 2, system.notifications_sent.size
    assert_match(/^EMAIL: alice@example.com/, system.notifications_sent[0])
    assert_match(/^SMS: 555-0101/, system.notifications_sent[1])
  end
end
