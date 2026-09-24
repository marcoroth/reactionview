# Debug Mode

**A rendered page does not say which template wrote which part of it. Debug mode does.** It marks each element with the template and the ERB tag it came from, and loads the Herb dev tools into the page to show it.

## Turning it on

Debug mode follows the development environment unless you set it.

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.debug_mode = Rails.env.development?
end
```
:::

It changes the HTML your templates render, so keep it out of production.

## What it adds to the page

Every element a template writes gets `data-herb-debug-*` attributes naming the file, its path relative to `Rails.root` and, for ERB output, the tag and its line and column. Output that is not an element of its own is wrapped in a `<span style="display: contents">` so it can carry the same attributes without changing the layout.

```html
<strong><span data-herb-debug-outline-type="erb-output"
  data-herb-debug-erb="&lt;%= message.author %&gt;"
  data-herb-debug-file-relative-path="app/views/messages/index.html.erb"
  data-herb-debug-line="9" data-herb-debug-column="17"
  style="display: contents;">Ada</span></strong>
```

Debug mode also puts the dev tools script and a few `<meta>` tags into the `<head>` of every layout Herb renders. You do not import anything yourself.

## The dev tools

The dev tools show up as a small Herb badge in the top right corner of the page. From there you can outline the templates and partials on the page, see which ERB tag rendered an element, and open the file in your editor at that line.

The badge also counts what Herb reported about the page, the [validator findings](/guides/validation-overlays) and, with [runtime instrumentation](/guides/runtime-instrumentation) on, the SQL queries and render times each tag caused. Opening it lists each entry with the source around it and the render stack that led there.

Editor links use `config.project_path`. When your app runs in a container and your editor runs outside it, set it to where `Rails.root` is mounted on your machine, as described in [Custom project path for editor links](/reference/configuration#custom-project-path-for-editor-links).

## Next

[Development Tools](/guides/development-tools) covers the linter, the language server and the dev server, which bring the same information into your editor.
