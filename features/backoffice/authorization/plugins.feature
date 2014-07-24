Feature: Plugin Settings
  In order to ensure plugin settings are not tampered with
  As an admin, designer or author
  I will be restricted based on my role

Background:
  Given I have the site: "test site" set up
  And the plugin "first_cucumber_plugin" is enabled
  And I have a designer and an author

  @javascript
  Scenario: Accessing plugin settings as an Admin
    Given I am an authenticated "admin"
    When I go to site settings
    And I unfold all folded inputs
    Then I should see "Plugins"
    And I should see "First cucumber plugin"
    And I should see the element "#site_plugins_first_cucumber_plugin_enabled"
    And I should see "Second cucumber plugin"
    And I should see the element "#site_plugins_second_cucumber_plugin_enabled"
    And I should see "Cucumber Plugin Config"

  @javascript
  Scenario: Accessing plugin settings as a Designer
    Given I am an authenticated "designer"
    When I go to site settings
    And I unfold all folded inputs
    Then I should see "Plugins"
    And I should see "First cucumber plugin"
    And I should not see the element "#site_plugins_first_cucumber_plugin_enabled"
    And I should not see "Second cucumber plugin"
    And I should not see the element "#site_plugins_second_cucumber_plugin_enabled"
    And I should see "Cucumber Plugin Config Two"

  @javascript
  Scenario: Accessing plugin settings as an Author
    Given I am an authenticated "author"
    When I go to site settings
    And I unfold all folded inputs
    Then I should see "Plugins"
    And I should see "First cucumber plugin"
    And I should not see the element "#site_plugins_first_cucumber_plugin_enabled"
    And I should not see "Second cucumber plugin"
    And I should not see the element "#site_plugins_second_cucumber_plugin_enabled"
    And I should not see "Cucumber Plugin Config"
