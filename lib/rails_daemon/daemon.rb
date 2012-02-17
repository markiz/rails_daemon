require 'rubygems'
require 'daemons'
require 'eventmachine'

module RailsDaemon
  class Daemon
    include DSL

    attr_reader :name, :root, :options
    def initialize(name, root, options = {})
      @name    = name
      @root    = root
      @options = default_options.merge(options)
    end

    def start!(&block)
      Daemons.run_proc(name, options[:daemon]) do
        prepare_environment!
        loop do
          begin
            logger.info "Starting daemon in #{Rails.env} mode"
            cleanup!
            EM.run do
              block.call(self)
            end
          rescue StandardError => e
            if $daemon_stopped
              logger.info("Exception raised after daemon stopped.")
              logger.info("#{e.class.name}: #{e.to_s}")
              logger.info("Ignoring it.")
              exit!
            else
              logger.error("#{e.class.name}: #{e.to_s}\n\n#{e.backtrace.join("\n")}")
            end
          end
          logger.error "Something happened, restarting daemon..."
          sleep(options[:restart_cooldown])
        end
      end
    end

    def logger
      Rails.logger
    end

    protected

    def cleanup!
      ActiveRecord::Base.connection.reconnect!
    end

    def prepare_environment!
      environments = ["development", "production"].freeze
      ENV["RAILS_ENV"] ||= ARGV.detect {|a| environments.include?(a) }
      ARGV.delete_if {|a| environments.include?(a)}
      require "#{root}/config/environment"
      setup_logger!
    end

    def setup_logger!
      log_file = File.open(options[:log_file], 'a')
      log_file.sync = true
      Rails.logger = Logger.new(log_file)
      Rails.logger.formatter = lambda do |severity, timestamp, progname, msg|
        "[#{timestamp.strftime("%Y-%m-%d %H:%M")}] #{msg}\n"
      end
    end

    def default_options
      {
        :daemon           => default_daemon_options,
        :restart_cooldown => 30,
        :log_file         => "#{root}/log/daemon.log"
      }
    end

    def default_daemon_options
      {
        :multiple   => false,
        :dir_mode   => :normal,
        :dir        => "#{root}/tmp/pids",
        :multiple   => false,
        :backtrace  => true,
        :monitor    => false,
        :log_output => true,
        :log_dir    => "#{root}/log",
        :hard_exit  => true,
        :stop_proc  => proc { $daemon_stopped = true }
      }
    end
  end
end
