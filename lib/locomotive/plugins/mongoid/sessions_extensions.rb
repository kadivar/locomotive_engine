
module Mongoid
  module Sessions

    class << self
      attr_accessor :collection_name_prefix

      def with_collection_name_prefix(prefix)
        old_prefix = self.collection_name_prefix
        self.collection_name_prefix = prefix
        yield
      ensure
        self.collection_name_prefix = old_prefix
      end
    end

    module ClassMethods

      def use_collection_name_prefix=(use_prefix)
        @use_collection_name_prefix = use_prefix
      end

      def use_collection_name_prefix?
        !!@use_collection_name_prefix
      end

      def collection_name
        if use_collection_name_prefix?
          prefix = Mongoid::Sessions.collection_name_prefix
          "#{prefix}#{__collection_name__}"
        else
          __collection_name__
        end
      end
    end
  end
end
