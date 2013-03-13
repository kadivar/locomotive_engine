Feature: Plugin Data
  In order to ensure plugin data is not tampered with
  As an admin, designer or author
  I will be restricted based on my role

  Background:
    Given I have the site: "test site" set up
    And the plugin "cucumber_plugin" is enabled
    And the plugin data for "cucumber_plugin" has ID "4f832c2cb0d86d3f42fffffe"
    And the config for the plugin "cucumber_plugin" is:
      | attr    | value     |
    And the plugin "first_cucumber_plugin" is enabled
    And the plugin data for "first_cucumber_plugin" has ID "4f832c2cb0d86d3f43000000"
    And the plugin "second_cucumber_plugin" is disabled
    And the plugin data for "second_cucumber_plugin" has ID "4f832c2cb0d86d3f42ffffff"
    And I have a designer and an author

  Scenario: As an unauthenticated user
    Given I am not authenticated
    When I do an API GET to plugin_data.json
    Then the JSON response at "error" should be "You need to sign in or sign up before continuing."

  # listing plugins

  Scenario: Accessing plugin data list as an Admin
    Given I have an "admin" API token
    When I do an API GET request to plugin_data.json
    Then the JSON response should be an array
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "cucumber_plugin" }
    """
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "first_cucumber_plugin" }
    """
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "second_cucumber_plugin" }
    """

  Scenario: Accessing plugin data list as a Designer
    Given I have a "designer" API token
    When I do an API GET request to plugin_data.json
    Then the JSON response should be an array
    And the JSON response should have 2 entries
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "cucumber_plugin" }
    """
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "first_cucumber_plugin" }
    """

  Scenario: Accessing plugin data list as an Author
    Given I have an "author" API token
    When I do an API GET request to plugin_data.json
    Then the JSON response should be an array
    And the JSON response should have 2 entries
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "cucumber_plugin" }
    """
    And the JSON array should include a hash which includes:
    """
    { "plugin_id": "first_cucumber_plugin" }
    """

  # showing plugin

  Scenario: Accessing plugin data as an Admin
    Given I have an "admin" API token
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42fffffe.json
    Then the JSON response at "plugin_id" should be "cucumber_plugin"
    And the JSON response at "enabled" should be true
    And the JSON response at "config" should be:
    """
    { "attr": "value" }
    """
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42ffffff.json
    Then the JSON response at "plugin_id" should be "second_cucumber_plugin"
    And the JSON response at "enabled" should be false

  Scenario: Accessing my plugin data as a Designer
    Given I have a "designer" API token
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42fffffe.json
    Then the JSON response at "plugin_id" should be "cucumber_plugin"
    And the JSON response at "enabled" should be true
    And the JSON response at "config" should be:
    """
    { "attr": "value" }
    """
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42ffffff.json
    Then an access denied error should occur

  Scenario: Accessing my plugin as an Author
    Given I have an "author" API token
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42fffffe.json
    Then the JSON response at "plugin_id" should be "cucumber_plugin"
    And the JSON response at "enabled" should be true
    And the JSON response at "config" should be:
    """
    { "attr": "value" }
    """
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42ffffff.json
    Then an access denied error should occur

  # update plugin

  Scenario: Updating plugin data as an Admin
    Given I have an "admin" API token
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42fffffe.json with:
    """
    {
      "plugin_data": {
        "enabled": false,
        "config": { "new_attr": "new value" }
      }
    }
    """
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42fffffe.json
    Then the JSON response at "plugin_id" should be "cucumber_plugin"
    And the JSON response at "enabled" should be false
    And the JSON response at "config" should be:
    """
    { "new_attr": "new value" }
    """

  Scenario: Updating plugin data config as a Designer
    Given I have a "designer" API token
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42fffffe.json with:
    """
    {
      "plugin_data": {
        "config": { "new_attr": "new value" }
      }
    }
    """
    When I do an API GET request to plugin_data/4f832c2cb0d86d3f42fffffe.json
    Then the JSON response at "plugin_id" should be "cucumber_plugin"
    And the JSON response at "enabled" should be true
    And the JSON response at "config" should be:
    """
    { "new_attr": "new value" }
    """

  Scenario: Updating plugin data enabled as a Designer
    Given I have a "designer" API token
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42fffffe.json with:
    """
    {
      "plugin_data": {
        "enabled": false,
        "config": { "new_attr": "new value" }
      }
    }
    """
    Then an access denied error should occur
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42fffffe.json with:
    """
    {
      "plugin_data": {
        "enabled": false
      }
    }
    """
    Then an access denied error should occur

  Scenario: Updating plugin data for disabled plugin as a Designer
    Given I have a "designer" API token
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42ffffff.json with:
    """
    {
      "plugin_data": {
        "config": { "new_attr": "new value" }
      }
    }
    """
    Then an access denied error should occur

  Scenario: Updating plugin data as an Author
    Given I have a "author" API token
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42fffffe.json with:
    """
    {
      "plugin_data": {
        "enabled": false
      }
    }
    """
    Then an access denied error should occur
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42fffffe.json with:
    """
    {
      "plugin_data": {
      "config": { "new_attr": "new value" }
      }
    }
    """
    Then an access denied error should occur
    When I do an API PUT to plugin_data/4f832c2cb0d86d3f42ffffff.json with:
    """
    {
      "plugin_data": {
      "config": { "new_attr": "new value" }
      }
    }
    """
    Then an access denied error should occur
