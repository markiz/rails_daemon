module RailsDaemon
  module DSL
    def every(n_seconds, &block)
      EM::PeriodicTimer.new(n_seconds, &block)
    end

    def once(n_seconds, &block)
      EM::Timer.new(n_seconds, &block)
    end
    alias_method :in, :once
  end
end
