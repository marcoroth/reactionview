import { initHerbDevTools, HerbOverlay, type HerbDevToolsOptions } from "@herb-tools/dev-tools"

export interface ReActionViewDevToolsOptions extends HerbDevToolsOptions {
  projectPath?: string
  autoInit?: boolean
}

export class ReActionViewDevTools {
  private herbOverlay: HerbOverlay | null = null
  private static instance: ReActionViewDevTools | null = null

  constructor(private options: ReActionViewDevToolsOptions = {}) {
    if (options.autoInit !== false) {
      this.init()
    }
  }

  init(): HerbOverlay {
    if (this.herbOverlay) {
      this.destroy()
    }

    this.herbOverlay = initHerbDevTools({
      projectPath: this.options.projectPath,
      ...this.options
    })

    return this.herbOverlay
  }

  destroy(): void {
    if (this.herbOverlay) {
      const existingMenu = document.querySelector(".herb-floating-menu")

      if (existingMenu) {
        existingMenu.remove()
      }
    }

    this.herbOverlay = null
  }

  getHerbOverlay(): HerbOverlay | null {
    return this.herbOverlay
  }

  static getInstance(): ReActionViewDevTools | null {
    return ReActionViewDevTools.instance
  }

  static setInstance(instance: ReActionViewDevTools | null): void {
    ReActionViewDevTools.instance = instance
  }
}

export function initReActionViewDevTools(options: ReActionViewDevToolsOptions = {}): ReActionViewDevTools {
  const existingInstance = ReActionViewDevTools.getInstance()

  if (existingInstance) {
    existingInstance.destroy()
  }

  const instance = new ReActionViewDevTools(options)
  ReActionViewDevTools.setInstance(instance)

  return instance
}

if (typeof window !== "undefined" && typeof document !== "undefined") {
  let isInitializing = false

  const initializeDevTools = () => {
    if (isInitializing) {
      console.log("ReActionView dev tools initialization already in progress, skipping...")

      return
    }

    const shouldAutoInit = document.querySelector(`meta[name="herb-debug-mode"]`)?.getAttribute("content") === "true" || document.querySelector("[data-herb-debug-erb]") !== null

    if (!shouldAutoInit) {
      console.log("ReActionView debug mode not detected, skipping dev tools initialization")
      return
    }

    isInitializing = true

    try {
      let projectPath: string | undefined
      const railsRoot = document.querySelector(`meta[name="herb-rails-root"]`)?.getAttribute("content")
      if (railsRoot) {
        projectPath = railsRoot
      }

      initReActionViewDevTools({
        projectPath,
        autoInit: true
      })

    } catch (error) {
      console.warn("Could not initialize ReActionView dev tools:", error)
    } finally {
      isInitializing = false
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeDevTools, { once: true })
  } else {
    setTimeout(initializeDevTools, 0)
  }

  document.addEventListener("turbo:load", initializeDevTools)
  document.addEventListener("turbo:render", initializeDevTools)
  document.addEventListener("turbo:visit", initializeDevTools)
}

declare global {
  interface Window {
    ReActionViewDevTools: {
      init: typeof initReActionViewDevTools
      ReActionViewDevTools: typeof ReActionViewDevTools
      HerbOverlay: typeof HerbOverlay
    }
  }
}

if (typeof window !== "undefined") {
  window.ReActionViewDevTools = {
    init: initReActionViewDevTools,
    ReActionViewDevTools,
    HerbOverlay
  }
}

export { HerbOverlay, type HerbDevToolsOptions }
