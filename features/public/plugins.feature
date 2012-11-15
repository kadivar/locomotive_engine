Feature: View output from plugins on public pages
  In order to view the functionality added by a plugin
  As a site visitor
  I should be able to see the output from the plugin

  Background:
    Given I have a site set up
    And I have registered the plugin "my_plugin"
    And a page named "plugin-page" with the template:
    """
    {% if plugins.my_plugin %}
    {{ plugins.my_plugin.greeting }}
    {% else %}
    Goodbye, World!
    {% endif %}
    {{ 'google.com' | my_plugin_add_http_prefix }}
    """

  Scenario: Plugin is enabled
    Given the plugin "my_plugin" is enabled
    When I view the rendered page at "/plugin-page"
    Then the rendered output should look like:
    """
    Hello, World!
    """
    And the rendered output should look like:
    """
    http://google.com
    """

  Scenario: Plugin is not enabled
    When I view the rendered page at "/plugin-page"
    Then the rendered output should look like:
    """
    Goodbye, World!
    """
    And the rendered output should look like:
    """
    google.com
    """

  Scenario: Plugin is enabled and then disabled
    Given the plugin "my_plugin" is enabled
    And the plugin "my_plugin" is disabled
    When I view the rendered page at "/plugin-page"
    Then the rendered output should look like:
    """
    Goodbye, World!
    """
