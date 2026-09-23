# Quick Start <Badge type="tip" text="^0.6.0" />

This page builds one small page, a list of messages, in three steps. First it renders as a plain template. Then a button opens a composer with no JavaScript of your own. Finally a select re-sorts the list, and your controller answers.

It assumes you have finished [Setup](/installation), including `config.slots = true`.

## Step 1: A plain template

Start with a model, a controller and a view you could write in any Rails app.

:::code-group
```bash [Terminal]
bin/rails generate model Message author:string body:string
bin/rails db:migrate
```

```ruby [db/seeds.rb]
Message.create!(author: "Ada", body: "The build is green again.", created_at: 3.hours.ago)
Message.create!(author: "Grace", body: "Deploying after lunch.", created_at: 2.hours.ago)
Message.create!(author: "Linus", body: "Reviewed the migration, looks good.", created_at: 1.hour.ago)
```

```ruby [config/routes.rb]
Rails.application.routes.draw do
  resources :messages, only: [:index, :create]
end
```

```ruby [app/controllers/messages_controller.rb]
class MessagesController < ApplicationController
  def index
    @messages = Message.order(:created_at)
  end

  def create
    Message.create!(params.require(:message).permit(:body).merge(author: "You"))

    redirect_to messages_path
  end
end
```

```erb [app/views/messages/index.html.erb]
<h1>Messages</h1>

<ul>
  <% @messages.each do |message| %>
    <%# herb:key message.id %>
    <li><strong><%= message.author %></strong> <%= message.body %></li>
  <% end %>
</ul>
```
:::

Run `bin/rails db:seed` and open `/messages`. The page renders the three messages, the same as it would without ReActionView.

The `<%# herb:key message.id %>` comment is the one new thing. It tells the client which row is which, so it can reorder rows later without rebuilding them. [Keys and collections](https://herb-tools.dev/language/keys) covers the other ways to key a row.

## Step 2: A composer that opens in place

Add a button that opens a form for a new message. The form is shown when a state called `composing` is true, and the button toggles it.

:::code-group
```erb [app/views/messages/index.html.erb]
<%# herb:slots client %>
<%# herb:state (composing: false) %>

<h1>Messages</h1>

<ul>
  <% @messages.each do |message| %>
    <%# herb:key message.id %>
    <li><strong><%= message.author %></strong> <%= message.body %></li>
  <% end %>
</ul>

<button data-herb-toggle="composing">New message</button>

<% if composing %>
  <form action="<%= messages_path %>" method="post">
    <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">
    <input name="message[body]" autocomplete="off">
    <button>Send</button>
  </form>
<% end %>
```
:::

`<%# herb:state (composing: false) %>` declares a Boolean state that starts out false, so the first render leaves the form out. [`data-herb-toggle`](https://herb-tools.dev/language/actions#attributes) flips it when the button is clicked, and the `if` reads it like any other Ruby value.

Click **New message** and the form appears without a page load. The client asked your app for the form's markup and put it in place. Nothing else on the page was touched, so the list keeps its scroll position and anything you had selected.

`<%# herb:slots client %>` compiles the template with [slots](https://herb-tools.dev/language/slots), which is what lets the client find the `if` again after the page has rendered. With `config.slots = true` every template gets them, and the directive makes it explicit in this one.

## Step 3: Let the server answer

Now add a select that sorts the list. Sorting happens in the database, so this time the server has to answer.

Declare a second state, `order`, and set it from the select. The template reads `order` to say which way the list is sorted.

:::code-group
```erb [app/views/messages/index.html.erb]
<%# herb:slots client %>
<%# herb:state (composing: false, order: "oldest") %>

<h1>Messages</h1>

<select data-herb-set="order=$value">
  <option value="oldest">Oldest first</option>
  <option value="newest">Newest first</option>
</select>

<p><% if order == "newest" %>Newest messages first<% else %>Oldest messages first<% end %></p>

<ul>
  <% @messages.each do |message| %>
    <%# herb:key message.id %>
    <li><strong><%= message.author %></strong> <%= message.body %></li>
  <% end %>
</ul>

<button data-herb-toggle="composing">New message</button>

<% if composing %>
  <form action="<%= messages_path %>" method="post">
    <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">
    <input name="message[body]" autocomplete="off">
    <button>Send</button>
  </form>
<% end %>
```
:::

The controller reads the same state with `herb_state`, which returns the value the browser holds, or the default you give it when there is none.

:::code-group
```ruby [app/controllers/messages_controller.rb]
class MessagesController < ApplicationController
  def index
    direction = herb_state("order", "oldest") == "newest" ? :desc : :asc

    @messages = Message.order(created_at: direction)
  end

  def create
    Message.create!(params.require(:message).permit(:body).merge(author: "You"))

    redirect_to messages_path
  end
end
```
:::

Choose **Newest first**. The select writes `"newest"` into `order`, and the client sends one request to the same URL.

```http
GET /messages?format=slots
Accept: application/vnd.herb.slots+json
Herb-State: {"app/views/messages/index.html.erb":{"order":"newest","composing":false}}
```

Your `index` action runs as usual, and `herb_state("order", "oldest")` returns `"newest"`. ReActionView renders the template in the `slots` format, which answers with the page's changed values instead of HTML. The client moves Linus to the top and Ada to the bottom, and updates the sentence above the list. The rows are moved, not rebuilt, because each one has a key.

::: tip The template has to read the state
The client asks the server when a state the template reads changes. A state that only your controller reads never makes the client ask, because nothing on the page depends on it. Here the sentence above the list reads `order`, which is also what tells the reader how the list is sorted.
:::

## What you built

The page is still one template, one controller action and one route. The composer opens without a page load, and the list re-sorts through the same `index` action you already had. You wrote no JavaScript, added no endpoint and made no second copy of the markup.

## Next

[State and Actions](/guides/state) covers what a state can hold and every action attribute. [Collections and Forms](/guides/collections) makes the composer add its message to the list before the server has answered.
