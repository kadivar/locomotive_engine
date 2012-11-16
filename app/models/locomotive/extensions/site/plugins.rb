

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

            clear_cached_plugin_data!
          end

          def plugin_liquid_filters
            @plugin_liquid_filters ||= [].tap do |arr|
              self.enabled_plugin_objects_by_id.each do |plugin_id, plugin_obj|
                arr << plugin_obj.prefixed_liquid_filter_module(plugin_id)
              end
            end
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

          # Clear cached data on reload
          def reload(*args, &block)
            clear_cached_plugin_data!
            super
          end

          protected

          def clear_cached_plugin_data!
            @enabled_plugin_objects_by_id = nil
            @all_plugin_objects_by_id = nil
            @plugin_liquid_filters = nil
          end

          def fetch_or_build_plugin_data(plugin_id)
            existing_plugin = self.plugin_data.where(plugin_id: plugin_id).first
            if existing_plugin
              existing_plugin
            else
              self.plugin_data.build(plugin_id: plugin_id)
            end
          end

          def construct_plugin_object_for_data(plugin_data)
            config = plugin_data.config
            plugin_data.plugin_class.new(config)
          end

        end

      end
    end
  end
end
