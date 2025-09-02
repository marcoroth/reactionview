# Installation

Get started with ReActionView in your Rails application.

## Requirements

- **Ruby**: 3.0+ (3.4+ recommended)
- **Rails**: 7.0+ (8.0+ recommended)
- **Herb**: The Herb gem will be installed automatically as a dependency

## Install the Gem

Add ReActionView to your Rails application's `Gemfile`:

```ruby
gem "reactionview"
```

Then run:

```bash
bundle install
```

## Run the Generator

ReActionView includes a Rails generator to set up the initial configuration:

```bash
rails generate reactionview:install
```

This creates the initializer with default configuration:

:::code-group
```ruby [config/initializers/reactionview.rb]
# frozen_string_literal: true

ReActionView.configure do |config|
  # Intercept .html.erb templates and process them with `Herb::Engine` for enhanced features
  # config.intercept_erb = true

  # Enable debug mode in development (adds debug attributes to HTML)
  config.debug_mode = Rails.env.development?
end
```
:::

## Configuration Options

### Basic Setup

For basic usage, you can start using `.html.herb` templates alongside your existing `.html.erb` files without any additional configuration.

### Enhanced Mode (Recommended)

To process **all** existing `.html.erb` templates through the Herb engine, enable ERB interception in your initializer:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.intercept_erb = true
  config.debug_mode = Rails.env.development?
end
```
:::

This gives you all the benefits of Herb's validation, security features, and debugging tools for your existing templates.

## Verify Installation

Create a test template to verify ReActionView is working:

:::code-group
```erb [app/views/test/index.html.herb]
<div class="test">
  <h1>ReActionView Test</h1>
  <p>Current time: <%= Time.current %></p>
</div>
```
:::

If you have debug mode enabled, you should see debug attributes in the rendered HTML when viewing in development mode.
