# Server and Client Rendering <Badge type="tip" text="^0.6.0" /> <Badge type="warning" text="experimental" />

**Every `if` in a template has a branch the page did not render.** When a state change needs that branch, something has to build it. The `herb:slots` directive decides whether that is the server or the browser.

## The two modes

:::code-group
```erb [app/views/messages/index.html.erb]
<%# herb:slots server %>
```
:::

In **server** mode, the page carries only what rendered. When the client needs a branch it has not seen, it asks the same URL for it with the current states, and your controller runs as usual. This is the default, for `<%# herb:slots client %>` without a mode and for `config.slots = true`.

:::code-group
```erb [app/views/messages/index.html.erb]
<%# herb:slots client %>
```
:::

In **client** mode, the page also carries the markup of every branch that did not render, parked in a `<template>`. The client builds a branch from it without a request. The parked markup is removed from the document once the client has read it.

## Choosing a mode

Start with server mode. It sends the least markup, and anything a state change needs goes through your controller, so data the controller loads with `herb_state` is always current.

Switch a template to client mode when it has branches the user flips often and that need nothing from the server, such as a composer, a tab strip or an inline editor. A composer whose form is plain markup opens with one request in server mode and none in client mode. A branch that contains Ruby output, such as a path helper or a CSRF token, still needs the server to fill in those values.

The mode is per template. `config.slots = :client` makes client mode the default for templates without a directive, and a directive always wins over the setting.

## What still goes to the server in client mode

In client mode the client evaluates every read it can, such as `<% if order == "newest" %>`, and asks the server only for Ruby it cannot run itself, such as `<%= order.humanize %>`.

That has a consequence worth knowing before you switch. If a controller loads data with `herb_state` and the template only reads that state in shapes the client can evaluate, a change never reaches the server in client mode. The sentence above the list updates, and the list itself does not. Keep such templates in server mode.

::: tip
The linter's [`herb-state-valid-reads`](https://herb-tools.dev/linter/rules/herb-state-valid-reads) rule lists the reads the client can evaluate. [Reading a state](https://herb-tools.dev/language/state#reading-a-state) has the same list.
:::

## What the markup looks like

Both modes mark the dynamic parts of the output with comments and `data-herb-slot` attributes, so the client can find them again. The page renders the same with or without the client. [Slots](https://herb-tools.dev/language/slots#output) shows the markers for a small template in each mode.

## Next

[Partials](/guides/partials) covers how state and slots work across `render` calls.
