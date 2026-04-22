# frozen_string_literal: true

require_relative "test_helper"

# =============================================================================
# Step 02: Single Responsibility Principle (SRP)
# =============================================================================
#
# A class should have only one reason to change.
#
# RegistrationSystem has too many responsibilities crammed into one class:
#   - Price calculation
#   - Notification delivery
#   - Report generation
#   - Registration orchestration
#
# You need to add a capacity_report method that returns a hash with
# `event_name`, `percent_full` (Float), and `status` (:available,
# :almost_full when >75%, or :full). But right now there's no obvious place
# to put it -- everything lives in one big class.
#
# First make the change easy: extract focused classes so each piece of logic
# has a single home:
#   - PriceCalculator  -- pricing logic
#   - Notifier         -- notification logic
#   - ReportGenerator  -- report-building logic
#
# Then update RegistrationSystem to delegate to these classes. The public API
# must not change -- safety-net tests still pass.
#
# Now make the easy change: capacity_report belongs in ReportGenerator, and
# RegistrationSystem delegates to it. Done.
#
# HINT: Once Notifier owns the notifications, where does `system.notifications_sent`
# get its data from? Safety-net tests still read it.
#
# HINT: What state does each new class actually need? Some need nothing;
# others need to see data that currently lives on RegistrationSystem.
#
# HINT: Who creates these collaborators, and when? (Don't overthink it --
# exercise 06 will revisit this.)
#
# =============================================================================

class SingleResponsibilityTest < Minitest::Test
  def test_capacity_report_almost_full
    # skip "Add capacity_report -- extract classes first so it has an obvious home"

    system = RegistrationSystem.new
    system.create_event("Workshop", :workshop, 10, 50)
    8.times do |i|
      system.register("A#{i}", "a#{i}@example.com", "Workshop")
    end

    report = system.capacity_report("Workshop")

    assert_equal "Workshop", report[:event_name]
    assert_equal 80.0, report[:percent_full]
    assert_equal :almost_full, report[:status]
  end

  def test_capacity_report_available
    skip "Add capacity_report -- extract classes first so it has an obvious home"

    system = RegistrationSystem.new
    system.create_event("Sunday Service", :service, 100, 0)
    10.times do |i|
      system.register("A#{i}", "a#{i}@example.com", "Sunday Service")
    end

    report = system.capacity_report("Sunday Service")

    assert_equal 10.0, report[:percent_full]
    assert_equal :available, report[:status]
  end

  def test_capacity_report_full
    skip "Add capacity_report -- extract classes first so it has an obvious home"

    system = RegistrationSystem.new
    system.create_event("Tiny Event", :service, 2, 0)
    system.register("A1", "a1@example.com", "Tiny Event")
    system.register("A2", "a2@example.com", "Tiny Event")
    system.register("A3", "a3@example.com", "Tiny Event")

    report = system.capacity_report("Tiny Event")

    assert_equal 100.0, report[:percent_full]
    assert_equal :full, report[:status]
  end

  def test_capacity_report_delegates_through_system
    skip "Add capacity_report -- extract classes first so it has an obvious home"

    system = RegistrationSystem.new
    system.create_event("Workshop", :workshop, 4, 50)
    4.times do |i|
      system.register("A#{i}", "a#{i}@example.com", "Workshop")
    end

    report = system.capacity_report("Workshop")

    assert_equal :full, report[:status]
  end
end
