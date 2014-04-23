module Toro
  module Monitor
    module ToroMonitorHelper
      def app_name
        'Toro'
      end

      def root_path
        Toro::Monitor.root_path
      end
    end
  end
end
