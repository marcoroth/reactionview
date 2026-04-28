import { nodeResolve } from "@rollup/plugin-node-resolve"
import typescript from "@rollup/plugin-typescript"
import postcss from "rollup-plugin-postcss"

export default {
  input: "src/index.ts",
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
  plugins: [
    nodeResolve(),
    postcss({
      inject: true,
      minimize: true,
    }),
    typescript({
      tsconfig: "./tsconfig.json"
    })
  ]
}
