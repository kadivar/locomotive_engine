
module Mongoid
  module Document

    class << self
      alias :_old_method__included :included
      def included(base)
        trackers.each do |block|
          block.call(base)
        end
        _old_method__included(base)
      end

      def add_tracker(&block)
        trackers << block
      end

      protected

      def trackers
        @trackers ||= []
      end
    end

  end
end
