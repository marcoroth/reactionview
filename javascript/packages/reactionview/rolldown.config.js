export default [
  {
    input: "src/index.ts",
    output: [
      {
        file: "dist/reactionview.esm.js",
        format: "esm",
        sourcemap: true,
        minify: true
      },
      {
        file: "../../../app/assets/javascripts/reactionview.esm.js",
        format: "esm",
        sourcemap: true,
        minify: true
      },
    ],
    external: [],
    platform: "browser"
  },
]
