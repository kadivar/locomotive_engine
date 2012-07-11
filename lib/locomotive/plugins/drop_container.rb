
module Locomotive
  module Plugins
    class DropContainer < ::Liquid::Drop

      def initialize(drops_hash)
        @drops_hash = drops_hash
      end

      def before_method(meth)
        @drops_hash[meth.to_s]
      end

    end
  end
end
