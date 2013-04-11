Feature: View output from plugins on public pages
  In order to view the functionality added by a plugin
  As a site visitor
  I should be able to see the output from the plugin

  Background:
    Given I have a site set up
    And a page named "plugin-page" with the template:
    """
    {% if plugins.cucumber_plugin %}
    {{ plugins.cucumber_plugin.greeting }}
    {% else %}
    Goodbye, World!
    {% endif %}
    {{ 'google.com' | cucumber_plugin_add_http_prefix }}
    {% cucumber_plugin_paragraph %}My Text{% endcucumber_plugin_paragraph %}
    My Text{% cucumber_plugin_newline %}
    """

  Scenario: Plugin is enabled
    Given the plugin "cucumber_plugin" is enabled
    When I view the rendered page at "/plugin-page"
    Then the rendered output should look like:
    """
    Hello, World!

    http://google.com
    <p>My Text</p>
    My Text<br />
    """

  Scenario: Plugin is not enabled
    When I view the rendered page at "/plugin-page"
    Then the rendered output should look like:
    """
    Goodbye, World!

    google.com
    My Text
    My Text
    """

  Scenario: Plugin is enabled and then disabled
    Given the plugin "cucumber_plugin" is enabled
    And the plugin "cucumber_plugin" is disabled
    When I view the rendered page at "/plugin-page"
    Then the rendered output should look like:
    """
    Goodbye, World!

    google.com
    My Text
    My Text
    """
