module Toro
  module Monitor
    class Engine < ::Rails::Engine
      isolate_namespace Monitor

      initializer "toro.asset_pipeline" do |app|
        app.config.assets.precompile << 'toro/monitor/application.js'
      end
    end
  end
end
