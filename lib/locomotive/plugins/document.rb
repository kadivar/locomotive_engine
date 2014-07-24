module Locomotive
  module Plugins
    module Document
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.use_collection_name_prefix=true
      end
    end
  end
end
