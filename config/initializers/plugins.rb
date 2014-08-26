# Do load initialization for all plugins
Rails.application.config.after_initialize do
  Locomotive::Plugins.do_all_load_init
end
