class RetreatEvent
  def initialize(event)
    @event = event
  end

  def calculate_price
    if @event[:early_bird_price] && @event[:registered].size <= (@event[:capacity] / 3)
      @event[:early_bird_price]
    else
      @event[:price]
    end
  end
end
