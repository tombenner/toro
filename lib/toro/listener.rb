module Toro
  class Listener
    include Actor

    def initialize(options={})
      defaults = {
        queues: [Toro.options[:default_queue]]
      }
      options.reverse_merge!(defaults)
      @queues = options[:queues]
      @fetcher = options[:fetcher]
      @manager = options[:manager]
      @is_done = false
      raise 'No fetcher provided' if @fetcher.blank?
      raise 'No manager provided' if @manager.blank?
    end

    def start
      @manager.register_actor(:listener, self)
      Toro::Database.with_connection do
        Toro::Database.raw_connection.async_exec(channels.map { |channel| "LISTEN #{channel}" }.join('; '))
        wait_for_notify
      end
    end

    def stop
      Toro::Database.raw_connection.async_exec(channels.map { |channel| "UNLISTEN #{channel}" }.join('; '))
      @is_done = true
    end

    protected

    def wait_for_notify
      Toro::Database.raw_connection.wait_for_notify(Toro.options[:listen_interval]) do |channel, pid, payload|
        @fetcher.notify
      end
      wait_for_notify unless @is_done
    end

    def channels
      @queues.map { |queue| "toro_#{queue}" }
    end
  end
end
