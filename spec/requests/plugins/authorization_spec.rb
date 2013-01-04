require 'spec_helper'

describe 'Plugin Authorization' do

  before(:each) do
    create_current_site!
    create_accounts!
    create_memberships!

    stub_i18n_fallbacks
    set_current_site
    Locomotive::Plugins::SpecHelpers.stub_registered_plugins(FirstPlugin,
      SecondPlugin)
    enable_plugins
  end

  # Specifies whether each role should be allowed to enable/disable or
  # configure plugins
  RULES = {
    admin: {
      enable: true,
      configure: true
    },
    designer: {
      enable: false,
      configure: :only_enabled
    },
    author: {
      enable: false,
      configure: false
    }
  }

  # Generate specs for all the rules
  RULES.each do |role, rules|

    # Enabling plugins
    can_enable = rules[:enable]
    it "should#{can_enable ? '' : ' not'} allow #{role}s to enable or disable plugins" do
      set_current_account_from_string(role)
      enabled = do_enable_and_disable_plugins

      should_or_should_not = can_enable ? :should : :should_not
      enabled['first_plugin'].send(should_or_should_not, be_false)
      enabled['second_plugin'].send(should_or_should_not, be_true)
    end

    # Configuring plugins
    can_configure = !!rules[:configure]
    only_enabled = rules[:configure] == :only_enabled
    it "should#{can_configure ? '' : ' not'} allow #{role}s to configure#{only_enabled ? ' enabled' : ''} plugins" do
      set_current_account_from_string(role)

      config = do_configure_plugins
      expected_first_config = { 'first_plugin_key' => 'first_plugin_value' }
      expected_second_config = { 'second_plugin_key' => 'second_plugin_value' }

      # Check to see if we've configured what we're allowed to configure
      if can_configure
        config['first_plugin'].should == expected_first_config
        if only_enabled
          config['second_plugin'].should_not == expected_second_config
        else
          config['second_plugin'].should == expected_second_config
        end
      else
        config['first_plugin'].should_not == expected_first_config
        config['second_plugin'].should_not == expected_second_config
      end
    end

  end

  protected

  attr_reader :site, :admin, :designer, :author

  def create_current_site!
    @site = FactoryGirl.create(:site)
  end

  def create_accounts!
    @admin = FactoryGirl.create('admin user')
    @designer = FactoryGirl.create('designer user')
    @author = FactoryGirl.create('author user')
  end

  def create_memberships!
    # Remove validations for role
    Locomotive::Membership.any_instance.stubs(:can_change_role).returns(true)

    # Create memberships
    FactoryGirl.create(:admin, account: admin, site: site)
    FactoryGirl.create(:designer, account: designer, site: site)
    FactoryGirl.create(:author, account: author, site: site)
  end

  def controller_class
    Locomotive::CurrentSiteController
  end

  def stub_i18n_fallbacks
    # For some reason this method is making other specs fail. Stub it out
    controller_class.any_instance.stubs(:setup_i18n_fallbacks).returns(true)
  end

  def set_current_site
    controller_class.any_instance.stubs(:current_site).returns(site)
  end

  def set_current_account(account)
    controller_class.any_instance.stubs(:current_locomotive_account).returns(account)
    controller_class.any_instance.stubs(:authenticate_locomotive_account!).returns(true)
  end

  def set_current_account_from_string(str)
    if %w{admin designer author}.include?(str.to_s)
      set_current_account(self.send(str))
    else
      nil
    end
  end

  def enable_plugins
    Factory.create(:plugin_data, plugin_id: 'first_plugin', enabled: true,
      site: site)
    Factory.create(:plugin_data, plugin_id: 'second_plugin', enabled: false,
      site: site)
  end

  def do_update(params)
    put '/locomotive/current_site', site: params
  end

  def do_enable_and_disable_plugins
    params = {
      plugins: {
        '0' => {
          plugin_id: 'first_plugin',
          plugin_enabled: false
        },
        '1' => {
          plugin_id: 'second_plugin',
          plugin_enabled: true
        }
      }
    }.with_indifferent_access

    do_update(params)

    {}.tap do |h|
      %w{first_plugin second_plugin}.each do |plugin_id|
        plugin_data = site.plugin_data.where(plugin_id: plugin_id).first
        h[plugin_id] = plugin_data.enabled
      end
    end
  end

  def do_configure_plugins
    params = {
      plugins: {
        '0' => {
          plugin_id: 'first_plugin',
          plugin_config: { 'first_plugin_key' => 'first_plugin_value' }
        },
        '1' => {
          plugin_id: 'second_plugin',
          plugin_config: { 'second_plugin_key' => 'second_plugin_value' }
        }
      }
    }.with_indifferent_access

    do_update(params)

    {}.tap do |h|
      %w{first_plugin second_plugin}.each do |plugin_id|
        plugin_data = site.plugin_data.where(plugin_id: plugin_id).first
        h[plugin_id] = plugin_data.config
      end
    end
  end

  Locomotive::Plugins.init_plugins do
    class FirstPlugin
      include Locomotive::Plugin
    end

    class SecondPlugin
      include Locomotive::Plugin
    end
  end

end
