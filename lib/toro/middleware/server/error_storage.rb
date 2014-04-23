module Toro
  module Middleware
    module Server
      class ErrorStorage
        def call(job, worker)
          begin
            yield
          rescue Exception => exception
            job.reload
            job.set_properties(
              'error:class' => exception.class.name,
              'error:message' => exception.message,
              'error:backtrace' => exception.backtrace
            )
            job.save
            raise exception
          end
        end
      end
    end
  end
end
