module Locomotive
  module Plugins
    module Helper
      def use_site(site)
        Thread.current[:site] = site
        ::Mongoid::Sessions.collection_name_prefix = "#{site.id}__"
      end
    end
  end
end
