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

### Advanced Configuration

#### Custom Project Path for Editor Links <Badge type="info" text="^0.4.0" />

When your app runs somewhere other than where its files live, such as a Docker bind mount, a devcontainer, or a VM, the paths Rails sees aren't paths your editor can open. `config.project_path` says where `Rails.root` is mounted on the machine running your editor, and rewrites "open in editor" links to match:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  # Where Rails.root is mounted on the machine running your editor
  config.project_path = "/Users/you/myapp"

  # Or take it from the environment
  # config.project_path = ENV.fetch("PROJECT_PATH", Rails.root.to_s)
end
```
:::

With `Rails.root` at `/app` inside the container, a template at `/app/app/views/users/show.html.erb` then opens as `/Users/you/myapp/app/views/users/show.html.erb`.

**Default**: `Rails.root.to_s`

::: info Only editor links are affected
Local template detection and the `herb-project-path` meta tag stay on `Rails.root`. The meta tag is compared against the path the `herb dev` server reports, so overriding it would make the dev tools treat the page as a different project and ignore it.
:::

#### Templates From Gems <Badge type="info" text="^0.4.0" />

With `intercept_erb` enabled, ReActionView sees every `.html.erb` template Rails renders, including ones shipped inside gems. Those are not yours to fix, so they get their own handling:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.external_template_mode = :fallback
end
```
:::

| Mode | Behavior |
| --- | --- |
| `:fallback` (default) | Compile with Herb. If that fails, log a warning and fall back to Rails' own ERB handler, so the template renders exactly as it would without ReActionView. |
| `:skip` | Never compile templates from gems. |
| `:compile` | No special treatment. Your `validation_mode` applies to them just as it does to your own templates, and nothing is rescued. |

Templates are considered external when they live outside `Rails.root`, or inside `Bundler.bundle_path` for applications that vendor their gems with `bundle config set --local path vendor/bundle`.

Anything other than these three values raises an `ArgumentError` when you set it, so a typo fails at boot rather than changing how your templates compile:

```ruby
config.external_template_mode = :warm
# => ArgumentError: external_template_mode must be one of :fallback, :skip, or :compile, got :warm
```

::: info Why :fallback rather than :skip
Skipping silently means you never find out that a gem's templates cannot be compiled, which matters if you later want to rely on Herb processing them. `:fallback` keeps every environment behaving the same way and tells you which templates fell back. See [herb#1508](https://github.com/marcoroth/herb/issues/1508).
:::

::: warning
In `:fallback` mode, external templates are always compiled with `validation_mode: :raise` regardless of your `validation_mode` setting, so a gem template can never put a validation overlay on your page over markup you cannot change.
:::

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
