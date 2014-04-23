module Toro
  class Job < ActiveRecord::Base
    if ActiveRecord::VERSION::MAJOR < 4 || ActiveRecord.constants.include?(:MassAssignmentSecurity)
      attr_accessible :queue, :class_name, :args, :name, :created_at, :scheduled_at, :started_at, :finished_at,
        :status, :started_by, :properties
    end

    serialize :args
    serialize :properties, ActiveRecord::Coders::NestedHstore

    self.table_name_prefix = 'toro_'
    
    STATUSES = [
      'queued',
      'running',
      'complete',
      'failed',
      'scheduled'
    ]

    class << self
      def statuses
        STATUSES
      end
    end

    def set_properties(hash)
      self.properties ||= {}
      hash.each do |key, value|
        self.properties[key.to_s] = value
      end
    end

    def to_s
      "Toro::Job ##{id}"
    end
  end
end
