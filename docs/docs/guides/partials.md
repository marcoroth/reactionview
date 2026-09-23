# Partials <Badge type="tip" text="^0.6.0" /> <Badge type="warning" text="experimental" />

**A partial should work on its own, and the page that renders it should decide how it fits in.** Every partial compiles as its own template, with its own slots and its own states, so the same partial can be dropped into any page.

## Declaring what a partial takes

Strict locals are the place to start. A `<%# locals: (...) %>` comment at the top of a partial says which locals it takes, Rails raises when a caller gets them wrong, and the Herb linter checks every `render` call against it before the page runs.

:::code-group
```erb [app/views/albums/_card.html.erb]
<%# locals: (album:, compact: false) %>

<article class="<%= "compact" if compact %>">
  <h2><%= album.title %></h2>
</article>
```
:::

[Strict locals](https://herb-tools.dev/language/strict-locals) covers the syntax and what Herb checks.

## A partial with its own state

A partial declares states the same way a page does. Each rendering gets its own copy, so ten cards on a page are ten independent `open` states.

:::code-group
```erb [app/views/albums/_card.html.erb]
<%# locals: (album:) %>
<%# herb:slots client %>
<%# herb:state (open: false) %>

<article>
  <h2><%= album.title %></h2>
  <button data-herb-toggle="open">Tracks</button>
  <% if open %><ol><li>Intro</li></ol><% end %>
</article>
```
:::

To let the caller choose where a state starts, seed it from a strict local, as in `<%# herb:state (open: open_initially) %>`. The name has to differ from the local, since a local belongs to the caller and a state belongs to the browser.

## Sharing a state with the page

Sometimes the page needs to drive a partial's state, such as an **Expand all** button above a list of cards. The `render` call binds the partial's state to one of the page's own with `state:`.

:::code-group
```erb [app/views/albums/index.html.erb]
<%# herb:slots client %>
<%# herb:state (expanded: false) %>

<button data-herb-toggle="expanded">Expand all</button>

<% @albums.each do |album| %>
  <%# herb:key album.id %>
  <%= render "albums/card", album: album, state: { open: expanded } %>
<% end %>
```
:::

The partial's `open` and the page's `expanded` are now one state. The button opens every card, and a toggle inside any card writes `expanded`. The same partial rendered without `state:` keeps its own `open`.

The compiler opens the partial to check each binding, so name it by its full path, like `"albums/card"`. A name the partial does not declare, or a value of another kind, is a compile error at the `render` call. [Binding a partial's state](https://herb-tools.dev/language/state#binding-a-partial-s-state) has the rules.

## Next

[Deferred Content](/guides/deferred) covers leaving slow parts of a page out of the first response.
