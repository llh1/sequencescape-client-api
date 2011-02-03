require 'sequencescape-api/resource'

module Sequencescape
  class LibraryTube < ::Sequencescape::Api::Resource
    has_many   :requests,       :class_name => 'Sequencescape::Request'
    belongs_to :sample,         :class_name => 'Sequencescape::Sample'
    belongs_to :source_request, :class_name => 'Sequencescape::Request'
  end
end
