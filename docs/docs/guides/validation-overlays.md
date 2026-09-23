# Validation Overlays

**A template problem is cheapest to fix while the template is still open in your editor.** ReActionView reports what Herb finds in the page you are looking at, with the file, the line and the markup around it.

## Two kinds of problems

Herb finds two kinds of problems, and they are handled differently.

A **parse error** means Herb cannot read the template as HTML+ERB. A tag closed with the wrong name, an element opened inside an `if` and closed outside it, or an ERB tag missing its `%>` are all parse errors. A template with one does not render, in any environment, because there is no correct output to send. [Templates](https://herb-tools.dev/language/templates#what-herb-rejects) lists what Herb rejects.

A **validator finding** means the template can be read, but what it produces is likely wrong. A `<div>` inside a `<p>`, a link inside a link, or ERB output in the middle of an open tag are validator findings. Browsers repair some of these silently, which is how they end up in production. What happens next depends on `validation_mode`.

## What `validation_mode` does

:::code-group
```ruby [config/initializers/reactionview.rb]
ReActionView.configure do |config|
  config.validation_mode = :overlay
end
```
:::

In `:overlay` mode, the default outside of tests, the page renders and each finding is reported to the dev tools. In `:raise` mode, the default in tests, a finding stops the render with an error, so a test that renders the template fails. `:none` turns the validators off.

The test default is deliberate. You see findings in the browser while you work, and your test suite refuses to let them through.

## An example

This template renders in every browser, and both of its problems are invisible on the page.

:::code-group
```erb [app/views/pages/nesting.html.erb]
<h1>Nesting</h1>

<p>
  <div>A block inside a paragraph</div>
</p>

<a href="/messages"><a href="/messages/1">Nested link</a></a>
```
:::

In development, the Herb badge in the top right corner turns red and shows a count of 2. Opening it lists both findings. Each one shows the validator that found it, the message, the lines around it with the offending markup underlined, and the render stack that led to the template.

```
InvalidNestingError   Block element <div> cannot be nested inside <p> at line 4
NestedAnchorError     Anchor <a> cannot be nested inside another anchor at line 7
```

The findings also reach your editor through the [Herb Language Server](https://herb-tools.dev/projects/language-server), so the same problem can be fixed before the page is ever opened.

## What the validators check

| Validator | Finds |
| --- | --- |
| Security | ERB output in an attribute name or in the middle of an open tag, where no escaping makes it safe |
| Nesting | Elements HTML does not allow inside each other, such as a block inside a `<p>` or a link inside a link |
| Accessibility | Missing or invalid accessibility attributes |
| Render | `render` calls whose arguments cannot work, such as `locals:` keywords passed without `partial:` |

The [Engine](https://herb-tools.dev/projects/engine#validators) page covers each validator, and `.herb.yml` can turn any of them off for a project.

## Templates from gems

Templates that ship inside gems are compiled with `validation_mode: :raise` and fall back to Rails' own ERB handler when Herb cannot compile them, so a gem's markup never puts findings on your page that you cannot fix. [Templates from gems](/reference/configuration#templates-from-gems) has the options.

## Next

[Debug Mode](/guides/debug-mode) covers the rest of what the dev tools show about a page.
