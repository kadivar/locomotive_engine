

module Locomotive
  module Extensions
    module Site
      module Plugins

        extend ActiveSupport::Concern

        included do

          embeds_many :plugin_data, :class_name => 'Locomotive::PluginData'

          ## Getter and setter virtual attributes ##

          def plugins
            LocomotivePlugins.registered_plugins.keys.collect do |plugin_id|
              data_obj = fetch_or_build_plugin_data(plugin_id)

              # Return hash
              {
                :plugin_id => plugin_id,
                :plugin_name => data_obj.name,
                :plugin_enabled => data_obj.enabled,
                :plugin_config => data_obj.config
              }
            end
          end

          def plugins=(plugins_indexed_hash)
            # Convert to hashes for quick lookup
            plugin_hashes_by_id = plugins_indexed_hash.inject({}) do |h, (index, plugin)|
              h[plugin[:plugin_id]] = plugin
              h
            end

            # Update plugin data objects
            LocomotivePlugins.registered_plugins.keys.each do |plugin_id|
              data_obj = fetch_or_build_plugin_data(plugin_id)
              plugin_hash = plugin_hashes_by_id[plugin_id] || {}
              if plugin_hash[:plugin_enabled] == 'false'
                plugin_hash[:plugin_enabled] = false
              end

              data_obj.config = plugin_hash[:plugin_config]
              data_obj.enabled = !!plugin_hash[:plugin_enabled]
            end

            # Clear cached data
            @all_plugin_objects_by_id = nil
            @enabled_plugin_objects_by_id = nil
          end

          # Hash of instantiated plugin object for each enabled plugin
          def enabled_plugin_objects_by_id
            @enabled_plugin_objects_by_id ||= (self.plugin_data.select do |plugin_data|
              plugin_data.enabled
            end).inject({}) do |h, plugin_data|
              plugin_id = plugin_data.plugin_id
              h[plugin_id] = construct_plugin_object_for_data(plugin_data)
              h
            end
          end

          # Hash of instantiated plugin object for each registered plugin. This
          # will create plugin_data objects for registered plugins if needed
          def all_plugin_objects_by_id
            @all_plugin_objects_by_id ||= LocomotivePlugins.registered_plugins.keys.inject({}) do |h, plugin_id|
              plugin_obj = enabled_plugin_objects_by_id[plugin_id]
              if plugin_obj
                h[plugin_id] = plugin_obj
              else
                plugin_data = fetch_or_build_plugin_data(plugin_id)
                h[plugin_id] = construct_plugin_object_for_data(plugin_data)
              end
              h
            end
          end

          protected

          def plugin_data_by_id
            @plugin_data_by_id ||= self.plugin_data.inject({}) do |h, plugin_data|
              plugin_id = plugin_data.plugin_id
              h[plugin_id] = plugin_data
              h
            end
          end

          def fetch_or_build_plugin_data(plugin_id)
            existing_plugin = plugin_data_by_id[plugin_id]
            if existing_plugin
              existing_plugin
            else
              plugin_data_by_id[plugin_id] = self.plugin_data.build(:plugin_id => plugin_id)
            end
          end

          def construct_plugin_object_for_data(plugin_data)
            plugin_id = plugin_data.plugin_id
            config = plugin_data.config
            plugin_data.plugin_class.new(config)
          end

        end

      end
    end
  end
end
