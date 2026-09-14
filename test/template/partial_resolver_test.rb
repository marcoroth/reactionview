# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"
require "action_controller"

class ReActionView::PartialResolverTest < Minitest::Spec
  before do
    skip "needs a Herb that resolves partials through a resolver" unless defined?(::Herb::Analysis::PartialResolver)

    @root = Dir.mktmpdir("rv_partial_resolver")
    @app_views = File.join(@root, "app", "views")
    @engine_views = File.join(@root, "vendor", "primer", "app", "views")

    write(@app_views, "shared/_album_card.html.erb")
    write(@app_views, "overlays/show.html.erb")
    write(@engine_views, "primer/_button.html.erb")
    write(@engine_views, "shared/_album_card.html.erb")
  end

  after do
    FileUtils.rm_rf(@root)
    ReActionView::Template::Dependencies.reset!
    ReActionView::Template::PartialResolver.reset!
  end

  def write(root, relative)
    path = File.join(root, relative)

    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "<p>#{relative}</p>")

    path
  end

  def resolver(*view_paths)
    ReActionView::Template::PartialResolver.new(project_path: @root, view_paths: view_paths.map { |path| "#{path}/" })
  end

  def registered(*view_paths)
    ReActionView::Template::Dependencies.reset!
    ReActionView::Template::PartialResolver.reset!

    original = ActionController::Base.view_paths
    ActionController::Base.view_paths = view_paths

    yield ReActionView::Template::PartialResolver.new(project_path: @root)
  ensure
    ActionController::Base.view_paths = original
    ReActionView::Template::Dependencies.reset!
    ReActionView::Template::PartialResolver.reset!
  end

  test "a partial under the application's own view path resolves" do
    resolved = resolver(@app_views, @engine_views).resolve("shared/album_card")

    assert_equal File.join(@app_views, "shared", "_album_card.html.erb"), resolved.path.to_s
    assert_equal "app/views/shared/_album_card.html.erb", resolved.identifier
  end

  test "a partial that lives only in an engine's view path resolves" do
    resolved = resolver(@app_views, @engine_views).resolve("primer/button")

    assert_equal File.join(@engine_views, "primer", "_button.html.erb"), resolved.path.to_s
    assert_equal "vendor/primer/app/views/primer/_button.html.erb", resolved.identifier
  end

  test "the herb default alone cannot see the engine's partial" do
    default = ::Herb::Analysis::PartialResolver.new(@root)

    assert_nil default.resolve("primer/button")
    refute_nil resolver(@app_views, @engine_views).resolve("primer/button")
  end

  test "the first registered path wins when both define the name" do
    assert_equal File.join(@app_views, "shared", "_album_card.html.erb"),
                 resolver(@app_views, @engine_views).resolve("shared/album_card").path.to_s
    assert_equal File.join(@engine_views, "shared", "_album_card.html.erb"),
                 resolver(@engine_views, @app_views).resolve("shared/album_card").path.to_s
  end

  test "a partial named without a directory resolves beside the calling template" do
    write(@app_views, "overlays/_row.html.erb")

    resolved = resolver(@app_views, @engine_views).resolve("row", from: "app/views/overlays/show.html.erb")

    assert_equal "app/views/overlays/_row.html.erb", resolved.identifier
  end

  test "a missing partial answers nil and lists every root it looked under" do
    subject = resolver(@app_views, @engine_views)
    looked = subject.candidates("shared/missing").map(&:to_s)

    assert_nil subject.resolve("shared/missing")
    assert_includes looked, File.join(@app_views, "shared", "_missing.html.erb")
    assert_includes looked, File.join(@engine_views, "shared", "_missing.html.erb")
  end

  test "a near miss is suggested from whichever root holds it" do
    assert_equal ["primer/button"], resolver(@app_views, @engine_views).similar("primer/buton")
  end

  test "the identifier of a file outside the project keeps the shape its own compile reports" do
    Dir.mktmpdir("rv_outside") do |outside|
      path = Pathname.new(File.join(outside, "_widget.html.erb"))

      assert_equal ::Herb::Analysis::PartialResolver.new(@root).identifier_for(path),
                   resolver(@app_views).identifier_for(path)
    end
  end

  test "it reads the view paths the application registered" do
    registered(@app_views, @engine_views) do |subject|
      assert_equal "vendor/primer/app/views/primer/_button.html.erb", subject.resolve("primer/button").identifier
    end
  end

  test "it falls back to the project's own view root when nothing is registered" do
    registered do |subject|
      assert_equal "app/views/shared/_album_card.html.erb", subject.resolve("shared/album_card").identifier
      assert_nil subject.resolve("primer/button")
    end
  end

  test "the handler hands the resolver to the engine it builds" do
    options = ReActionView::Template::Handlers::Herb.new.send(:engine_options)

    assert_instance_of ReActionView::Template::PartialResolver, options[:resolver]
    assert(%i[resolve candidates similar identifier_for].all? { |message| options[:resolver].respond_to?(message) })
  end

  test "it picks up view paths registered after a reset" do
    subject = ReActionView::Template::PartialResolver.new(project_path: @root)
    original = ActionController::Base.view_paths

    begin
      ActionController::Base.view_paths = [@app_views]
      ReActionView::Template::Dependencies.reset!

      assert_nil subject.resolve("primer/button")

      ActionController::Base.view_paths = [@app_views, @engine_views]
      ReActionView::Template::Dependencies.reset!

      refute_nil subject.resolve("primer/button")
    ensure
      ActionController::Base.view_paths = original
      ReActionView::Template::Dependencies.reset!
    end
  end
end
