# Deferred Content <Badge type="tip" text="^0.6.0" /> <Badge type="warning" text="experimental" />

**The slowest part of a page should not decide when the rest of it arrives.** A chart that takes a second to compute, or comments far below the fold, can follow the page instead of holding it up.

## `<Async>`

An `<Async>` block leaves its content out of the first response and shows its `<Fallback>` instead. As soon as the page loads, the client asks for the content, and it replaces the fallback when it arrives.

:::code-group
```erb [app/views/dashboard/show.html.erb]
<%# herb:slots client %>

<h1>Dashboard</h1>

<Async>
  <%= render "dashboard/revenue_chart" %>
  <Fallback><p>Loading revenue</p></Fallback>
</Async>
```
:::

The first response only renders the heading and the fallback, so it comes back as fast as the rest of the page allows. The chart's queries run in the second request, through the same controller action.

## `<Lazy>`

A `<Lazy>` block works the same way, except that the client waits until the block nears the viewport. Content the reader never scrolls to is never requested.

:::code-group
```erb [app/views/posts/show.html.erb]
<%# herb:slots client %>

<Lazy>
  <%= render "comments/list", post: @post %>
  <Fallback><p>Loading comments</p></Fallback>
</Lazy>
```
:::

## Keeping it current

`poll` asks for the content again on an interval once it has loaded, which suits a counter or a status that changes on its own.

:::code-group
```erb [app/views/dashboard/show.html.erb]
<Async poll="30000">
  <%= render "dashboard/open_orders" %>
  <Fallback><p>Loading orders</p></Fallback>
</Async>
```
:::

`delay` keeps the fallback hidden for a few milliseconds, so a fast answer never flashes it, and `hold` keeps it up long enough not to flicker once it has appeared.

## Content that depends on a state

A `<Fragment>` is for content that is already on the page but goes stale when a state changes, because the server has to render it again. Its fallback stands in while the new content is on its way.

:::code-group
```erb [app/views/weather/_lookup.html.erb]
<%# herb:slots client %>
<%# herb:state (city: "Zurich") %>

<input value="<%= city %>">

<Fragment delay="100" hold="600">
  <p><%= Geo.locate(city) %></p>
  <Fallback><p>Looking it up</p></Fallback>
</Fragment>
```
:::

[Components](https://herb-tools.dev/language/components) covers every attribute and the compile errors, such as a second `<Fallback>` or an `<Async>` inside a loop.

## Next

[Stimulus and Turbo](/guides/stimulus-and-turbo) covers how reactive templates work alongside the rest of Hotwire.
