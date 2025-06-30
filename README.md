# ReActionView

Reactive ActionView.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add reactionview
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install reactionview
```

## Usage

ReactionView is a Rails engine that provides an alternative template processing system. It automatically handles `.html.herb` files and can optionally override `.html.erb` files.

### Automatic Processing

Files with the `.html.herb` extension are automatically processed by ReactionView:

```erb
<!-- app/views/users/show.html.herb -->
<h1><%= @user.name %></h1>
<p><%= @user.email %></p>
```

### Configuration

```ruby
require "reactionview"

# ReactionView automatically handles .html.herb files
# No registration needed for .html.herb files - they use ReactionView by default

# Optionally register ReactionView for .html.erb files (overrides default ActionView)
# ReActionView.register_content_type('html.erb', ReActionView::TemplateEngine)

# Configure template exclusion filter and validation options
ReActionView.configure do |config|
  config.template_exclusion_filter = ->(template_path) {
    # Exclude certain templates from ReactionView processing
    template_path.include?('admin') || template_path.include?('legacy')
  }
  
  # Enable/disable Herb validation (default: true)
  config.enable_herb_validation = true
  
  # Enable/disable HTML5 validation with Nokogiri (default: true)
  config.enable_html5_validation = true
  
  # Enable verbose error logging for debugging (default: false)
  config.verbose_error_logging = true
end
```

### File Extensions

- **`.html.erb`** - Uses standard ActionView (can be overridden to use ReactionView)
- **`.html.herb`** - Automatically processed by ReactionView

This allows you to gradually migrate templates or use ReactionView selectively in your application.

## Features

### Template Validation

ReactionView includes comprehensive template validation using both Herb and Nokogiri:

#### Pre-render Validation
- **Herb Integration**: Validates raw template files using `Herb.parse_file()` before rendering
- **Syntax Checking**: Catches ERB syntax errors and HTML structure issues early

#### Post-render Validation  
- **Herb Validation**: Validates the final rendered output using `Herb.parse()`
- **HTML5 Compliance**: Uses Nokogiri's HTML5 parser to validate HTML5 compliance
- **Smart Detection**: Only validates content that appears to be HTML

#### Error Reporting
- **Detailed Logging**: Shows precise line and column numbers for all validation errors
- **Separate Error Types**: Distinguishes between Herb (ERB/HTML syntax) and HTML5 validation errors
- **Configurable Verbosity**: Optional verbose error logging with full stack traces

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enable_herb_validation` | `true` | Enable/disable Herb validation for ERB and HTML syntax |
| `enable_html5_validation` | `true` | Enable/disable HTML5 compliance validation with Nokogiri |
| `verbose_error_logging` | `false` | Include full stack traces in error logs |
| `template_exclusion_filter` | `nil` | Lambda to exclude specific templates from ReactionView processing |

### Validation Flow

1. **Pre-render**: Herb validates the raw `.html.herb` template file
2. **Rendering**: Template is processed by ReactionView's template engine  
3. **Post-render**: Both Herb and Nokogiri validate the final HTML output
4. **Error Logging**: Any validation errors are logged with precise location information

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/reactionview. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/marcoroth/reactionview/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the ReActionView project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/marcoroth/reactionview/blob/main/CODE_OF_CONDUCT.md).
