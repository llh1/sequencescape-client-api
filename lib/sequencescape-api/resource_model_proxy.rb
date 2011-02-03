require 'active_support'
require 'active_support/basic_object'
require 'sequencescape-api/finder_methods'
require 'ostruct'

module Sequencescape
  class Api
    # Any interaction with the API isn't done directly through a model but through an instance of this
    # class, that proxies the model and ensures that it uses the correct instance of Sequencescape::Api.
    class ResourceModelProxy
      self.instance_methods.each { |m| undef_method(m) unless m.to_s =~ /^(__.+__|respond_to\?)$/ }

      include ::Sequencescape::Api::FinderMethods

      def initialize(api, model, actions)
        @api, @model, @actions = api, model, OpenStruct.new(actions)
      end

      attr_reader :api, :actions, :model
      private :api, :actions, :model

      def create!(attributes = nil)
        attributes ||= {}
        api.create(actions.create, { model.json_root => attributes }) do |json|
          new(json, true)
        end
      end

      def respond_to?(name, include_private = false)
        super || model.respond_to?(name, include_private)
      end

      def method_missing(name, *args, &block)
        model.send(name, api, *args, &block)
      end
      protected :method_missing

      # Here are some methods that need to be delegated directly.
      delegate :ai, :to => :model
    end
  end
end
