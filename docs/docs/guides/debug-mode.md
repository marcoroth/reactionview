# Debug Mode

*This guide is coming soon.*

ReActionView's debug mode adds helpful metadata to HTML elements during development, making it easier to debug template issues and understand how your views are rendered.

## Overview

When debug mode is enabled, ReActionView injects debug attributes into HTML elements that help with:

- Template debugging
- Element identification
- Development workflow enhancement

## Configuration

Debug mode is enabled by default in development environments:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.debug_mode = Rails.env.development? && !ENV["REACTIONVIEW_DISABLE_DEBUG_MODE"]
end
```
:::

---

*For the latest updates, check back soon or follow the project on [GitHub](https://github.com/marcoroth/reactionview).*
