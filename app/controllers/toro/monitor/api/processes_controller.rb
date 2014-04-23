module Toro
  module Monitor
    module Api
      class ProcessesController < ActionController::Base
        protect_from_forgery

        def index
          render json: ProcessesDatatable.new(view_context)
        end
      end
    end
  end
end
