<div align="center">
  <img alt="ReActionView" style="height: 256px" height="256px" src="https://github.com/marcoroth/reactionview/blob/main/assets/reactionview.png?raw=true">
</div>

<h2 align="center">ReActionView</h2>

<h4 align="center">Reactive views for the HTML+ERB you already have.</h4>

<div align="center">You get what a client-side framework gives you, without adopting one.</div><br/>

<div align="center">No new syntax · No client framework · No API layer · No build step</div><br/>

<p align="center">
  <a href="https://rubygems.org/gems/reactionview"><img alt="Gem Version" src="https://img.shields.io/gem/v/reactionview"></a>
  <a href="https://reactionview.dev"><img alt="Documentation" src="https://img.shields.io/badge/documentation-available-green"></a>
  <a href="https://github.com/marcoroth/reactionview/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/github/license/marcoroth/reactionview"></a>
  <a href="https://github.com/marcoroth/reactionview/issues"><img alt="Issues" src="https://img.shields.io/github/issues/marcoroth/reactionview"></a>
</p>

<br/>

**ReActionView makes your existing HTML+ERB templates reactive.**

Rails 8.2 already renders HTML templates with `Herb::Engine`, which reads the HTML and the Ruby in a template together. ReActionView builds on that. A template declares state the browser owns, changes it with an HTML attribute, and has your controller answer when the server is needed. There is no second copy of the page to keep in sync.

It also brings Herb's error overlays, the dev tools and per-tag instrumentation to the page, so a mismatched tag or a `<div>` inside a `<p>` shows up in the browser with the file and the line while you work. On Rails 8.1 and earlier, it brings the engine itself.

### Documentation

[reactionview.dev](https://reactionview.dev/overview)

### Installation

```bash
bundle add reactionview
bin/rails generate reactionview:install
```

The generator creates `config/initializers/reactionview.rb` and imports the client from `app/javascript/application.js`. On importmap-rails the gem pins the client for you. With a bundler, install the `reactionview` npm package as well.

ReActionView needs Ruby 3.2 or newer and Rails 7.0 or newer. [Setup](https://reactionview.dev/installation) covers turning on reactive templates and checking that it works, and the [Quick Start](https://reactionview.dev/quick-start) builds a first reactive page.

### Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/reactionview. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/marcoroth/reactionview/blob/main/CODE_OF_CONDUCT.md).

### Code of Conduct

Everyone interacting in the ReActionView project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/marcoroth/reactionview/blob/main/CODE_OF_CONDUCT.md).

### License

This project is available as open source under the terms of the [MIT License](https://github.com/marcoroth/reactionview/blob/main/LICENSE.txt).
