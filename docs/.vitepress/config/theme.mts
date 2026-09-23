const defaultSidebar = [
  {
    text: "Hello World",
    collapsed: false,
    items: [
      { text: "Welcome", link: "/overview" },
      { text: "Setup", link: "/installation" },
      { text: "Quick Start", link: "/quick-start" },
    ],
  },
  {
    text: "Guide",
    collapsed: false,
    items: [
      { text: "Validation Overlays", link: "/guides/validation-overlays" },
      { text: "Debug Mode", link: "/guides/debug-mode" },
      { text: "Development Tools", link: "/guides/development-tools" },
      { text: "State and Actions", link: "/guides/state" },
      { text: "Collections and Forms", link: "/guides/collections" },
      { text: "Server and Client Rendering", link: "/guides/rendering-modes" },
      { text: "Partials", link: "/guides/partials" },
      { text: "Deferred Content", link: "/guides/deferred" },
      { text: "Stimulus and Turbo", link: "/guides/stimulus-and-turbo" },
      { text: "Runtime Instrumentation", link: "/guides/runtime-instrumentation" },
    ],
  },
  {
    text: "Reference",
    collapsed: false,
    items: [
      { text: "Configuration", link: "/reference/configuration" },
      { text: "JavaScript Client", link: "/javascript" },
      { text: "Rails Integration", link: "/integrations/rails" },
    ],
  },
  {
    text: "Appendices",
    collapsed: false,
    items: [
      { text: "Glossary", link: "/glossary" },
    ],
  },
]

export function createThemeConfig() {
  return {
    logo: "/reactionview.png",
    nav: [
      { text: "Home", link: "/" },
      { text: "Documentation", link: "/overview" },
      { text: "GitHub", link: "https://github.com/marcoroth/reactionview" },
    ],
    outline: [2, 4],
    search: {
      provider: "local",
    },
    lastUpdated: {
      text: "Last updated",
      formatOptions: {
        dateStyle: "long",
      },
    },
    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright © 2025-2026 Marco Roth and the ReActionView Contributors.",
    },
    editLink: {
      pattern: "https://github.com/marcoroth/reactionview/edit/main/docs/docs/:path",
      text: "Edit this page on GitHub",
    },
    sidebar: {
      '/': defaultSidebar
    },
    socialLinks: [
      { icon: "github", link: "https://github.com/marcoroth/reactionview" },
      { icon: "twitter", link: "https://twitter.com/marcoroth_" },
      { icon: "mastodon", link: "https://ruby.social/@marcoroth" },
      { icon: "bluesky", link: "https://bsky.app/profile/marcoroth.dev" },
    ],
  }
}
