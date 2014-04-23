module Toro
  class Processor
    include Actor

    attr_accessor :proxy_id

    class << self
      def default_middleware
        Middleware::Chain.new do |middleware|
          middleware.add Middleware::Server::Properties
          middleware.add Middleware::Server::Retry
          middleware.add Middleware::Server::ErrorStorage
          middleware.add Middleware::Server::Error
        end
      end
    end

    def initialize(manager)
      @manager = manager
    end

    def process(job)
      @manager.set_thread(proxy_id, Thread.current)

      Toro.logger.info "Processing #{job}"
      worker = job.class_name.constantize

      Toro::Database.with_connection do
        begin
          Toro.server_middleware.invoke(job, worker) do
            worker.new.perform(*job.args)
          end
        rescue Exception => exception
          Toro.logger.error "#{exception.class}: #{exception.message}"
          Toro.logger.error exception.backtrace.join("\n")
        else
          Toro.logger.info "Processed #{job}"
          job.update_attributes(
            status: 'complete',
            finished_at: Time.now
          )
        end
      end
      
      @manager.processor_complete(current_actor) if @manager.alive?
    end
  end
end
