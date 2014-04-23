module Toro
  module Middleware
    module Server
      class Properties
        def call(job, worker)
          result = yield
          if result.is_a?(Hash) && result[:job_properties].is_a?(Hash)
            job.set_properties(result[:job_properties])
            job.save
          end
        end
      end
    end
  end
end
