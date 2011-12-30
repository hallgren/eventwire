class Event

@events = []

  def self.add event
    @events << event
  end

  def self.check event
    return @events.include? event
  end

  def self.get_event_count
    return @events.count
  end


end