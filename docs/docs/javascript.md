# JavaScript Client <Badge type="info" text="^0.5.0" />

Templates that declare states, slots, fragments or actions need the client runtime on the page. It indexes the markers the gem compiles into your HTML, keeps state, applies values the server sends back, and drives `data-herb-*` attributes.

The runtime is [`@herb-tools/client`](https://github.com/marcoroth/herb/tree/main/javascript/packages/client). ReActionView ships it two ways so it matches the gem you have installed. The `reactionview` npm package bundles it for applications with a JavaScript bundler, and the gem carries the same build as an asset for applications on importmap.

## Importmap

The gem draws its own importmap, so `reactionview` is already pinned and preloaded in every application that uses importmap-rails. Import it from your entry point and you are done:

:::code-group
```js [app/javascript/application.js]
import "reactionview"
```
:::

The asset lives inside the gem, so there is nothing to install from npm and nothing to add to `config/importmap.rb`, and the runtime always matches the gem version. The gem's pins are drawn before your `config/importmap.rb`, so a pin of your own for `reactionview` wins if you ever need to point the name somewhere else.

## Bundlers

With jsbundling-rails, Vite or any other bundler, install the package and import it from your entry point:

```bash
yarn add reactionview
```

```js
import "reactionview"
```

Keep the npm package on the same version as the gem. The compiled markers and the values payload are a contract between the two, and a mismatch is the first thing to check when a page stops reacting.

## Starting with options

Importing the package starts the runtime with `{ state: { debounce: 150 } }`, which delays server writes while the user is still typing. To choose the options yourself, call `Runtime.start` right after the import. The call has to happen synchronously in the same module, since the automatic start runs on the next microtask and yields to a runtime that is already up. Your options replace the defaults instead of merging with them.

```js
import { Runtime } from "reactionview"

Runtime.start({ state: { debounce: 300 } })
```

`Runtime` is the `@herb-tools/client` class, so `Runtime.get()` returns the running instance with its `state`, `slots`, `outbox` and `actions`, the same object `window.HerbRuntime` points at.

## Working with states from JavaScript

Everything `@herb-tools/client` exports is available from `reactionview`, including `useState` for a Stimulus controller or any object with an `element`:

```js
import { Controller } from "@hotwired/stimulus"
import { useState } from "reactionview"

export default class extends Controller {
  connect() {
    this.state = useState(this)
  }

  draftChanged(value, previous) {
    console.log(`draft went from ${previous} to ${value}`)
  }
}
```

`useState` reads the states declared around the element, calls a `<name>Changed` method on the host whenever one of them changes, and unsubscribes when the host disconnects. `stateFor(element)` does the reading alone when you do not need the callbacks.

## Development tools

The development tools are a separate script the gem injects into your layout when `config.debug_mode` is on. They attach to the runtime this page describes and never need to be imported yourself. See [Development Tools](/guides/development-tools).
