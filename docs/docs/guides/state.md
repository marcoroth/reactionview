# State and Actions <Badge type="tip" text="^0.6.0" /> <Badge type="warning" text="experimental" />

**Whether a menu is open is not something your database needs to know.** Most of what makes a page feel responsive is state that belongs to the browser, and ReActionView lets the template say so instead of reaching for a controller, an endpoint or a Stimulus controller.

## Who is this for?

If your page already works with full page loads and Turbo, you may not need any of this. State is for the small interactions in between, such as a composer that opens, a tab that switches, a character count, or a filter the list below it follows. If you find yourself writing a Stimulus controller whose only job is to toggle a class or show an element, a state and an action replace it.

## Declaring state

A template declares the states it owns in one directive, each with a default.

:::code-group
```erb [app/views/messages/_composer.html.erb]
<%# herb:slots client %>
<%# herb:state (open: false, draft: "") %>

<button data-herb-toggle="open">New message</button>

<% if open %>
  <textarea name="message[body]"><%= draft %></textarea>
  <p><%= draft.length %> characters</p>
<% end %>
```
:::

The server renders every state with its default, so the first response is an ordinary page. From then on the browser owns the value. Every part of the page that reads it follows when it changes.

The default decides the kind. `open: false` is a Boolean, `draft: ""` is a String and `unread: 3` is an Integer, and those three cover almost every page. Floats, Arrays and Hashes are refused at compile time, and [Kinds](https://herb-tools.dev/language/state#kinds) explains why.

## Changing state with actions

An action is an HTML attribute that writes a state when an event fires.

:::code-group
```erb [app/views/messages/_tabs.html.erb]
<%# herb:slots client %>
<%# herb:state (tab: "inbox", unread: 3) %>

<nav>
  <button data-herb-set="tab=inbox">Inbox (<%= unread %>)</button>
  <button data-herb-set="tab=archive">Archive</button>
  <button data-herb-decrement="unread">Mark one read</button>
</nav>

<% if tab == "inbox" %>
  <p>Your inbox</p>
<% else %>
  <p>Your archive</p>
<% end %>
```
:::

`data-herb-set` writes a value, `data-herb-toggle` flips a Boolean, `data-herb-increment` and `data-herb-decrement` count, and `data-herb-reset` goes back to the default. Each one runs on the element's natural event, a click for a button, `input` for a text field, `change` for a select. [Actions](https://herb-tools.dev/language/actions) covers every attribute, event clauses such as `keydown.esc@window->open=false`, and timing.

A form field can also be bound to a state. When `value` reads a String state, typing writes it, and everything else that reads the state follows. In the composer above, the character count updates as you type.

## When the server has to answer

Some reads need the server. Sorting a list, filtering it or looking something up all run Ruby the browser cannot run. When a state like that changes, the client asks the same URL again with the new values, and your controller reads them with `herb_state`.

:::code-group
```ruby [app/controllers/messages_controller.rb]
class MessagesController < ApplicationController
  def index
    @messages = Message.where(archived: herb_state("tab", "inbox") == "archive")
  end
end
```
:::

`herb_state(name, default)` returns the value the browser sent, or the default on a normal page load. It is available in controllers and views once `config.slots` is on. The request is described in the [Quick Start](/quick-start#step-3-let-the-server-answer).

::: warning The template has to read the state
The client only asks when a state that the template reads changes. A state that only your controller reads never makes the client ask. Read it somewhere on the page, such as in a heading that says which tab is open.
:::

## What the client cannot keep current

A read like `<%= draft.length %>` or `<% if tab == "inbox" %>` updates in place, because the client can evaluate it. A read like `<%= draft.titleize %>` is Ruby, so the page has to ask the server for its new value. [Reading a state](https://herb-tools.dev/language/state#reading-a-state) lists the shapes the client evaluates itself, and the linter points out the ones it cannot.

Template Ruby can read a state but never assign one, since the browser would never learn about the change. A state is changed by an action, a bound form field, or your own JavaScript.

## From JavaScript

A Stimulus controller can read and write the states around its element with `useState`, and gets a `<name>Changed` callback when one changes. [Stimulus and Turbo](/guides/stimulus-and-turbo) shows how.

## Next

[Collections and Forms](/guides/collections) covers lists, keyed rows and forms that add to a list before the server has answered.
