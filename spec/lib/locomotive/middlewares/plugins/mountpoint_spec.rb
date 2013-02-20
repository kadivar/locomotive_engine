
require 'spec_helper'

module Locomotive
  module Middlewares
    module Plugins
      describe Mountpoint do

        it 'should store the mountpoint host' do
          called = false
          mountpoint = Mountpoint.new(Proc.new do |env|
            called = true
            Mountpoint.mountpoint_host.should == 'http://www.example.com:3000'
          end)

          mountpoint.call(default_env)
          called.should be_true
        end

        protected

        def default_env
          {
            'SERVER_NAME' => 'www.example.com',
            'SERVER_PORT' => '3000',
            'rack.url_scheme' => 'http'
          }
        end

      end
    end
  end
end
