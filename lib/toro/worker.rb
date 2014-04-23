module Toro
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def perform_async(*args)
        create_job(args: args, queue: queue)
      end

      def perform_at(time, *args)
        create_job(args: args, queue: queue, scheduled_at: time, status: 'scheduled')
      end

      def perform_in(interval, *args)
        time = Time.now + interval
        perform_at(time, *args)
      end

      def create_job(item)
        Toro::Client.create_job(normalize_job(item))
      end

      def normalize_job(item)
        name = respond_to?(:job_name) ? send(:job_name, *(item[:args])) : nil
        { class_name: self.name, name: name }.merge(item)
      end

      def queue
        toro_options[:queue]
      end

      def toro_options(options={})
        @toro_options ||= {
          queue: Toro.options[:default_queue],
          retry_interval: nil
        }
        @toro_options.merge!(options)
        @toro_options
      end
    end
  end
end
