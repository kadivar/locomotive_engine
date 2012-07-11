
%w{processor drop_container}.each do |f|
  require File.join(File.dirname(__FILE__), 'plugins', f)
end
