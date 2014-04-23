require 'active_record'

config_path = File.expand_path('../config/database.yml', File.dirname(__FILE__))
raise 'ActiveRecord config file not found. Please `cp spec/config/database.yml.example spec/config/database.yml`.' if !File.exists?(config_path)
connection_settings = YAML.load_file(config_path)['test']
ActiveRecord::Base.establish_connection(connection_settings)

Toro::Database.down
Toro::Database.up
 
RSpec.configure do |config|
  # An approach like DatabaseCleaner.start/DatabaseCleaner.clean doesn't suit us, as it wraps a
  # transaction around each example. If an example spawns a new thread, the original thread's data
  # won't be available to it, since a commit hasn't been performed.
  config.before(:each) do
    ActiveRecord::Base.connection.execute('TRUNCATE toro_jobs;')
  end
end