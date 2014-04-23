module Toro
  module Monitor
    class QueuesController < BaseController
      def index
        @queues = Job.select('DISTINCT queue').collect { |job| job.queue }.sort
      end
    end
  end
end
