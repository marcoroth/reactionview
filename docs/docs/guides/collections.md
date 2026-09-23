# Collections and Forms <Badge type="tip" text="^0.6.0" /> <Badge type="warning" text="experimental" />

**A list that changes should change one row at a time.** When a row is added, removed or moved, the rows around it should stay exactly as they were, with their focus, their scroll position and anything typed into them.

## Keys

A loop in a template becomes a collection. Give each row a key so the client can tell the rows apart.

:::code-group
```erb [app/views/messages/index.html.erb]
<%# herb:slots client %>

<ul data-herb-name="messages">
  <% @messages.each do |message| %>
    <%# herb:key message.id %>
    <li>
      <strong data-herb-name="author"><%= message.author %></strong>
      <span data-herb-name="body"><%= message.body %></span>
    </li>
  <% end %>
</ul>
```
:::

With keys, a reordered list is a set of moves. Without them, the client cannot tell which row went where, so it rebuilds every row after the first change, and the engine warns about it when the template compiles. A dynamic `id` or a `herb-key` attribute on the row element works as a key too. [Keys and collections](https://herb-tools.dev/language/keys) has the details.

`data-herb-name` names the collection and the parts of a row, so a form can address them. That is the next step.

## A form that adds a row immediately

A form with `data-herb-into` adds its row to the named collection the moment it is submitted, before the server has answered.

:::code-group
```erb [app/views/messages/index.html.erb]
<form action="/messages" method="post" data-herb-into="messages">
  <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">
  <input name="message[body]" autocomplete="off">
  <button>Send</button>
</form>
```
:::

The client builds the new row from the markup of an existing one and fills each named part from the form field with the same name. A Rails field name is read by its last bracketed part, so `message[body]` fills `body`. The row carries a temporary key until the server answers, and sends go out one at a time, in order, so nothing the user typed is lost.

The form still posts to your `create` action. Answer the `slots` format with the new row rendered through the same template.

:::code-group
```ruby [app/controllers/messages_controller.rb]
class MessagesController < ApplicationController
  def index
    @messages = Message.order(:created_at)
  end

  def create
    message = Message.create!(params.require(:message).permit(:body).merge(author: "You"))

    respond_to do |format|
      format.slots do
        @messages = Message.where(id: message.id)
        render :index, status: :created
      end
      format.html { redirect_to messages_path }
    end
  end
end
```
:::

The answer carries one row, with its real key and the values the server rendered, such as `author`. The client gives the temporary row its real key in place, so the element on screen is the same one the user just saw appear. The `format.html` branch keeps the form working as an ordinary form when JavaScript is not running.

## When the send fails

If the request fails, the row stays on the page and is marked as failed instead of disappearing. Your JavaScript can retry it or discard it, and [Sending](https://herb-tools.dev/projects/client#sending) in the client reference covers `outbox.retry` and `outbox.discard`.

## Counting rows

A total that depends on the rows, such as how many tasks are done, can be kept current by the client too. [Counting folds](https://herb-tools.dev/language/state#counting-folds) shows the pattern.

## Next

[Server and Client Rendering](/guides/rendering-modes) explains who builds the parts of the page that were not on it when it loaded.
