class ServiceEvent
  def initialize(event)
    @event = event
  end

  def calculate_price
    @event[:price]
  end
end
