module Toro
  class Database
    SQL_DIRECTORY = Pathname.new(File.expand_path('sql', File.dirname(__FILE__)))

    class << self
      def up
        execute_file('up')
      end

      def down
        execute_file('down')
      end

      def connection
        ActiveRecord::Base.connection
      end

      def raw_connection
        connection.raw_connection
      end

      def query(sql, parameters=[])
        raw_connection.exec(sql, parameters)
      end

      def with_connection(&block)
        ActiveRecord::Base.connection_pool.with_connection(&block)
      end

      private

      def execute_file(file_name)
        file_path = SQL_DIRECTORY.join("#{file_name}.sql")
        connection.execute(File.read(file_path))
      end
    end
  end
end
