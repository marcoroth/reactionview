# Setup

ReActionView needs Ruby 3.2 or newer and Rails 7.0 or newer. It installs the `herb` gem as a dependency.

## Step 1: Install the gem

Add ReActionView to your application and run its generator.

:::code-group
```bash [Terminal]
bundle add reactionview
bin/rails generate reactionview:install
```
:::

The generator creates `config/initializers/reactionview.rb` and adds `import "reactionview"` to `app/javascript/application.js`.

## Step 2: Load the JavaScript client

In an application on importmap-rails, the gem pins `reactionview` for you, so there is nothing else to install. With jsbundling-rails, Vite or another bundler, install the npm package and keep it on the same version as the gem.

:::code-group
```bash [Terminal]
yarn add reactionview
```
:::

[JavaScript Client](/javascript) covers both setups and the options the client starts with.

## Step 3: Put your templates through ReActionView

With the Rails 8.2 framework defaults, Rails already compiles your HTML templates with Herb. `intercept_erb` hands them to ReActionView instead, which adds the validators and overlays, the debug tooling and reactive templates. On Rails 8.1 and earlier, it is also what compiles them with Herb at all. Templates named `.html.herb` always go through ReActionView.

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.intercept_erb = true
  config.debug_mode = Rails.env.development?
end
```
:::

[Rails Integration](/integrations/rails) explains how the setting combines with the Rails 8.2 default.

## Step 4: Turn on reactive templates <Badge type="tip" text="^0.6.0" />

[State](https://herb-tools.dev/language/state), [actions](https://herb-tools.dev/language/actions) and the other reactive features need slots. Turn them on for the whole application with `config.slots`.

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.intercept_erb = true
  config.debug_mode = Rails.env.development?
  config.slots = true
end
```
:::

In development, `config.slots` also starts the Herb dev server inside your Rails server. It needs no extra gems, and it prints the address it listens on when your server boots. Turn it off with `config.dev_server = false`.

## Check that it works

Start your server and open any page. In development, a small Herb badge appears in the top right corner. That is the dev tools, and it means the client is loaded and debug mode is on.

Now break a template on purpose. Change a closing tag so it no longer matches.

:::code-group
```erb [app/views/messages/index.html.erb]
<h1>Messages</h2>
```
:::

Reload the page. It no longer renders, and the error names the file, the line and the problem.

```
app/views/messages/index.html.erb:1:1: Opening tag `<h1>` at (1:1) doesn't have a matching closing tag `</h1>` in the same scope. (and 1 more error)
```

Fix the tag and the page renders again. Problems that do not stop a template from rendering, such as a `<div>` inside a `<p>`, show up on the badge instead. [Validation Overlays](/guides/validation-overlays) covers the difference, including what to check when the badge does not appear at all.

## Next

The [Quick Start](/quick-start) builds one page step by step, from a plain template to one the server updates in place. Every configuration option is listed in [Configuration](/reference/configuration).
