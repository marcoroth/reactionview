<div align="center">
  <img alt="ReActionView - Enhanced Rails templates" style="height: 256px" height="256px" src="assets/reactionview.png">
</div>

<h2 align="center">ReActionView</h2>

<h4 align="center">Enhanced Rails templates powered by <code>Herb::Engine</code></h4>

<div align="center">Seamless integration of Herb's HTML-aware ERB Rendering Engine into Rails applications.</div><br/>

<p align="center">
  <a href="https://rubygems.org/gems/reactionview"><img alt="Gem Version" src="https://img.shields.io/gem/v/reactionview"></a>
  <a href="https://reactionview.dev"><img alt="Documentation" src="https://img.shields.io/badge/documentation-available-green"></a>
  <a href="https://github.com/marcoroth/reactionview/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/github/license/marcoroth/reactionview"></a>
  <a href="https://github.com/marcoroth/reactionview/issues"><img alt="Issues" src="https://img.shields.io/github/issues/marcoroth/reactionview"></a>
</p>

<br/><br/><br/>

## Installation

Add to your Rails application:

```bash
bundle add reactionview
rails generate reactionview:install
```

## Usage

ReActionView provides two ways to use enhanced template processing:

1. **Native `.html.herb` templates** - Automatically processed with `Herb::Engine`.
2. **Intercept `.html.erb` templates** - Enable in config to process all HTML+ERB templates with Herb.

### Configuration

```ruby
# config/initializers/reactionview.rb

ReActionView.configure do |config|
  # Intercept .html.erb templates to use Herb::Engine
  # config.intercept_erb = true

  # Enable debug mode
  config.debug_mode = Rails.env.development?
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/reactionview. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/marcoroth/reactionview/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the ReActionView project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/marcoroth/reactionview/blob/main/CODE_OF_CONDUCT.md).

## License 

This project is available as open source under the terms of the [MIT License](https://github.com/marcoroth/reactionview/blob/main/LICENSE.txt).
