
Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '**', '*.rb')) do |f|
  require f
end
