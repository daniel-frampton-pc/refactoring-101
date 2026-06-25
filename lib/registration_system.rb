# frozen_string_literal: true

require_relative './price_calculator.rb'
require './lib/notifier.rb'
require_relative './report_generator.rb'
require_relative './retreat_event'
require_relative './workshop_event'
require_relative './service_event'
class RegistrationSystem
  attr_reader :events, :registrations, :notifier
  extend Forwardable

  def_delegators :@report_generator, :capacity_report, :event_report, :attendee_report

  def initialize
    @events = {}
    @registrations = {}
    @notifier = Notifier.new
    @report_generator = ReportGenerator.new(@events, @registrations)
  end

  def notifications_sent
    @notifier.notifications_sent
  end

  def create_event(name, event_type, capacity, price, early_bird_price = nil)
    @events[name] = {
      name: name,
      event_type: event_type,
      capacity: capacity,
      price: price,
      early_bird_price: early_bird_price,
      registered: [],
      waitlist: []
    }
  end

  def transfer_registration(attendee, from_event, to_event)
    # remove the attendee from the from_event
    # from_event.registered.

    cancelation_result = cancel_registration(attendee, from_event)
    registration_result = register(attendee[:name], attendee[:email], to_event[:name], attendee[:phone])

    {
      success: cancelation_result[:success] && registration_result[:success],
      status: :confirmed,
      price: registration_result[:price]
    }
  end

  def register(attendee_name, attendee_email, event_name, phone = nil)
    event = @events[event_name]
    return { success: false, status: nil, price: nil, error: "Event not found" } unless event

    already =
      event[:registered].find { |r| r[:email] == attendee_email } ||
        event[:waitlist].find { |r| r[:email] == attendee_email }
    return { success: false, status: nil, price: nil, error: "Already registered" } if already

    attendee = { name: attendee_name, email: attendee_email, phone: phone }

    if event[:registered].size < event[:capacity]
      event[:registered] << attendee

      event_obj = case event[:event_type]
      when :service
        ServiceEvent.new(event)
      when :workshop
        WorkshopEvent.new(event)
      when :retreat
        RetreatEvent.new(event)
      end

      # Calculate price
      final_price = PriceCalculator.new(event_obj).calculate_price

      # Send notifications
      notifier.send_registration_notifications(event, attendee, final_price)

      @registrations[attendee_email] ||= []
      @registrations[attendee_email] << { event_name: event[:name], price: final_price, status: :confirmed }

      { success: true, status: :confirmed, price: final_price, error: nil }
    else
      event[:waitlist] << attendee

      notifier.send_waitlist_notifications(event, attendee)

      @registrations[attendee[:email]] ||= []
      @registrations[attendee[:email]] << { event_name: event[:name], price: 0, status: :waitlisted }

      { success: true, status: :waitlisted, price: nil, error: nil }
    end
  end

  def cancel_registration(attendee, event)
    registered_person = event[:registered].find { |r| r[:email] == attendee[:email] }
    waitlisted_person = event[:waitlist].find { |r| r[:email] == attendee[:email] }

    return { success: false, status: nil, price: nil, error: "Registration not found" } unless registered_person || waitlisted_person

    if registered_person
      event[:registered].delete(registered_person)
      registration = @registrations[attendee[:email]]&.find { |r| r[:event_name] == event[:name] }
      registration[:status] = :cancelled if registration

      notifier.send_cancellation_notifications(event, attendee, registration)

      # Promote from waitlist
      if event[:waitlist].any?
        promoted = event[:waitlist].shift
        event[:registered] << promoted
        preg = @registrations[promoted[:email]]&.find { |r| r[:event_name] == event[:name] }
        if preg
          preg[:status] = :confirmed
          preg[:price] = event[:price]
        end
        notifier.send_promote_from_waitlist_notification(event, promoted)
      end

      { success: true, status: :cancelled, price: nil, error: nil }
    else
      event[:waitlist].delete(waitlisted_person)
      registration = @registrations[attendee[:email]]&.find { |r| r[:event_name] == event[:name] }
      registration[:status] = :cancelled if registration
      notifier.send_remove_from_waitlist_notification(event, attendee)
      { success: true, status: :cancelled, price: nil, error: nil }
    end
  end
end
