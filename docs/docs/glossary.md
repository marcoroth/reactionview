# Glossary

These are the terms the ReActionView docs use. Terms that belong to the template language, such as state, slot, key and action, are defined in the [Herb glossary](https://herb-tools.dev/glossary).

## Client

The JavaScript that runs in the browser, loaded with `import "reactionview"`. It finds the slots in the page, holds the states, runs actions and asks the server for what it cannot build itself. See [JavaScript Client](/javascript).

## Debug mode

The setting that marks each element with the template and ERB tag it came from, and loads the dev tools. See [Debug Mode](/guides/debug-mode).

## Dev server

The Herb dev server, started inside your Rails server in development when `config.slots` is on. It watches your templates and updates open pages when one changes. See [Development Tools](/guides/development-tools#the-dev-server).

## Dev tools

The Herb badge and panel in the top right corner of a page in development. It shows what Herb reported about the page and which template rendered what.

## Intercepting

Handing `.html.erb` templates to ReActionView, turned on with `config.intercept_erb`. On Rails 8.2 that takes them from Rails' own Herb implementation, and on earlier versions from Rails' ERB handler. See [Rails Integration](/integrations/rails#template-handlers).

## Mode

Whether a template's unrendered branches are built by the server or the browser, set with `<%# herb:slots server %>` or `<%# herb:slots client %>`. See [Server and Client Rendering](/guides/rendering-modes).

## Optimistic row

The row a form with `data-herb-into` adds to a list before the server has answered. See [Collections and Forms](/guides/collections).

## Slots format

The `slots` request format, with the MIME type `application/vnd.herb.slots+json`, that the client uses to ask your controllers for a page's values. See [Rails Integration](/integrations/rails#what-config-slots-adds).

## Validation mode

What happens when a validator finds a problem in a template, set with `config.validation_mode`. See [Validation Overlays](/guides/validation-overlays).

## Values request

A request in the slots format. It carries the browser's states in a `Herb-State` header, runs your controller action as usual, and answers with the values that changed instead of HTML. Your controller reads the states with `herb_state`.
