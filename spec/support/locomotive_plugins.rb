
module LocomotivePluginsSpecHelpers

  def self.before_each
    clear_plugins!
    setup_load_path!
  end

  def self.clear_plugins!
    Locomotive::Plugins.instance_variable_set(:@initialized, nil)
    Locomotive::Plugin.instance_variable_set(:@trackers, [])
    Locomotive::Plugin.instance_variable_set(:@plugin_classes, Set.new)
    Locomotive::Plugin.instance_variable_set(:@registered_plugins, nil)
  end

  def self.setup_load_path!
    $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib',
      'locomotive', 'plugins', 'plugins_spec_files'))
  end

end
