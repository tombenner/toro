module Toro
  class Fetcher
    include Actor

    def initialize(options={})
      defaults = {
        queues: [Toro.options[:default_queue]]
      }
      options.reverse_merge!(defaults)
      @queues = options[:queues]
      @manager = options[:manager]
      raise 'No manager provided' if @manager.blank?
    end

    def notify
      if @manager.is_ready?
        job = retrieve
        @manager.assign(job) if job
      end
    end

    def fetch
      job = retrieve
      @manager.async.assign(job) if job
    end

    def retrieve
      job = nil
      queue_list = @queues.map { |queue| "'#{queue}'" }.join(', ')
      sql = "SELECT * FROM toro_pop(ARRAY[#{queue_list}]::TEXT[], '#{Toro.process_identity}')"
      result = nil
      Toro::Database.with_connection do
        result = Toro::Database.query(sql).first
        result = nil if result['id'].nil?
      end
      return nil if result.nil?
      Job.instantiate(result)
    end
  end
end
