const defaultSidebar = [
  {
    text: "Getting Started",
    collapsed: false,
    items: [
      { text: "Overview", link: "/overview" },
      { text: "Installation", link: "/installation" },
    ],
  },
  {
    text: "Guides",
    collapsed: false,
    items: [
      { text: "Debug Mode", link: "/guides/debug-mode" },
      { text: "Validation Overlays", link: "/guides/validation-overlays" },
      { text: "Development Tools", link: "/guides/development-tools" },
    ],
  },
  {
    text: "Integration",
    collapsed: false,
    items: [
      { text: "Rails", link: "/integrations/rails" },
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
      copyright: "Copyright © 2025 Marco Roth and the ReActionView Contributors.",
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
