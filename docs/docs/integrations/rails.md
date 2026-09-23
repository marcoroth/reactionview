# Rails Integration

ReActionView supports Rails 7.0 through 8.2 on Ruby 3.2 or newer. It plugs into Action View as a template handler and changes nothing else about how Rails renders.

Rails 8.2 brings Herb to Rails on its own. ReActionView is what makes your existing HTML+ERB templates reactive, and it adds the validators, the overlays, the dev tools and the instrumentation on top.

## Template handlers

ReActionView registers a `herb` template handler, so `.html.herb` templates always render through `Herb::Engine`.

With `config.intercept_erb = true`, it also replaces the handler for `.html.erb`. Only templates with the `html` format are intercepted, together with the `slots` format reactive templates answer with. Mailer text parts, `.json.erb`, `.xml.erb` and every other format keep rendering through Rails' own ERB handler.

Templates that ship inside gems are handled separately, so a gem's markup can never break your pages. [Templates from gems](/reference/configuration#templates-from-gems) has the options.

## Rails 8.2 and the built-in Herb implementation

Rails 8.2 compiles HTML templates through Herb on its own when an application runs the 8.2 framework defaults, through `config.action_view.html_erb_implementation`. That covers plain compilation. Enabling `intercept_erb` on Rails 8.2 adds what Rails does not do on its own, which is the validators and transform visitors, validation modes, the debug tooling, the external template modes for gem templates, and reactive templates.

The two settings compose. When `intercept_erb` is off, Rails 8.2 compiles your HTML templates through its built-in Herb implementation and ReActionView only handles `.html.herb` templates. When `intercept_erb` is on, ReActionView takes over HTML template compilation, and templates it declines, such as gem templates in `:skip` or `:fallback` mode, compile through the default ERB implementation instead of the built-in Herb one.

On Rails 8.1 and earlier, `intercept_erb` remains the way to compile `.html.erb` templates through Herb at all.

## What `config.slots` adds <Badge type="tip" text="^0.6.0" />

Turning on `config.slots` registers the `slots` format with the MIME type `application/vnd.herb.slots+json`. The client sends its requests in that format, with the browser's states in a `Herb-State` header, to the same URL the page came from.

Your controller actions answer those requests without changes. ReActionView renders the same template without its layout and returns the page's values as JSON. A controller reads the browser's states with `herb_state`, which is also available in views. An action that responds to formats explicitly, such as `create` after a form send, answers with `format.slots`, as shown in [Collections and Forms](/guides/collections).

A response to a request that carried `Herb-State` is marked `Cache-Control: no-store`, since it depends on the state the browser sent.

## Assets

The client and the dev tools ship inside the gem. On importmap-rails, the gem pins `reactionview` itself. With Sprockets or Propshaft, the gem adds its assets to the asset paths. [JavaScript Client](/javascript) covers bundler setups.
