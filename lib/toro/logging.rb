module Toro
  module Logging
    class Formatter < Logger::Formatter
      def call(severity, time, program_name, message)
        "[#{time.utc.iso8601} P-#{Process.pid} T-#{Thread.current.object_id.to_s(36)}] #{severity} -- Toro: #{message}\n"
      end
    end

    class << self
      def initialize_logger(log_target=nil)
        if log_target.nil?
          log_target = $TESTING ? '/dev/null' : STDOUT
        end

        old_logger = defined?(@logger) ? @logger : nil
        @logger = Logger.new(log_target)
        @logger.level = $TESTING ? Logger::DEBUG : Logger::INFO
        @logger.formatter = Formatter.new
        old_logger.close if old_logger && !$TESTING # don't want to close testing's STDOUT logging
        Celluloid.logger = @logger
        @logger
      end

      def logger
        defined?(@logger) ? @logger : initialize_logger
      end

      def logger=(log)
        @logger = (log ? log : Logger.new('/dev/null'))
        Celluloid.logger = @logger
        @logger
      end

      # This reopens ALL logfiles in the process that have been rotated
      # using logrotate(8) (without copytruncate) or similar tools.
      # A +File+ object is considered for reopening if it is:
      #   1) opened with the O_APPEND and O_WRONLY flags
      #   2) the current open file handle does not match its original open path
      #   3) unbuffered (as far as userspace buffering goes, not O_SYNC)
      # Returns the number of files reopened
      def reopen_logs
        to_reopen = []
        append_flags = File::WRONLY | File::APPEND

        ObjectSpace.each_object(File) do |fp|
          begin
            if !fp.closed? && fp.stat.file? && fp.sync && (fp.fcntl(Fcntl::F_GETFL) & append_flags) == append_flags
              to_reopen << fp
            end
          rescue IOError, Errno::EBADF
          end
        end

        nr = 0
        to_reopen.each do |fp|
          orig_st = begin
            fp.stat
          rescue IOError, Errno::EBADF
            next
          end

          begin
            b = File.stat(fp.path)
            next if orig_st.ino == b.ino && orig_st.dev == b.dev
          rescue Errno::ENOENT
          end

          begin
            File.open(fp.path, 'a') { |tmpfp| fp.reopen(tmpfp) }
            fp.sync = true
            nr += 1
          rescue IOError, Errno::EBADF
            # not much we can do...
          end
        end
        nr
      end
    end
  end
end
