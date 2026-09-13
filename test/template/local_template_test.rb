# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"
require "action_controller"

class ReActionView::LocalTemplateTest < Minitest::Spec
  SidecarTemplate = Struct.new(:identifier, :format, keyword_init: true)

  class Classifier
    include ReActionView::Template::LocalTemplate

    def local?(template)
      local_template?(template)
    end
  end

  before do
    @root = Dir.mktmpdir("rv_local_template")
    @classifier = Classifier.new
  end

  after do
    FileUtils.rm_rf(@root)
    ReActionView::Template::Dependencies.reset!
  end

  def touch(relative)
    path = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "")
    path
  end

  def engine_at(relative, name)
    root = File.join(@root, relative)
    FileUtils.mkdir_p(File.join(root, "lib"))
    FileUtils.mkdir_p(File.join(root, "app", "views"))

    engine = Class.new(Rails::Engine)
    Object.const_set(name, engine)
    engine.config.root = root

    root
  end

  def classify(identifier, template: nil)
    ReActionView::Template::Dependencies.reset!

    template ||= SidecarTemplate.new(identifier: identifier, format: :html)

    Rails.stub(:root, Pathname.new(@root)) do
      @classifier.local?(template)
    end
  end

  def with_loaded_gem(name, full_gem_path)
    spec = Gem::Specification.new do |candidate|
      candidate.name = name
      candidate.version = "1.0"
    end

    spec.instance_variable_set(:@full_gem_path, full_gem_path)
    Gem.loaded_specs[name] = spec

    yield
  ensure
    Gem.loaded_specs.delete(name)
  end

  def teardown_engine(name)
    Object.send(:remove_const, name) if Object.const_defined?(name)
  end

  test "a template in the application's own app/views is local" do
    assert classify(touch("app/views/users/show.html.erb"))
  end

  test "an engine vendored inside the application is external" do
    engine_root = engine_at("vendor/primer-view_components", :RVTestVendoredEngine)

    identifier = File.join(engine_root, "app", "views", "primer", "beta", "button.html.erb")
    FileUtils.mkdir_p(File.dirname(identifier))
    File.write(identifier, "")

    refute classify(identifier), "a vendored engine's template should not be treated as application code"
  ensure
    teardown_engine(:RVTestVendoredEngine)
  end

  test "a ViewComponent sidecar from an engine vendored inside the application is external" do
    engine_root = engine_at("vendor/primer-view_components", :RVTestSidecarEngine)

    identifier = File.join(engine_root, "app", "components", "primer", "beta", "button.html.erb")
    FileUtils.mkdir_p(File.dirname(identifier))
    File.write(identifier, "")

    refute classify(identifier), "a vendored engine's sidecar should not be treated as application code"
  ensure
    teardown_engine(:RVTestSidecarEngine)
  end

  test "the application's own ViewComponent sidecar is local" do
    assert classify(touch("app/components/button_component.html.erb"))
  end

  test "a template from an engine installed outside the application is external" do
    engine_root = engine_at("installed/devise-4.9.4", :RVTestInstalledEngine)

    identifier = File.join(engine_root, "app", "views", "devise", "sessions", "new.html.erb")
    FileUtils.mkdir_p(File.dirname(identifier))
    File.write(identifier, "")

    refute classify(identifier)
  ensure
    teardown_engine(:RVTestInstalledEngine)
  end

  test "a view path a plain railtie registered is external" do
    gem_root = File.join(@root, "vendor", "cache", "some_gem-1.0")
    gem_views = File.join(gem_root, "app", "views")
    FileUtils.mkdir_p(gem_views)

    with_loaded_gem("rv_test_railtie_gem", gem_root) do
      Object.const_set(:RVTestPlainRailtie, Class.new(Rails::Railtie))
      ActionController::Base.prepend_view_path(gem_views)

      identifier = File.join(gem_views, "thing.html.erb")
      File.write(identifier, "")

      refute classify(identifier), "a railtie has no engine root, so the gem it ships in has to place it"
    end
  ensure
    teardown_engine(:RVTestPlainRailtie)
  end

  test "a gem path that contains the application does not make application templates external" do
    with_loaded_gem("rv_test_app_as_gem", @root) do
      assert classify(touch("app/views/users/show.html.erb"))
    end
  end

  test "a template is local when there is no application root to compare against" do
    ReActionView::Template::Dependencies.reset!

    template = SidecarTemplate.new(identifier: "test_template", format: :html)

    Rails.stub(:root, nil) do
      assert @classifier.local?(template)
    end
  end

  test "a template with no identifier is local" do
    assert classify(nil)
  end

  test "a template outside the application and outside every dependency is external" do
    refute classify("/somewhere/else/thing.html.erb")
  end

  test "an engine that raises when asked for its root does not break classification" do
    broken = Class.new(Rails::Engine)
    Object.const_set(:RVTestBrokenEngine, broken)
    broken.define_singleton_method(:instance) { raise "boom" }

    assert classify(touch("app/views/users/show.html.erb"))
  ensure
    teardown_engine(:RVTestBrokenEngine)
  end
end
