class PriceCalculator
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def calculate_price
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
end
