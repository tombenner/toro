module Toro
  class CLI
    attr_reader :options

    def initialize(arguments=ARGV)
      @options = arguments_to_options(arguments)
      @manager = Manager.new(@options)
    end

    def run
      Toro.logger.info 'Starting processing (press Control-C to stop)'

      read_io, write_io = IO.pipe
      
      %w(INT TERM USR1 USR2 TTIN).each do |signal|
        begin
          trap signal do
            write_io.puts(signal)
          end
        rescue ArgumentError
          Toro.logger.debug "Signal #{signal} not supported"
        end
      end

      begin
        @manager.start

        while readable_io = IO.select([read_io])
          signal = readable_io.first[0].gets.strip
          handle_signal(signal)
        end
      rescue Interrupt
        Toro.logger.info 'Shutting down...'
        @manager.stop
      end

      # Explicitly exit so busy Processor threads can't block
      # process shutdown.
      exit 0
    end

    protected

    def arguments_to_options(arguments)
      options = {}
      OptionParser.new do |opts|
        opts.on('-q', '--queue NAME', 'Queue') { |v| options[:queues] ||= []; options[:queues] << parse_queue(v) }
        opts.on('-c', '--concurrency CONCURRENCY', 'Concurrency') { |v| options[:concurrency] = Integer(v) }
      end.parse!(arguments)
      options
    end

    def parse_queue(value)
      value.strip
    end

    def handle_signal(signal)
      Toro.logger.debug "Got #{signal} signal"
      case signal
      when 'INT'
        # Handle Ctrl-C in JRuby like MRI
        # http://jira.codehaus.org/browse/JRUBY-4637
        raise Interrupt
      when 'TERM'
        # Heroku sends TERM and then waits 10 seconds for process to exit.
        raise Interrupt
      when 'USR1'
        Toro.logger.info "Received USR1, no longer accepting new work"
        @manager.async.stop
      when 'USR2'
        if Toro.options[:logfile]
          Toro.logger.info "Received USR2, reopening log file"
          Toro::Logging.reopen_logs
        end
      when 'TTIN'
        Thread.list.each do |thread|
          Toro.logger.info "Thread T#{thread.object_id.to_s(36)} #{thread['label']}"
          if thread.backtrace
            Toro.logger.info thread.backtrace.join("\n")
          else
            Toro.logger.info "<no backtrace available>"
          end
        end
      end
    end
  end
end
