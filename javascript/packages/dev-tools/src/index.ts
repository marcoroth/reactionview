import { HerbDevTools, type HerbDevToolsOptions } from "@herb-tools/dev-tools"

type HerbOverlay = NonNullable<HerbDevTools["overlay"]>

export interface ReActionViewDevToolsOptions extends HerbDevToolsOptions {
  projectPath?: string
  autoInit?: boolean
}

export class ReActionViewDevTools {
  private devTools: HerbDevTools | null = null
  private static instance: ReActionViewDevTools | null = null

  constructor(private options: ReActionViewDevToolsOptions = {}) {
    if (options.autoInit !== false) {
      this.init()
    }
  }

  init(): HerbDevTools | null {
    this.destroy()

    HerbDevTools.instance?.stop()

    this.devTools = HerbDevTools.start({
      projectPath: this.options.projectPath,
      ...this.options
    })

    return this.devTools
  }

  destroy(): void {
    this.devTools?.stop()
    this.devTools = null
  }

  getHerbOverlay(): HerbOverlay | null {
    return this.devTools?.overlay ?? null
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

    if (ReActionViewDevTools.getInstance() && HerbDevTools.instance) {
      return
    }

    isInitializing = true

    try {
      const projectPath = document.querySelector(`meta[name="herb-project-path"]`)?.getAttribute("content") ?? undefined

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
}

declare global {
  interface Window {
    ReActionViewDevTools: {
      init: typeof initReActionViewDevTools
      ReActionViewDevTools: typeof ReActionViewDevTools
      HerbDevTools: typeof HerbDevTools
    }
  }
}

if (typeof window !== "undefined") {
  window.ReActionViewDevTools = {
    init: initReActionViewDevTools,
    ReActionViewDevTools,
    HerbDevTools
  }
}

export { HerbDevTools, type HerbDevToolsOptions }
