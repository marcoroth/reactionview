# Configuration

ReActionView is configured in `config/initializers/reactionview.rb`, which the install generator creates.

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.intercept_erb = true
  config.debug_mode = Rails.env.development?
  config.slots = true
end
```
:::

## Options

| Option | Default | Controls |
| --- | --- | --- |
| [`intercept_erb`](#intercept-erb) | `false` | Whether `.html.erb` templates render through Herb |
| [`debug_mode`](#debug-mode) | on in development | Debug attributes and the dev tools |
| [`validation_mode`](#validation-mode) | `:raise` in test, `:overlay` otherwise | What happens when a validator reports a problem |
| [`slots`](#slots) | `false` | Reactive templates, and the default slot mode |
| [`dev_server`](#dev-server) | on in development | Whether the Herb dev server starts with Rails |
| [`dev_server_port`](#dev-server-port) | chosen per project | The port the dev tools connect to |
| [`project_path`](#custom-project-path-for-editor-links) | `Rails.root` | Where editor links point |
| [`external_template_mode`](#templates-from-gems) | `:fallback` | How templates from gems are compiled |
| [`instrumentation`](/guides/runtime-instrumentation) | on in development | Per-tag SQL, render time and translation measurements |
| [`engine.visitors`](#compile-visitors) | empty | Extra visitors for every compile |
| [`engine.parser_options`](#parser-options) | `{}` | Parser options for every compile |

## `intercept_erb`

Renders `.html.erb` templates through `Herb::Engine`. Templates named `.html.herb` render through Herb whether this is on or not. Only templates with the `html` format are intercepted.

**Default**: `false`

## `debug_mode`

Adds debug attributes to rendered elements and loads the dev tools into the page. [Debug Mode](/guides/debug-mode) describes both.

**Default**: on in development, off everywhere else.

## `validation_mode`

Decides what happens when a validator, such as the nesting or security validator, reports a problem in a template.

| Mode | Behavior |
| --- | --- |
| `:overlay` | The page renders, and the problem is reported to the dev tools |
| `:raise` | Rendering stops with an error |
| `:none` | The problem is not reported |

A template that cannot be parsed never renders, whatever the mode. [Validation Overlays](/guides/validation-overlays) explains the difference.

**Default**: `:raise` in the test environment, `:overlay` everywhere else.

## `slots` <Badge type="tip" text="^0.6.0" />

Turns on reactive templates. With slots on, ReActionView registers the `slots` format, adds the `herb_state` helper to controllers and views, and compiles every template with slot markers.

| Value | Behavior |
| --- | --- |
| `false` | Reactive templates are off |
| `true` | On, and templates without a `herb:slots` directive use `server` mode |
| `:server` | Same as `true` |
| `:client` | On, and templates without a directive use `client` mode |

A [`herb:slots`](https://herb-tools.dev/language/slots#herb-slots) directive in a template always wins over this setting. Any other value raises an `ArgumentError` at boot.

**Default**: `false`

## `dev_server` <Badge type="tip" text="^0.6.0" />

With `slots` on in development, ReActionView starts the Herb dev server inside your Rails server. Set this to `false` to leave the dev server off.

**Default**: on in development.

## `dev_server_port` <Badge type="tip" text="^0.6.0" />

The port the dev tools connect to. Herb picks one per project, so two applications on the same machine do not collide. Set it when you need a fixed port, for example to forward it out of a container.

**Default**: chosen from the project path in development, unset elsewhere.

## Custom project path for editor links <Badge type="info" text="^0.4.0" />

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

## Templates from gems <Badge type="info" text="^0.4.0" />

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

Anything other than these three values raises an `ArgumentError` when you set it, so a typo fails at boot instead of changing how your templates compile:

```ruby
config.external_template_mode = :warm
# => ArgumentError: external_template_mode must be one of :fallback, :skip, or :compile, got :warm
```

::: info Why :fallback and not :skip
Skipping silently means you never find out that a gem's templates cannot be compiled, which matters if you later want to rely on Herb processing them. `:fallback` keeps every environment behaving the same way and tells you which templates fell back. See [herb#1508](https://github.com/marcoroth/herb/issues/1508).
:::

::: warning
In `:fallback` mode, external templates are always compiled with `validation_mode: :raise` regardless of your `validation_mode` setting, so a gem template can never put a validation overlay on your page over markup you cannot change.
:::

## Compile visitors <Badge type="info" text="^0.5.0" />

`config.engine.visitors` is the stack of visitors ReActionView adds to every compile on top of its own. It is a `Herb::Visitor::Stack`, so a visitor can be appended with `use` or placed against a built-in with `insert_before` and `insert_after`:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.engine.visitors.use(MyVisitor.new)
  config.engine.visitors.insert_after(Herb::Engine::Slots::Visitor, MyRewriter.new)
end
```
:::

The order visitors run in follows what they declare about themselves. A visitor that reads the ERB a template was written with runs before any visitor that rewrites it, a visitor that reads `<style>` blocks runs after any visitor that rewrites them, and a visitor that inlines other templates runs first. ReActionView merges its built-ins with your stack and lets `Herb::Visitor::Stack.arrange` order the result, so placing a visitor where its declarations do not allow moves it instead of failing the compile. A visitor that rewrites ERB takes part in the page compile only. The values, block and schema compiles that answer the client leave rewriters out, since nothing reads what they would wrap there.

`config.transform_visitors` still works and fills the same stack, and says it is deprecated when used.

## Parser options <Badge type="info" text="^0.5.0" />

Visitors declare the parser options they need themselves, and Herb reads the rest from the `engine.parser_options` section of `.herb.yml`. An application without a `.herb.yml` can set them on the engine instead:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.engine.parser_options = { strict_locals: true }
end
```
:::

These are merged over the project's parser options and handed to every compile alike, so the page, the values it answers with, and the schema never parse a template differently from one another. The keys are the ones `.herb.yml` uses, so the engine and `herb lint` keep reading the same names. An option that contradicts what a visitor requires raises at compile time, the same way it would when passed to `Herb::Engine` directly.

**Default**: `{}`, which leaves the engine to its own defaults.
