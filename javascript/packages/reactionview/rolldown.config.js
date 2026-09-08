export default [
  {
    input: "src/index.ts",
    output: [
      {
        file: "dist/reactionview.esm.js",
        format: "esm",
        sourcemap: true
      },
      {
        file: "../../../app/assets/javascripts/reactionview.esm.js",
        format: "esm",
        sourcemap: true
      },
    ],
    external: [],
    platform: "browser"
  },
]
