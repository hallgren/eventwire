module Eventwire
  module EventHandler
    def handle_event(event_name, event_data = nil)
      Eventwire.handle_event event_name, event_data
    end
  end
end