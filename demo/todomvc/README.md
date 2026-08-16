# TodoMVC, on Rails

TodoMVC as a Rails application, in one file, updated by `@herb-tools/runtime`. Every interaction
asks the server what this page renders now and writes back the values that differ, so the page is
never replaced.

```bash
cd /Users/marcoroth/Development/herb-worktree/javascript/packages/runtime && yarn build
bundle exec rackup demo/todomvc/config.ru
```

## What ReActionView is doing

Nothing in `config.ru` sets any of this up, which is the point. Turning `config.slots = :client` on
is the whole configuration, and from there:

- **the `:slots` format exists**, because `LookupContext#formats=` refuses one that is not a
  registered Mime type
- **a resolver answers for it**, handing back the same `.html.erb` rather than a second file, so one
  template keeps one numbering
- **the handler compiles values** instead of markup when a request asks for that format, over the
  same visitor stack the markup compile uses, so an index means the same thing to both
- **the layout is skipped**, since a layout is chrome, is where `content_for` lives, and rendering
  it would mean rendering every partial in it

The page is 3.8 kB and its values are about 500 bytes.

## The same demo without Rails

`demo/todomvc` in the Herb repo is this application again as a bare Rack app, wiring those four
things by hand. Comparing them is the clearest way to see what this gem is for.

## What the template avoids, and why

Three shapes a slot template should not use, each for its own reason, and all three are worth
knowing before writing your own:

- **a conditional inside a tag**, like `class="<%= done ? "completed" : "" %>"`, compiles to a
  conditional whose branches differ only by an attribute value, so there is no markup to park and
  the client cannot build the branch it was not sent
- **a conditional wrapping a collection** is captured with its rows still inside it, so rebuilding
  it brings back rows that have been deleted
- **a word interpolated into an attribute**, like `class="main <%= hidden %>"`, marks part of an
  attribute, and a marker says which attribute rather than which stretch of it, so the runtime
  refuses to write it rather than dropping what the template wrote around it

A fourth is a limit rather than a choice: `checked` is presence, not value, and no slot can say
"absent". The server sends the state as an ordinary attribute and the client sets the checkbox.

## The same demo on Rails

`demo/todomvc` in the ReActionView repo is this application again, as a Rails app. The template is
the same and the client is the same; what changes is that the four things wired by hand here are
the gem's. Comparing them is the clearest way to see what that gem is for.

## What it is not

No database, so the todos live in memory and reset with the server. No authentication, no CSRF, and
mutations happen on GET, none of which a real application should copy.
