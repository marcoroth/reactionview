# Runtime Instrumentation

ReActionView can measure what a page did while it rendered, and file each measurement against the ERB tag that caused it. A `render` call that ran fifteen queries says so on the line it was written on, rather than in a log you have to correlate by hand.

## Configuration

Measuring follows development unless you say otherwise:

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.instrumentation.enabled = Rails.env.development?
end
```
:::

Measuring means instrumenting every ERB tag, which is worth it while you are working on a page and not while anyone else is reading one. Turning it off leaves your templates compiling exactly as they would without ReActionView's instrumentation.

## What it measures

Three measurements are built in, and each can be turned off on its own:

| Option | What it records | Reads as |
|---|---|---|
| `sql_queries` | The statements a tag ran, minus cached, schema and transaction queries | `5 SQL queries` |
| `render_times` | What a render cost, with its GC time and allocations | `1.4 ms` |
| `translations` | What a `t(...)` or `translate(...)` tag rendered | `Hello World` |

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.instrumentation.render_times = false
end
```
:::

The options are seeded with the keys they expect and refuse the ones they do not, so a mistyped option is an `ArgumentError` at boot instead of a measurement that quietly keeps running:

```ruby
config.instrumentation.render_time = false
# => ArgumentError: unknown instrumentation option :render_time, expected one of
#    [:enabled, :sql_queries, :render_times, :translations]
```

## Where the numbers come from

Rails already announces this work through `ActiveSupport::Notifications`, so nothing is measured twice. A render reports the duration, GC time and allocation count that Rails put on the event, and a query is skipped when it was served from cache, because that is not a query the page paid for.

Herb's instrumentation supplies the other half: it says which tag is rendering at any moment, so whatever a subscriber observes is filed against the tag that was open at the time.

## Where they show up

Measurements appear in the Herb dev tools panel in the browser, beside the diagnostics for the same page. Each one shows what was observed behind its count, so `5 SQL queries` opens to the statements themselves.

They are also written to a journal on disk, keyed by the template and a digest of its contents, which is what lets the Herb Language Server show them in your editor on the line they belong to. A template that has been edited since it was rendered shows nothing rather than something misleading.

## Measuring something of your own

The built-ins are ordinary subscribers and measurements. Anything your application knows how to observe can be recorded the same way:

```ruby
ActiveSupport::Notifications.subscribe("cache_read.active_support") do |*, payload|
  Herb::Engine::Runtime::Session.observe(:cache, payload[:key])
end

Herb::Engine::Runtime::Session.measurement(:cache, origin: "My App", code: "cache-reads") do |keys|
  "#{keys.size} cache #{"read".pluralize(keys.size)}"
end
```

The block is given everything observed for one tag and returns the line the tools show. Anything else it recorded stays available underneath it.
