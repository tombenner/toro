module Toro
  module Monitor
    class JobsDatatable < AbstractDatatable
      @search_filters = []

      def initialize(view)
        @model_name = Toro::Job
        @columns = [
          'toro_jobs.id',
          'toro_jobs.started_by',
          'toro_jobs.queue',
          'toro_jobs.class_name',
          'toro_jobs.name',
          'toro_jobs.created_at',
          'toro_jobs.started_at',
          'COALESCE(toro_jobs.finished_at, NOW()) - toro_jobs.started_at',
          'toro_jobs.status',
          'toro_jobs.properties',
          'toro_jobs.args'
        ]
        @searchable_columns = [
          'toro_jobs.started_by',
          'toro_jobs.queue',
          'toro_jobs.class_name',
          'toro_jobs.args',
          'toro_jobs.status',
          'toro_jobs.name'
        ]
        super(view)
      end
      
      protected

      def data
        records.map do |job|
          [
            job.id,
            job.started_by,
            job.queue,
            job.class_name,
            job.name || job.args.to_s,
            job.created_at,
            job.started_at,
            get_duration(job),
            job.properties.blank? ? nil : job.properties.values.map { |value| value.to_s }.join(', ')[0,30],
            job.status,
            job.properties,
            job.args
          ]
        end
      end

      def get_raw_records
        records = Toro::Job
        records = records.where(queue: params[:queue]) unless params[:queue].blank?
        records
      end
    end
  end
end
