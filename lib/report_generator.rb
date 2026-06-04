class ReportGenerator
  def initialize(events, registrations)
    @events = events
    @registrations = registrations
  end

  def capacity_report(event_name)
    event = @events[event_name]

    decimal_full = event[:registered].size.to_f / event[:capacity].to_f
    percent_full = decimal_full * 100

    status = if percent_full == 100
      :full
    elsif percent_full > 75
      :almost_full
    else
      :available
    end

    {
      event_name: event[:name],
      percent_full:,
      status:
    }
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
