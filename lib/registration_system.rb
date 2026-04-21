# frozen_string_literal: true

class RegistrationSystem
  attr_reader :events, :registrations, :notifications_sent

  def initialize
    @events = {}
    @registrations = {}
    @notifications_sent = []
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
  def calculate_price(event)
    # Calculate price
    case event[:event_type]
    when :service
      event[:price]
    when :workshop
      if event[:early_bird_price] && event[:registered].size <= (event[:capacity] / 2)
        event[:early_bird_price]
      else
        event[:price]
      end
    when :retreat
      if event[:early_bird_price] && event[:registered].size <= (event[:capacity] / 3)
        event[:early_bird_price]
      else
        event[:price]
      end
    else
      event[:price]
    end
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
      final_price = calculate_price(event)

      # Send notifications
      case event[:event_type]
      when :service
        @notifications_sent << "EMAIL: #{attendee[:email]} - Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
      when :workshop
        @notifications_sent << "EMAIL: #{attendee[:email]} - Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
        @notifications_sent << "SMS: #{attendee[:phone]} - You're registered for #{event[:name]}!" if attendee[:phone]
      when :retreat
        @notifications_sent << "EMAIL: #{attendee[:email]} - Registration confirmed for #{event[:name]}. Amount: $#{final_price}"
        @notifications_sent << "SMS: #{attendee[:phone]} - You're registered for #{event[:name]}!" if attendee[:phone]
      end

      @registrations[attendee_email] ||= []
      @registrations[attendee_email] << { event_name: event[:name], price: final_price, status: :confirmed }

      { success: true, status: :confirmed, price: final_price, error: nil }
    else
      event[:waitlist] << attendee

      # Send waitlist notifications
      case event[:event_type]
      when :service
        @notifications_sent << "EMAIL: #{attendee[:email]} - You're on the waitlist for #{event[:name]}"
      when :workshop
        @notifications_sent << "EMAIL: #{attendee[:email]} - You're on the waitlist for #{event[:name]}"
        @notifications_sent << "SMS: #{attendee[:phone]} - Waitlisted for #{event[:name]}" if attendee[:phone]
      when :retreat
        @notifications_sent << "EMAIL: #{attendee[:email]} - You're on the waitlist for #{event[:name]}"
        @notifications_sent << "SMS: #{attendee[:phone]} - Waitlisted for #{event[:name]}" if attendee[:phone]
      end

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

      # Send cancellation notifications
      case event[:event_type]
      when :service
        @notifications_sent << "EMAIL: #{attendee[:email]} - Registration cancelled for #{event[:name]}"
      when :workshop
        @notifications_sent << "EMAIL: #{attendee[:email]} - Registration cancelled for #{event[:name]}"
        @notifications_sent << "SMS: #{attendee[:phone]} - Cancelled: #{event[:name]}" if attendee[:phone]
      when :retreat
        refund_info = " Refund of $#{registration[:price]} will be processed within 5-7 business days."
        @notifications_sent << "EMAIL: #{attendee[:email]} - Registration cancelled for #{event[:name]}.#{refund_info}"
        @notifications_sent << "SMS: #{attendee[:phone]} - Cancelled: #{event[:name]}" if attendee[:phone]
      end

      # Promote from waitlist
      if event[:waitlist].any?
        promoted = event[:waitlist].shift
        event[:registered] << promoted
        preg = @registrations[promoted[:email]]&.find { |r| r[:event_name] == event[:name] }
        if preg
          preg[:status] = :confirmed
          preg[:price] = event[:price]
        end
        @notifications_sent << "EMAIL: #{promoted[:email]} - You've been promoted from the waitlist for #{event[:name]}! Amount: $#{event[:price]}"
        @notifications_sent << "SMS: #{promoted[:phone]} - Promoted from waitlist: #{event[:name]}!" if promoted[:phone]
      end

      { success: true, status: :cancelled, price: nil, error: nil }
    else
      event[:waitlist].delete(waitlisted_person)
      registration = @registrations[attendee[:email]]&.find { |r| r[:event_name] == event[:name] }
      registration[:status] = :cancelled if registration
      @notifications_sent << "EMAIL: #{attendee[:email]} - Removed from waitlist for #{event[:name]}"
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
