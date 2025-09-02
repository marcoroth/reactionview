import { defineConfig } from "vitepress"
import { createMarkdownConfig } from "./config/markdown.mts"
import { createViteConfig } from "./config/vite.mts"
import { createThemeConfig } from "./config/theme.mts"

const themeConfig = createThemeConfig()

const title = "ReActionView"
const description = "A new ActionView-compatible ERB engine with modern DX - re-imagined with Herb."

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title,
  description,
  srcDir: "./docs",
  base: "/",
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['link', { rel: 'icon', href: '/favicon-16x16.png', sizes: '16x16' }],
    ['link', { rel: 'icon', href: '/favicon-32x32.png', sizes: '32x32' }],
    ['link', { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' }],
    ['meta', { property: 'og:image', content: '/social.png' }],
    ['meta', { property: 'og:title', content: 'ReActionView' }],
    ['meta', { property: 'og:description', content: 'Enhanced ERB templates with Herb engine integration for Rails applications.' }],
    ['meta', { property: 'og:url', content: 'https://reactionview.dev' }],
    ['meta', { property: 'og:type', content: 'website' }],
  ],
  cleanUrls: true,
  markdown: createMarkdownConfig(),
  vite: createViteConfig(),
  themeConfig,
  transformPageData(pageData) {
    pageData.frontmatter.head ??= []

    const pageTitle = pageData.frontmatter.title || pageData.title

    pageData.frontmatter.head.push([
      'meta',
      {
        property: 'og:title',
        content: pageTitle ? `${pageTitle} | ${title}` : `${title} - ${description}`
      }
    ])
  },

  async buildEnd() {
    console.log('🎉 VitePress build completed successfully')
  }
})
