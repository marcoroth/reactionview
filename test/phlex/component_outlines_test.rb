# frozen_string_literal: true

require_relative "../test_helper"

require "phlex"

class ReActionView::Phlex::ComponentOutlinesTest < Minitest::Spec
  PROJECT_PATH = File.expand_path("../..", __dir__)

  class Base < ::Phlex::HTML
    include ReActionView::Phlex::ComponentOutlines
  end

  class Card < Base
    def view_template
      div(class: "card") { "Hello" }
    end
  end

  class Text < Base
    def view_template
      plain "Just text"
    end
  end

  class Page < Base
    def view_template
      main do
        render Card.new
      end
    end
  end

  class CardWrapper < Base
    def view_template
      render Card.new
    end
  end

  before do
    @previous_debug_mode = ReActionView.config.debug_mode

    ReActionView.config.project_path = PROJECT_PATH
  end

  after do
    ReActionView.config.debug_mode = @previous_debug_mode
    ReActionView.config.project_path = nil
  end

  test "marks the root tag with the Herb debug attributes when debug mode is on" do
    ReActionView.config.debug_mode = true

    expected = [
      %(<div data-herb-debug-outline-type="component"),
      %(data-herb-debug-file-name="ReActionView::Phlex::ComponentOutlinesTest::Card"),
      %(data-herb-debug-file-relative-path="test/phlex/component_outlines_test.rb"),
      %(data-herb-debug-file-full-path="#{__FILE__}"),
      %(class="card">Hello</div>)
    ].join(" ")

    assert_equal expected, Card.new.call
  end

  test "leaves the HTML unchanged when debug mode is off" do
    ReActionView.config.debug_mode = false

    assert_equal %(<div class="card">Hello</div>), Card.new.call
  end

  test "leaves a component without a root tag unchanged" do
    ReActionView.config.debug_mode = true

    assert_equal "Just text", Text.new.call
  end

  test "marks nested components on their own root tags" do
    ReActionView.config.debug_mode = true

    html = Page.new.call

    assert_match(/<main data-herb-debug-outline-type="component" data-herb-debug-file-name="ReActionView::Phlex::ComponentOutlinesTest::Page"/, html)
    assert_match(/<div data-herb-debug-outline-type="component" data-herb-debug-file-name="ReActionView::Phlex::ComponentOutlinesTest::Card"/, html)
  end

  test "keeps the inner component outline when both share the root tag" do
    ReActionView.config.debug_mode = true

    html = CardWrapper.new.call

    assert_equal 1, html.scan("data-herb-debug-outline-type").size
    assert_match(/data-herb-debug-file-name="ReActionView::Phlex::ComponentOutlinesTest::Card"/, html)
  end
end
