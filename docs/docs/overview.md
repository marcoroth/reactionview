---
title: Welcome
---

<div align="center">
  <img src="/reactionview.png" alt="ReActionView Logo" width="200" height="200">
</div>

# Welcome to ReActionView

**ReActionView makes your existing HTML+ERB templates reactive.**

Rails 8.2 already renders HTML templates with [`Herb::Engine`](https://herb-tools.dev/projects/engine), which reads the HTML and the Ruby in a template together. ReActionView builds on that. A template can declare state the browser owns, change it from an HTML attribute, and have your controller answer when the server is needed, all in the `.html.erb` files you already have. It also brings Herb's error overlays, the dev tools and per-tag instrumentation to the page, and on Rails 8.1 and earlier it brings the engine itself.

You keep your controllers, your helpers, your partials and your layouts.

## Why should I use ReActionView?

Most Rails apps render HTML on the server and add JavaScript where the page needs to respond. That split works well until a small interaction grows its own controller, its own endpoint and its own copy of the markup, or until a template ships broken markup nobody noticed.

ReActionView answers both. A template can declare [state](https://herb-tools.dev/language/state) the browser owns and change it with an [action attribute](https://herb-tools.dev/language/actions), and every part of the page that reads it updates in place. When the change needs the server, the client asks the controller action the page already came from, and only what changed is updated. While you develop, a mismatched tag or a `<div>` inside a `<p>` shows up in the browser with the file and the line, and the dev tools say which template rendered what.

You do not have to take all of it. Each step builds on the one before, and you can stop at any of them.

## A gradient, not a rewrite

The first step is what Herb finds in your templates reaching you. Rails 8.2 compiles them with Herb, and ReActionView reports what it finds, in the browser while you develop and, through the [language server](https://herb-tools.dev/projects/language-server), in your editor. On Rails 8.1 and earlier, `config.intercept_erb` is what compiles your `.html.erb` templates with Herb at all.

The second step is debug mode and the dev tools. The panel in the corner of the page shows which template rendered which element, what each render cost, and the queries a tag ran.

The third step is state and actions. A menu that opens, a composer that appears, a tab that switches all become a declaration and an attribute in the template, with no JavaScript of your own.

The fourth step is letting the server answer. A select that re-sorts a list or a filter that narrows it sends the new state to the same controller action, and the list updates in place. A form can add its row to a list before the server has answered.

The last step is deferring what is slow. An [`<Async>`](https://herb-tools.dev/language/components#async) block leaves its content out of the first response, so the page arrives at once and the slow part follows.

::: warning Reactive templates are experimental
State, actions, slots and components need ReActionView `^0.6.0` and Herb `^0.11.0`. Their markup, the payload and the JavaScript API may change between releases. Validation, debug mode and the dev tools do not depend on them.
:::

## When ReActionView is not the right fit

ReActionView renders HTML+ERB. A view layer built on Phlex, Haml or Slim has nothing for it to read, and templates that produce JSON, text or XML are left to Rails.

If most of your interface is already a single-page application talking to an API, ReActionView will not replace it. It is at its best when the server renders the page and the browser needs to respond in a few places.

## Goals

ReActionView exists to make the Rails view layer tell you more. Errors should point at a line, not at a stack trace. The tools you use in the editor should agree with what renders in the browser. Interactivity should start from the template you already have and grow only as far as the page needs.

It also aims to stay out of your way. Templates stay HTML+ERB, controllers stay controllers, and removing ReActionView leaves an app that still renders.

## How we got here

ReActionView started as the Rails half of the [Herb](https://herb-tools.dev) project. The Herb parser was introduced at RubyKaigi 2025, and the linter, formatter and language server followed at RailsConf 2025. ReActionView launched at [Rails World 2025](https://www.rubyevents.org/talks/introducing-reactionview-an-actionview-compatible-erb-engine) together with `Herb::Engine` and the dev tools, and reactive templates followed in 2026.

Rails 8.2 then took the engine itself into the framework, so an app on the 8.2 framework defaults renders HTML templates with Herb without installing anything. That left ReActionView the parts Rails does not do on its own, which are reactive templates, the validators and overlays, the dev tools and the instrumentation. [Rails Integration](/integrations/rails) explains how the two fit together.

## Where to go next

[Setup](/installation) installs ReActionView and checks that it works. The [Quick Start](/quick-start) then builds one small page, from a plain template to one the server updates in place.
