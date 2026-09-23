# Stimulus and Turbo <Badge type="tip" text="^0.6.0" /> <Badge type="warning" text="experimental" />

**ReActionView is built to share a page with Hotwire.** Turbo drives navigation, Stimulus holds behavior that is more than writing a value, and reactive templates cover the part in between. The client knows about both, so nothing has to be wired up twice, and a Stimulus controller can read and write the same states the template declares.

## Turbo

The client watches the whole document for markup that arrives or leaves. A Turbo visit that replaces the body, a Turbo Frame that loads, a Turbo Stream that appends a row and a page restored from Turbo's cache are all indexed as they land, with nothing to call on navigation.

The dev tools read the diagnostics for the new page on every Turbo navigation too, so the badge always describes the page you are looking at.

## Stimulus

A Stimulus controller can read and write the states around its element with `useState`. It calls a `<name>Changed` method whenever one of those states changes, and stops when the controller disconnects.

:::code-group
```js [app/javascript/controllers/composer_controller.js]
import { Controller } from "@hotwired/stimulus"
import { useState } from "reactionview"

export default class extends Controller {
  connect() {
    useState(this)
  }

  openChanged(open) {
    if (open) this.element.querySelector("textarea")?.focus()
  }
}
```
:::

:::code-group
```erb [app/views/messages/_composer.html.erb]
<%# herb:slots client %>
<%# herb:state (open: false) %>

<div data-controller="composer">
  <button data-herb-toggle="open">New message</button>
  <% if open %><textarea name="message[body]"></textarea><% end %>
</div>
```
:::

The button opens the composer without any JavaScript. The controller only adds what an attribute cannot say, which is moving focus into the textarea once it appears.

`useState` also gives the controller `this.state`, so it can drive the template's state from JavaScript with `this.state.set({ open: false })`, `toggle`, `increment`, `decrement` and `reset`. `this.state.get("open")` reads the current value, and `on("open", listener)` subscribes without defining a method. Inside a keyed row, all of it resolves to that row's own state, so a controller on a row does not have to know which row it is on.

This works in the other direction too. A state a controller writes updates every part of the template that reads it, so a Stimulus controller can drive markup it does not own without touching the DOM itself.

## Behaviors

For JavaScript that should follow elements as the client adds, moves and removes them, such as an animation when a row leaves, the client has behaviors. A behavior registers for an attribute and is told when an element with it connects, updates, moves or is about to leave. [Behaviors](https://herb-tools.dev/projects/client#behaviors) in the client reference covers every callback.

## Next

[Runtime Instrumentation](/guides/runtime-instrumentation) covers measuring what a page does while it renders.
