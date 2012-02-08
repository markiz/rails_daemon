require 'async_delayed_job'
module RailsDaemon
  module Workers
    class DelayedJobQueueWatcher
      attr_reader :daemon, :options
      def initialize(daemon, options = {})
        @daemon  = daemon
        @options = default_options.merge(options)
      end

      def start!
        daemon.every(options[:cooldown]) do
          queue_size = AsyncDelayedJob::DelayedJob.available.count
          daemon.logger.info "DelayedJob queue size: #{queue_size}"
        end
      end

      protected

      def default_options
        {
          :cooldown => 120
        }
      end
    end
  end
end
