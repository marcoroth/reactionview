const input = "src/index.ts"
const platform = "browser"

export default [
  {
    input,
    output: [
      {
        file: "dist/reactionview-dev-tools.umd.js",
        format: "umd",
        name: "ReActionViewDevTools",
        sourcemap: true
      },
      {
        file: "../../../app/assets/javascripts/reactionview-dev-tools.umd.js",
        format: "umd",
        name: "ReActionViewDevTools",
        sourcemap: true
      },
    ],
    external: [],
    platform,
    transform: {
      define: {
        "import.meta": "{}"
      }
    }
  },
  {
    input,
    output: [
      {
        file: "dist/reactionview-dev-tools.esm.js",
        format: "esm",
        sourcemap: true
      },
      {
        file: "../../../app/assets/javascripts/reactionview-dev-tools.esm.js",
        format: "esm",
        sourcemap: true
      },
    ],
    external: [],
    platform
  },
]
