module Toro
  module Monitor
    class BaseController < ActionController::Base
      protect_from_forgery

      layout 'toro/monitor/layouts/application'

      helper Toro::Monitor::ToroMonitorHelper
    end
  end
end
