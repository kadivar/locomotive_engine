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
    Given I am an authenticated "author"
    When I go to site settings
    And I unfold all folded inputs
    And I check "site_enabled_plugins_my_plugin"
    And I press "Save"
    Then the plugin "my_plugin" should be enabled
    When I unfold all folded inputs
    Then the "site_enabled_plugins_my_plugin" checkbox should be checked
