module Toro
  class Client
    class << self
      def create_job(item)
        item.stringify_keys!
        job_attributes = item_to_job_attributes(item)
        Job.create!(job_attributes)
      end

      private

      def item_to_job_attributes(item)
        { 'status' => 'queued' }.merge(item)
      end
    end
  end
end
