Feature: Plugin Settings
  In order to ensure plugin settings are not tampered with
  As an admin, designer or author
  I will be restricted based on my role

Background:
  Given I have the site: "test site" set up
  And the plugin "first_plugin" is enabled
  And I have a designer and an author

  @javascript
  Scenario: Accessing plugin settings as an Admin
    Given I am an authenticated "admin"
    When I go to site settings
    And I unfold all folded inputs
    Then I should see "Plugins"
    And I should see "First plugin"
    And I should see the element "#site_plugins_first_plugin_enabled"
    And I should see "Second plugin"
    And I should see the element "#site_plugins_second_plugin_enabled"
    And I should see "My Plugin Config"

  @javascript
  Scenario: Accessing plugin settings as a Designer
    Given I am an authenticated "designer"
    When I go to site settings
    And I unfold all folded inputs
    Then I should see "Plugins"
    And I should see "First plugin"
    And I should not see the element "#site_plugins_first_plugin_enabled"
    And I should not see "Second plugin"
    And I should not see the element "#site_plugins_second_plugin_enabled"
    And I should see "My Plugin Config"

  @javascript
  Scenario: Accessing plugin settings as an Author
    Given I am an authenticated "author"
    When I go to site settings
    And I unfold all folded inputs
    Then I should see "Plugins"
    And I should see "First plugin"
    And I should not see the element "#site_plugins_first_plugin_enabled"
    And I should not see "Second plugin"
    And I should not see the element "#site_plugins_second_plugin_enabled"
    And I should not see "My Plugin Config"
