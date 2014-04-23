module Toro
  module Middleware
    module Server
      class Error
        def call(job, worker)
          begin
            yield
          rescue Exception => exception
            job.update_attributes(
              status: 'failed',
              finished_at: Time.now
            )
            raise exception
          end
        end
      end
    end
  end
end
