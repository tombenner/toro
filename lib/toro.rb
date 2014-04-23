# Dependencies
require 'active_support/all'
require 'active_record'
require 'celluloid'
require 'nested-hstore'
require 'socket'

# Self
directory = File.dirname(File.absolute_path(__FILE__))
require "#{directory}/toro/version.rb"
Dir.glob("#{directory}/toro/*.rb") { |file| require file }
Dir.glob("#{directory}/toro/middleware/**/*.rb") { |file| require file }
Dir.glob("#{directory}/generators/**/*.rb") { |file| require file }

module Toro
  DEFAULTS = {
    default_queue: 'default',
    graceful_shutdown_time: 1,
    hard_shutdown_time: 8,
    listen_interval: 5
  }

  class << self
    def options
      @options ||= DEFAULTS.dup
    end

    def options=(options)
      @options = options
    end

    def configure_server
      yield self
    end

    def server_middleware
      @server_chain ||= Processor.default_middleware
      yield @server_chain if block_given?
      @server_chain
    end

    def process_identity
      @process_identity ||= "#{Socket.gethostname}:#{Process.pid}"
    end

    def logger
      Toro::Logging.logger
    end

    def logger=(log)
      Toro::Logging.logger = log
    end
  end
end