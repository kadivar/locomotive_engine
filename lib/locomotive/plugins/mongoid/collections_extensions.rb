
module Mongoid
  module Collections

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

      alias :_old_method__collection :collection
      def collection
        if use_collection_name_prefix? && prefix_changed?
          self._collection = nil
          update_prefix
        end
        _old_method__collection
      end

      protected

      def prefix_changed?
        Mongoid::Collections.collection_name_prefix != @_old_prefix
      end

      def update_prefix
        @_original_collection_name ||= self.collection_name

        prefix = Mongoid::Collections.collection_name_prefix
        self.collection_name = "#{prefix}#{@_original_collection_name}"

        @_old_prefix = prefix
      end

    end

  end
end
