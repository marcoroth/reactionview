# frozen_string_literal: true

module ReActionView
  class LogSubscriber < ActiveSupport::LogSubscriber
    def cache_miss(event)
      info "[ReActionView] Cache miss for #{event.payload[:identifier]}"
    end
  end
end
