module Toro
  module Middleware
    module Server
      class Retry
        def call(job, worker)
          begin
            yield
          rescue Exception => exception
            if worker.toro_options[:retry_interval]
              interval = worker.toro_options[:retry_interval]
              job.reload
              job.properties ||= {}
              job.properties['retry:errors'] ||= []
              job.properties['retry:errors'] << "#{exception.class.name} -- #{exception.message} -- #{Time.now}"
              job.status = 'scheduled'
              job.scheduled_at = Time.now + interval
              job.save
            end
            raise exception
          end
        end
      end
    end
  end
end
