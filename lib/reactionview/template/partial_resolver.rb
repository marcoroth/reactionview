# frozen_string_literal: true

module ReActionView
  class Template
    # Answers a render's partial name with the file Rails would render, across every view path the
    # application has registered.
    #
    # Herb resolves partials while it compiles, to check that a render names a template that
    # exists, to inline one, and to read the states a caller binds through `state:`. On its own it
    # looks under a single view root, which is a fair description of an application and wrong for
    # everything around it. Rails has the application's own paths, its engines' and its gems' all
    # registered, in an order the application controls, and `shared/album_card` may live in any of
    # them.
    #
    # This asks Herb's own resolver once per registered path, in the order Rails registered them,
    # so the file is the one Rails would have found and the identifier is the one that file's own
    # compile reports for itself. That last part is what a state binding keys on, so the two sides
    # of a binding agree by construction.
    #
    class PartialResolver
      #: () -> PartialResolver
      def self.current
        @current ||= new
      end

      #: () -> void
      def self.reset!
        @current = nil
      end

      #: (?project_path: untyped, ?view_paths: Array[String]?) -> void
      def initialize(project_path: nil, view_paths: nil)
        @project_path = project_path
        @view_paths = view_paths
      end

      #: (String, ?from: untyped, ?format: String?) -> untyped
      def resolve(name, from: nil, format: nil)
        resolvers.each do |resolver|
          found = resolver.resolve(name, from: from, format: format)

          return found if found
        end

        nil
      end

      #: (String, ?from: untyped) -> Array[untyped]
      def candidates(name, from: nil)
        resolvers.flat_map { |resolver| resolver.candidates(name, from: from) }.uniq
      end

      #: (String, ?from: untyped, ?limit: Integer) -> Array[String]
      def similar(name, from: nil, limit: 3)
        resolvers.flat_map { |resolver| resolver.similar(name, from: from, limit: limit) }.uniq.first(limit)
      end

      #: (untyped) -> String
      def identifier_for(path)
        resolvers.first.identifier_for(path)
      end

      private

      #: () -> Array[untyped]
      def resolvers
        dependencies = @view_paths ? nil : Dependencies.current

        unless dependencies.equal?(@dependencies)
          @dependencies = dependencies
          @resolvers = nil
        end

        @resolvers ||= roots(dependencies).map { |root| ::Herb::Analysis::PartialResolver.new(project_path, view_root: root) }
      end

      #: (untyped) -> Array[String?]
      def roots(dependencies)
        paths = @view_paths || dependencies.view_paths

        paths.empty? ? [nil] : paths
      end

      #: () -> untyped
      def project_path
        @project_path ||= ::ReActionView.config.project_path
      end
    end
  end
end
