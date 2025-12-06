import { HerbOverlay } from "@herb-tools/dev-tools"

interface TimingData {
  duration: number
  template: string
  path: string
  identifier: string
}

interface TimingsMap {
  [renderId: string]: TimingData
}

export function enhanceLabelsWithRenderTimes(): void {
  const timings = loadTimingData()

  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          const element = node as HTMLElement

          if (element.classList?.contains('herb-overlay-label')) {
            enhanceLabel(element, timings)
          } else {
            element.querySelectorAll?.('.herb-overlay-label').forEach((label) => {
              enhanceLabel(label as HTMLElement, timings)
            })
          }
        }
      })
    })
  })

  observer.observe(document.body, {
    childList: true,
    subtree: true
  })

  document.querySelectorAll('.herb-overlay-label').forEach((label) => {
    enhanceLabel(label as HTMLElement, timings)
  })
}

function loadTimingData(): TimingsMap {
  const script = document.getElementById('reactionview-timings')
  if (!script) return {}

  try {
    return JSON.parse(script.textContent || '{}')
  } catch (e) {
    console.error('Failed to parse ReactionView timing data:', e)
    return {}
  }
}

function enhanceLabel(label: HTMLElement, timings: TimingsMap): void {
  let parent = label.parentElement
  while (parent) {
    const renderId = parent.getAttribute('data-reactionview-id')

    if (renderId && timings[renderId]) {
      const timing = timings[renderId]
      const shortName = parent.getAttribute('data-herb-debug-file-name') || timing.template

      if (!(label as any)._reactionviewEnhanced) {
        label.textContent = `${shortName} (${timing.duration} ms)`

        label.addEventListener('mouseenter', () => {
          label.textContent = `${timing.path} (${timing.duration} ms)`

          document.querySelectorAll('.herb-overlay-label').forEach(otherLabel => {
            (otherLabel as HTMLElement).style.zIndex = '1000'
          })

          label.style.zIndex = '1002'
        })

        label.addEventListener('mouseleave', () => {
          label.textContent = `${shortName} (${timing.duration} ms)`
          label.style.zIndex = '1000'
        })

        ;(label as any)._reactionviewEnhanced = true
      }

      break
    }

    parent = parent.parentElement
  }
}

export { HerbOverlay }
