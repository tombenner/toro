module Toro
  class Shutdown < Interrupt; end

  class Manager
    include Actor
    include ActorManager

    attr_reader :busy, :ready

    def initialize(options={})
      defaults = {
        concurrency: 1,
        queues: [Toro.options[:default_queue]],
      }
      options = defaults.merge(options)
      @queues = options[:queues]
      @threads = {}
      @ready = options[:concurrency].times.map do
        processor = Processor.new_link(current_actor)
        processor.proxy_id = processor.object_id
        processor
      end
      @busy = []
      @is_done = false
      @fetcher = Fetcher.new({ manager: current_actor, queues: options[:queues] })
      @listener = Listener.new({ queues: @queues, fetcher: @fetcher, manager: current_actor })
    end

    def start
      @is_done = false
      @listener.async.start
      @ready.each { dispatch }
      heartbeat
    end

    def stop
      @is_done = true

      Toro.logger.debug "Shutting down #{@ready.size} quiet workers"
      @ready.each { |processor| processor.terminate if processor.alive? }
      @ready.clear
      @fetcher.terminate if @fetcher.alive?
      if @listener.alive?
        actors[:listener].stop if actors[:listener]
        @listener.terminate
      end
      return if clean_up_for_graceful_shutdown

      hard_shutdown_in(Toro.options[:hard_shutdown_time])
    end

    def assign(job)
      raise 'No processors ready' if !is_ready?
      processor = @ready.pop
      @busy << processor
      processor.async.process(job)
    end

    def is_ready?
      !@ready.empty?
    end

    def dispatch
      raise "No processors, cannot continue!" if @ready.empty? && @busy.empty?
      raise "No ready processor!?" if @ready.empty?
      @fetcher.async.fetch
    end

    def clean_up_for_graceful_shutdown
      if @busy.empty?
        shutdown
        return true
      end

      after(Toro.options[:graceful_shutdown_time]) { clean_up_for_graceful_shutdown }
      false
    end

    def hard_shutdown_in(delay)
      Toro.logger.info "Pausing up to #{delay} seconds to allow workers to finish..."

      after(delay) do
        # We've reached the timeout and we still have busy processors.
        # They must die but their messages shall live on.
        Toro.logger.warn "Terminating #{@busy.size} busy worker threads"

        requeue

        @busy.each do |processor|
          if processor.alive? && thread = @threads.delete(processor.object_id)
            thread.raise Shutdown
          end
        end

        signal_shutdown
      end
    end

    def shutdown
      requeue
      signal_shutdown
    end

    def requeue
      Toro::Database.with_connection do
        Job.where(status: 'running', started_by: Toro.process_identity).
          update_all(status: 'queued', started_by: nil, started_at: nil)
      end
    end

    def signal_shutdown
      after(0) { signal(:shutdown) }
    end

    def set_thread(proxy_id, thread)
      @threads[proxy_id] = thread
    end

    def heartbeat
      return if stopped?

      after(5) do
        heartbeat
      end
    end

    def processor_complete(processor)
      @threads.delete(processor.object_id)
      @busy.delete(processor)
      if stopped?
        processor.terminate if processor.alive?
        shutdown if @busy.empty?
      else
        @ready << processor if processor.alive?
        dispatch
      end
    end

    def stopped?
      @is_done
    end
  end
end
