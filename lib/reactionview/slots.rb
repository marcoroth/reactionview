# frozen_string_literal: true

module ReActionView
  # Serving what a template's dynamic parts evaluated to, for a client that already has its markup.
  #
  # The browser holds an index of the slot markers a page was rendered with, so a state change costs
  # the values that changed rather than the page. This is the half that answers with them.
  module Slots
    FORMAT = :slots #: Symbol
    MIME_TYPE = "application/vnd.herb.slots+json" #: String
  end
end
