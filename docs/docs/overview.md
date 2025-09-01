# Overview

ReActionView is a new ActionView-compatible ERB engine with modern developer experience - re-imagined with `Herb::Engine`. It provides seamless integration of Herb's HTML-aware ERB rendering engine into Rails applications, compatible with `.html.erb` templates but with modern enhancements like HTML validation, better error feedback, developer-friendly debug mode, and more!

## The Herb Journey

ReActionView is the practical payoff of a year-long development effort:

- **RubyKaigi 2025**: Introduced [Herb](https://github.com/marcoroth/herb), a new HTML-aware ERB parser built on Prism
- **RailsConf 2025**: Released developer tools including formatter, linter, and language server
- **Rails World 2025**: Debuting ReActionView - bringing it all together as a new ERB engine

## What is ReActionView?

ReActionView is a new ActionView-compatible ERB engine that enhances Rails template rendering:

- **HTML-aware parsing** through Herb's advanced ERB parser
- **Enhanced error handling** with validation overlays in development
- **Debug mode** for better development experience
- **Security improvements** with context-aware validation

## Key Features

### **Full ActionView Compatibility**
- Seamless replacement for Rails' ERB handler
- Zero-breaking-change migration for existing `.html.erb` templates
- Preserves Rails conventions, helpers, and asset pipeline integration
- Maintains performance characteristics of standard ERB

### **Reactive Server-Rendered Components** *(Coming Soon)*
- Bridge the gap between traditional views and modern frontend frameworks
- Enable dynamic UI updates without JavaScript complexity
- Server-driven reactivity that works with Hotwire and Turbo
- Component state management built into the rendering engine

### **HTML Validation & Security**
- Context-aware validation through Herb's security validators
- Template error overlays displayed directly in the browser (in overlay mode)
- Integration with Herb's validation system for better template safety

### **Enhanced Development Experience**
- Visual debugging with element metadata injection in debug mode
- Better error feedback through validation overlays
- Integration with Herb's ecosystem of developer tools

## How It Works

1. **Template Registration**: ReActionView registers itself as a template handler for `.html.herb` files and optionally for `.html.erb` files
2. **Herb Processing**: Templates are processed through the Herb engine instead of standard ERB
3. **Enhanced Output**: The result includes validation, security checks, and debug information
4. **Rails Integration**: Output integrates seamlessly with Rails' `@output_buffer` and HTML safety mechanisms

## Rails World 2025 Debut

ReActionView makes its first public appearance at Rails World 2025, representing the culmination of the Herb ecosystem development. This exclusive release demonstrates:

- Enhanced template processing with `Herb::Engine` integration
- Migration paths for existing Rails applications
- Improved developer experience and debugging capabilities
- Vision for the future of Rails' view layer

## Collaboration & Rails Integration

ReActionView is designed as a collaboration opportunity for the Rails community:

- **Exploration Initiative**: Experimenting with what's possible in the Rails view layer
- **Community Feedback**: Gathering insights on architecture and developer experience
- **Rails Core Integration**: Positioning as a potential evolution of Rails' default view layer
- **Open Development**: Transparent development process with community input

## Getting Started

Ready to be part of the future of Rails templates? Check out the [installation guide](/installation) to get started with ReActionView in your Rails application.
