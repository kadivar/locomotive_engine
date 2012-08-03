Feature: Add, view, and configure plugins
  In order to add functionality to Locomotive CMS through plugins
  As a CMS user
  I should be able to add, view, and/or configure plugins based on my role

  Background:
    Given I have a site set up
    And I have a designer and an author

  Scenario: Adding a plugin to a site
    Given I am an authenticated "admin"
    And I have registered the plugin "my_plugin"
    Then I should be able to add the plugin "my_plugin" to my site
