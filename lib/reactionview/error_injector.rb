# frozen_string_literal: true

module ReActionView
  class ErrorInjector
    class << self
      def inject_errors(content, errors, template_path)
        return content if errors.empty? || !ReActionView.config.should_inject_errors?

        error_html = generate_error_display(errors, template_path)
        inject_into_html(content, error_html)
      end

      private

      def generate_error_display(errors, template_path)
        error_list = errors.map do |error|
          <<~HTML
            <div class="reactionview-error-item">
              <div class="reactionview-error-type">[#{error[:type]}]</div>
              <div class="reactionview-error-message">#{escape_html(error[:message])}</div>
              <div class="reactionview-error-location">Line #{error[:line]}, Column #{error[:column]}</div>
            </div>
          HTML
        end.join

        <<~HTML
          <div id="reactionview-errors" style="position: fixed; top: 20px; right: 20px; z-index: 10000; max-width: 400px;">
            <div style="background: #fee; border: 2px solid #fcc; border-radius: 8px; padding: 16px; font-family: monospace; font-size: 12px; line-height: 1.4; box-shadow: 0 4px 12px rgba(0,0,0,0.15);">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid #fcc;">
                <h3 style="margin: 0; color: #c33; font-size: 14px; font-weight: bold;">ReactionView Validation Errors</h3>
                <button onclick="this.closest('#reactionview-errors').style.display='none'" style="background: none; border: none; color: #c33; font-size: 18px; cursor: pointer; padding: 4px; line-height: 1; border-radius: 3px;" onmouseover="this.style.backgroundColor='#fcc'" onmouseout="this.style.backgroundColor='transparent'" title="Dismiss errors">&times;</button>
              </div>
              <div style="color: #666; font-size: 11px; margin-bottom: 12px;">#{escape_html(template_path)}</div>
              <div class="reactionview-error-list">
                #{error_list}
              </div>
            </div>
            <style>
              .reactionview-error-item {
                margin-bottom: 8px;
                padding: 8px;
                background: #fff;
                border-radius: 4px;
                border-left: 3px solid #c33;
              }
              .reactionview-error-type {
                font-weight: bold;
                color: #c33;
                margin-bottom: 4px;
              }
              .reactionview-error-message {
                color: #333;
                margin-bottom: 4px;
              }
              .reactionview-error-location {
                color: #666;
                font-size: 11px;
              }
            </style>
          </div>
        HTML
      end

      def inject_into_html(content, error_html)
        # Try to inject before closing body tag, or append at the end
        if content.include?('</body>')
          content.sub('</body>', "#{error_html}</body>")
        else
          content + error_html
        end
      end

      def escape_html(text)
        text.to_s
            .gsub('&', '&amp;')
            .gsub('<', '&lt;')
            .gsub('>', '&gt;')
            .gsub('"', '&quot;')
            .gsub("'", '&#39;')
      end
    end
  end
end
