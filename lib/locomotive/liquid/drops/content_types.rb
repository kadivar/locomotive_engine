module Locomotive
  module Liquid
    module Drops
      class ContentTypes < ::Liquid::Drop

        def before_method(meth)
          type = @context.registers[:site].content_types.where(:slug => meth.to_s).first
          ContentTypeProxyCollection.new(type)
        end

      end

      class ContentTypeProxyCollection < ProxyCollection

        def initialize(content_type)
          @content_type = content_type
          @collection   = nil
        end

        def public_submission_url
          @context.registers[:controller].main_app.locomotive_entry_submissions_url(@content_type.slug)
        end

        def api
          Locomotive.log :warn, "[Liquid template] the api for content_types has been deprecated and replaced by public_submission_url instead."
          { 'create' => public_submission_url }
        end

        def before_method(meth)
          klass = @content_type.entries.klass # delegate to the proxy class

          if (meth.to_s =~ /^group_by_(.+)$/) == 0
            klass.send(:group_by_select_option, $1, @content_type.order_by_definition)
          elsif (meth.to_s =~ /^(.+)_options$/) == 0
            klass.send(:"#{$1}_options").map { |option| option['name'] }
          else
            Locomotive.log :warn, "[Liquid template] trying to call #{meth} on a content_type object"
          end
        end

        protected

        def current_scope
          conditions = [ @context['with_scope'] ]
          conditions += @context.registers[:plugins].collect do |plugin|
            plugin.content_type_scope(@content_type)
          end

          conditions.compact!

          if conditions.blank?
            nil
          elsif conditions.count == 1
            conditions[0]
          else
            { '$and' => conditions }
          end
        end

        def collection
          @collection ||= @content_type.ordered_entries(current_scope)
        end
      end

    end
  end
end
