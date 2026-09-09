# reactionview

The ReActionView client runtime for Rails applications. This package bundles [`@herb-tools/client`](https://github.com/marcoroth/herb/tree/main/javascript/packages/client) into one self-contained module and starts it on import, so a page rendered by the `reactionview` gem becomes interactive with a single line.

```js
import "reactionview"
```

The same build ships inside the gem as `reactionview.esm.js`, and the gem draws its own importmap, so applications on importmap-rails get it without installing anything from npm. Applications with a JavaScript bundler install this package instead.

The automatic start uses `{ state: { debounce: 150 } }`. To choose the options yourself, call `Runtime.start` right after the import. The call has to happen synchronously in the same module, before the automatic start gets its turn, and it replaces the defaults instead of merging with them.

```js
import { Runtime } from "reactionview"

Runtime.start({ state: { debounce: 300 } })
```

Everything `@herb-tools/client` exports is re-exported here, including `useState` for wiring a controller or any other host object to the states around its element.

See the [documentation](https://reactionview.dev/javascript) for the full setup.
