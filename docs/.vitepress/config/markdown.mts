import { groupIconMdPlugin } from "vitepress-plugin-group-icons"

export function createMarkdownConfig() {
  return {
    config(md) {
      md.use(groupIconMdPlugin)
    },
    // Explicitly load these languages for types highlighting
    languages: ["js", "jsx", "ts", "tsx", "bash", "shell", "ruby", "html", "erb"],
  }
}
