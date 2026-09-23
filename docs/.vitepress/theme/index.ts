import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'

import './style.css'

import ReActionViewLanding from './components/ReActionViewLanding.vue'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('ReActionViewLanding', ReActionViewLanding)
  },
} satisfies Theme
