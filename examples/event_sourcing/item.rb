require "json"

class Item
  include Eventwire::EventHandler

  def add_item(name)
    @completed = true
    handle_event :add_item, {:item_name => name}.to_json
  end

end