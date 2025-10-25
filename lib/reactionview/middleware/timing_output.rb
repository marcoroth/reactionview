# frozen_string_literal: true

module ReActionView
  module Middleware
    class TimingOutput
      def initialize(app)
        @app = app
      end

      def call(env)
        Thread.current[:reactionview_timings] = {}

        status, headers, response = @app.call(env)

        if ::ReActionView.config.show_render_times? && html_response?(headers)
          response = inject_timing_data(response)
        end

        Thread.current[:reactionview_timings] = nil

        [status, headers, response]
      end

      private

      def html_response?(headers)
        content_type = headers["Content-Type"]
        content_type && content_type.include?("text/html")
      end

      def inject_timing_data(response)
        body = response_body(response)
        timings = Thread.current[:reactionview_timings] || {}

        return [body] if timings.empty?

        timing_script = build_timing_script(timings)

        if body.include?("</body>")
          body = body.sub("</body>", "#{timing_script}</body>")
        elsif body.include?("</html>")
          body = body.sub("</html>", "#{timing_script}</html>")
        else
          body << timing_script
        end

        [body]
      end

      def response_body(response)
        body = +""
        response.each { |part| body << part }
        body
      end

      def build_timing_script(timings)
        timings_json = timings.to_json.gsub("<", "\\u003c").gsub(">", "\\u003e")

        <<~HTML
          <script type="application/json" id="reactionview-timings">
          #{timings_json}
          </script>
        HTML
      end
    end
  end
end
