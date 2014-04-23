require 'rspec/autorun'
require 'toro'

require 'support/active_record_spec_helper'
require 'support/jobs_helper'
require 'support/workers_helper'

$TESTING = true
Celluloid.logger = Toro.logger
Toro.options[:hard_shutdown_time] = 1

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before(:each) do
    Celluloid.shutdown
    Celluloid.boot
  end
end
