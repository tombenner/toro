require 'slim'
require 'jquery-datatables-rails'
require 'rails-datatables'
require 'action_view'

directory = File.dirname(File.absolute_path(__FILE__))
require "#{directory}/monitor/custom_views.rb"
require "#{directory}/monitor/time_formatter.rb"
require "#{directory}/monitor/engine.rb" if defined?(Rails)

module Toro
  module Monitor
    DEFAULTS = {
      :charts => nil,
      :javascripts => [],
      :poll_interval => 3000
    }

    class << self
      def options
        @options ||= DEFAULTS.dup
      end

      def options=(options)
        @options = options
      end

      def root_path
        toro_monitor_path = Toro::Monitor::Engine.routes.url_helpers.toro_monitor_path
        "#{::Rails.application.config.relative_url_root}#{toro_monitor_path}"
      end
    end
  end
end
