# frozen_string_literal: true

require_relative './price_calculator.rb'
require './lib/notifier.rb'

class RegistrationSystem
  attr_reader :events, :registrations, :notifier

  def initialize
    @events = {}
    @registrations = {}
    @notifier = Notifier.new
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

  def capacity_report(event_name)
    event = @events[event_name]

    decimal_full = event[:registered].size.to_f / event[:capacity].to_f
    percent_full = decimal_full * 100

    {
      event_name: event[:name],
      percent_full:,
      status: :almost_full
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

      # Calculate price
      final_price = PriceCalculator.new(event).calculate_price

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

  def event_report(event_name)
    event = @events[event_name]
    return nil unless event

    total_revenue =
      @registrations
        .values
        .flatten
        .select { |r| r[:event_name] == event_name && r[:status] == :confirmed }
        .sum { |r| r[:price] }

    {
      event_name: event[:name],
      event_type: event[:event_type],
      capacity: event[:capacity],
      registered_count: event[:registered].size,
      waitlist_count: event[:waitlist].size,
      available_spots: event[:capacity] - event[:registered].size,
      total_revenue: total_revenue,
      registrations: event[:registered].map { |r| { name: r[:name], email: r[:email], phone: r[:phone] } },
      waitlist: event[:waitlist].map { |r| { name: r[:name], email: r[:email], phone: r[:phone] } }
    }
  end

  def attendee_report(attendee_email)
    regs = @registrations[attendee_email]
    return nil unless regs

    total_spent = regs.select { |r| r[:status] == :confirmed }.sum { |r| r[:price] }

    {
      email: attendee_email,
      registrations: regs,
      total_spent: total_spent
    }
  end
end
