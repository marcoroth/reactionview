# Development Tools

**The browser is the last place a template mistake should show up.** ReActionView renders with the same parser as the Herb linter and language server, so what the page reports and what your editor reports agree.

## In your editor

The [Herb Language Server](https://herb-tools.dev/projects/language-server) shows parse errors and linter findings as you type, and formats templates on save. Zed includes it by default. VS Code and the other editors need an extension or a few lines of configuration, which the [editor pages](https://herb-tools.dev/integrations/editors) walk through.

With [runtime instrumentation](/guides/runtime-instrumentation) on, the language server also shows what a tag cost the last time the page rendered, on the line it was written on.

## The linter

The [Herb Linter](https://herb-tools.dev/projects/linter) checks HTML, ERB, accessibility and Action View conventions, and it knows the reactive syntax too. A state read the client cannot keep current, or an action whose operation does not match the state's kind, is reported before you open the page.

:::code-group
```bash [Terminal]
npx @herb-tools/linter
```
:::

Run it in CI the same way. [CI Integrations](https://herb-tools.dev/integrations/ci) has ready-made setups.

## The dev server <Badge type="tip" text="^0.6.0" />

With `config.slots` on in development, ReActionView starts the [Herb Dev Server](https://herb-tools.dev/projects/dev-server) inside your Rails server and prints where it listens.

```
* Herb Dev Server: ws://localhost:8593 (embedded)
```

The dev tools connect to it from every open page. When you save a template, the dev server compares the old and new syntax trees. It patches text and attribute changes into the open page, and asks the page to reload for anything structural.

Turn the dev server off with `config.dev_server = false`, and pin its port with `config.dev_server_port` when you need to forward it out of a container.

::: warning
The dev server is experimental and may not patch every change correctly. A reload always brings the page back in line with the template.
:::

## Next

[State and Actions](/guides/state) starts on reactive templates.
