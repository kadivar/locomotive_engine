@javascript
Feature: Add, view, and configure plugins
  In order to add functionality to Locomotive CMS through plugins
  As a CMS user
  I should be able to add, view, and/or configure plugins based on my role

  Background:
    Given I have a site set up
    And I have a designer and an author
    And I have registered the plugin "my_plugin"

  Scenario: Adding a plugin to a site
    Given I am an authenticated "admin"
    When I go to site settings
    And I unfold all folded inputs
    And I check "site_plugins_my_plugin_enabled"
    And I press "Save"
    Then after the AJAX finishes, the plugin "my_plugin" should be enabled

  Scenario: Configuring plugins
    Given I am an authenticated "designer"
    And the plugin "my_plugin" is enabled
    When I go to site settings
    And I unfold all folded inputs
    And I follow "toggle" within "#plugin_list"
    And I fill in "my_plugin_config" with "A Value"
    And I press "Save"
    Then after the AJAX finishes, the plugin config for "my_plugin" should be:
        | my_plugin_config  | A Value   |
