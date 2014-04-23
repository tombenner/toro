module Toro
  module Monitor
    class AbstractDatatable < RailsDatatables
      class << self
        attr_reader :search_filters

        def add_search_filter(search_filter)
          @search_filters << search_filter
        end
      end
      
      protected

      def records
        @records ||= fetch_records
      end

      def get_duration(job)
        if job.started_at
          to_time = job.finished_at ? job.finished_at : Time.now
          return Toro::Monitor::TimeFormatter.distance_of_time(job.started_at, to_time)
        end
        nil
      end

      def search_records(records)
        if params[:sSearch].present?
          records = apply_search_value_to_records(params[:sSearch], records)
        end
        conditions = @columns.each_with_index.map do |column, index|
          value = params[:"sSearch_#{index}"]
          search_condition(column, value) if value.present?
        end
        conditions = conditions.compact.reduce(:and)
        records = records.where(conditions) if conditions.present?
        records
      end

      def apply_search_value_to_records(search_value, records)
        search_terms = []
        search_value.split.each do |search_term|
          filter_applied = false
          self.class.search_filters.each do |search_filter|
            if search_term =~ search_filter[:pattern]
              records = search_filter[:filter].call(search_term, records)
              filter_applied = true
              break
            end
          end
          search_terms << search_term unless filter_applied
        end
        value = search_terms.join(' ')
        conditions = @searchable_columns.map do |column|
          search_condition(column, value)
        end
        conditions = conditions.reduce(:or)
        records = records.where(conditions)
        records
      end

      def search_condition(column, value)
        column = column.split('.').last
        column_hash = @model_name.columns_hash[column]
        if column_hash && [:string, :text].include?(column_hash.type)
          return @model_name.arel_table[column].matches("%#{value}%")
        end
        @model_name.arel_table[column].eq(value)
      end
    end
  end
end
