import { Runtime } from "@herb-tools/client"

if (typeof document !== "undefined") {
  queueMicrotask(() => {
    if (!Runtime.get() && !window.HerbRuntime) {
      Runtime.start({ state: { debounce: 150 } })
    }
  })
}
