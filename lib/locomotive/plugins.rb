
%w{processor drop_container liquid_tag_loader}.each do |f|
  require File.join(File.dirname(__FILE__), 'plugins', f)
end
