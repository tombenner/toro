require 'rails/railtie'

module Toro
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/tasks.rb'
    end
  end
end
