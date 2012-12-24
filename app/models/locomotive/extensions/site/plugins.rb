

module Locomotive
  module Extensions
    module Site
      module Plugins

        extend ActiveSupport::Concern

        included do

          embeds_many :plugin_data, :class_name => 'Locomotive::PluginData'

          ## Getter and setter virtual attributes ##

          # Takes an optional block which will be called for each plugin to
          # determine whether it should be included. This is needed because
          # some users can only view some plugins
          def plugins
            [].tap do |arr|
              LocomotivePlugins.registered_plugins.keys.collect do |plugin_id|
                data_obj = fetch_or_build_plugin_data(plugin_id)

                # If a block is given, only include the hash if the block
                # returns true. Otherwise include them all
                if !block_given? || yield(data_obj)
                  arr << {
                    :plugin_id => plugin_id,
                    :plugin_name => data_obj.name,
                    :plugin_enabled => data_obj.enabled,
                    :plugin_config => data_obj.config
                  }
                end
              end
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

              if plugin_hash.has_key?(:plugin_enabled)
                data_obj.enabled = !!plugin_hash[:plugin_enabled]
              end

              if plugin_hash.has_key?(:plugin_config)
                config = plugin_hash[:plugin_config]
                plugin_hash[:plugin_config_boolean_fields].try(:each) do |boolean_field|
                  if config.has_key?(boolean_field)
                    val = config[boolean_field]
                    config[boolean_field] = val == 'false' ? false : !!val
                  end
                end
                data_obj.config = plugin_hash[:plugin_config]
              end
            end

            clear_cached_plugin_data!
          end

          # Get the plugin object for a given ID. This is required by the
          # locomotive_plugins gem in order to populate the liquid context
          # properly. See Locomotive::Plugin::Liquid::ContextHelpers
          def plugin_object_for_id(plugin_id)
            self.all_plugin_objects_by_id[plugin_id]
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
            plugin_data.plugin_class.new(config) do |plugin_obj|
              # Use the site_id as the db_model_container name for this plugin
              # object
              plugin_obj.use_db_model_container(self.id.to_s)
            end
          end

        end

      end
    end
  end
end
