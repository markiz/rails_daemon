require "rails_daemon/version"
require "rails_daemon/dsl"
require "rails_daemon/daemon"
require "rails_daemon/workers"

module RailsDaemon
  def self.start(name, root, options = {}, &block)
    Daemon.new(name, root, options).start!(&block)
  end
end
