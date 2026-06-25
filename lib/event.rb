class Event
  attr_reader :price, :name, :early_bird_price, :capacity, :registered

  def initialize(event)
    @name = event[:name]
    @price = event[:price]
    @early_bird_price = event[:early_bird_price]
    @capacity = event[:capacity]
    @registered = event[:registered]
  end
end
