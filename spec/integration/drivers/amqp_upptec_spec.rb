require 'integration/drivers/driver_helper_amqp_upptec'

describe Eventwire::Drivers::AMQP_UPPTEC do
  it_should_behave_like 'a driver with single-process support with only one subscriber'
  it_should_behave_like 'a driver with multi-process support with only one subscriber'
end