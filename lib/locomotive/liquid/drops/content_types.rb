module Locomotive
  module Liquid
    module Drops
      class ContentTypes < ::Liquid::Drop

        def before_method(meth)
          type = @context.registers[:site].content_types.where(:slug => meth.to_s).first
          if(type.from_remote_source)
            cache_key = Digest::SHA1.hexdigest(type.remote_source_url)
            
            minimum_cache_time = 10
            if type.remote_source_expiry == 'none'
              expires_in = minimum_cache_time
            else
              expires_in = type.remote_source_expiry.to_i rescue 1.minute 
            end
            force = true
            if(Rails.cache.exist?(cache_key+"_expiry"))
               force = Rails.cache.read(cache_key+"_expiry") != expires_in
            end
            Rails.cache.fetch(cache_key, :expires_in => expires_in, :force => force) do
              Rails.cache.write(cache_key+"_expiry", expires_in)
              #is this site hosted by this app?
              if Locomotive::Site.match_domain(URI.parse(type.remote_source_url).host).size > 0
                Locomotive.log  "[Liquid template] Loading URL from this app: #{type.remote_source_url}"
                JSON.parse(get_page_from_local_site(type.remote_source_url))
              else
                Locomotive.log  "[Liquid template] Loading Remote URL: #{type.remote_source_url}"
                Locomotive::Httparty::Webservice.consume(type.remote_source_url)
              end
            end
          else
            ContentTypeProxyCollection.new(type)
          end
        end
        
        
        protected
        
        def get_page_from_local_site(url)
          env = ::Rack::MockRequest.env_for(url)
          response = Rails.application.call(env)
          response[2][0]
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
          else
            Locomotive.log :warn, "[Liquid template] trying to call #{meth} on a content_type object"
          end
        end

        protected

        def collection
          @collection ||= @content_type.ordered_entries(@context['with_scope'])
        end
      end

    end
  end
end
