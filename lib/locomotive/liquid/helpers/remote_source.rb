module Locomotive
  module Liquid
    module Helpers
      module RemoteSource
        
        def load_remote_source(source_url, expiry_time = 1.minute, force_load = false)
          cache_key = Digest::SHA1.hexdigest(source_url)
            
          minimum_cache_time = 10
          if expiry_time == 'none'
            expires_in = minimum_cache_time
          else
            
            expires_in = [(expiry_time == 'simple'?  1.minute : expiry_time.to_i), minimum_cache_time].max
          end
          force = true
          if(Rails.cache.exist?(cache_key+"_expiry"))
             force = Rails.cache.read(cache_key+"_expiry") != expires_in
          end
          Rails.cache.fetch(cache_key, :expires_in => expires_in, :force => (force or force_load)) do
            Rails.cache.write(cache_key+"_expiry", expires_in)
            #is this site hosted by this app?
            if Locomotive::Site.match_domain(URI.parse(source_url).host).size > 0
              Locomotive.log  "[Liquid template] Loading URL from this app: #{source_url}"
              JSON.parse(get_page_from_local_site(source_url))
            else
              Locomotive.log  "[Liquid template] Loading Remote URL: #{source_url}"
              Locomotive::Httparty::Webservice.consume(source_url)
            end
          end
        end
        
        protected
        
        def get_page_from_local_site(url)
          env = ::Rack::MockRequest.env_for(url)
          response = Rails.application.call(env)
          response[2][0]
        end
        
      end
    end
  end
end