require 'spec_helper'

module Locomotive
  module Liquid
    module Drops
      describe ContentTypeProxyCollection do

        before(:each) do
          @proxy_collection = ContentTypeProxyCollection.new(special_content_type)

          @registers = { :plugins => plugins }
          @assigns = {}
          context_stub = Stubs::Context.new
          context_stub.registers = @registers
          context_stub.assigns = @assigns
          @proxy_collection.instance_variable_set(:@context, context_stub)
        end

        context 'plugins' do

          it 'should apply a nil scope if there are no plugins' do
            current_scope.should be_nil
          end

          it 'should apply the scope for this content type' do
            set_plugins(Plugins::Plugin1)
            current_scope.count.should == 1
            current_scope.should == { :field1 => :value1 }
          end

          it 'should apply multiple scopes with an "and" query' do
            set_plugins(Plugins::Plugin1, Plugins::Plugin2)
            current_scope['$and'].count.should == 2
            current_scope['$and'].should include({ :field1 => :value1 })
            current_scope['$and'].should include({ :field3 => :value3 })
          end

          it 'should not apply the scope for other content types' do
            set_plugins(Plugins::Plugin1, Plugins::Plugin2)
            current_scope['$and'].should_not include({ :field2 => :value2 })
            current_scope['$and'].should_not include({ :field4 => :value4 })
          end

          it 'should also apply the scope supplied by "with_scope"' do
            @assigns['with_scope'] = { 'special_field' => 'special_value' }
            current_scope.should == { 'special_field' => 'special_value' }

            set_plugins(Plugins::Plugin1, Plugins::Plugin2)
            current_scope['$and'].count.should == 3
            current_scope['$and'].should include({ 'special_field' => 'special_value' })
            current_scope['$and'].should include({ :field1 => :value1 })
            current_scope['$and'].should include({ :field3 => :value3 })
          end

        end

        protected

        def special_content_type
          Plugins.special_content_type
        end

        def set_plugins(*plugin_classes)
          @current_scope = nil
          @plugins ||= []
          @plugins.clear
          plugin_classes.each do |plugin_class|
            @plugins << plugin_class.new({})
          end
        end

        def plugins
          @plugins ||= []
        end

        def current_scope
          @current_scope ||= @proxy_collection.send(:current_scope)
        end

        ## Classes ##

        module Plugins

          def self.special_content_type
            @special_content_type ||= ContentType.new
          end

          class Plugin1

            include Locomotive::Plugin

            def content_type_scope(content_type)
              if content_type == special_content_type
                { :field1 => :value1 }
              else
                { :field2 => :value2 }
              end
            end

            protected

            def special_content_type
              ::Locomotive::Liquid::Drops::Plugins.special_content_type
            end

          end

          class Plugin2

            include Locomotive::Plugin

            def content_type_scope(content_type)
              if content_type == special_content_type
                { :field3 => :value3 }
              else
                { :field4 => :value4 }
              end
            end

            protected

            def special_content_type
              ::Locomotive::Liquid::Drops::Plugins.special_content_type
            end

          end

        end

        module Stubs

          class Context

            attr_accessor :registers, :assigns

            def [](key)
              self.assigns[key]
            end

          end

        end

      end
    end
  end
end
