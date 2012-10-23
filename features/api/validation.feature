Feature: API Validations
  In order to manage content types programmatically
  As an API user
  I will be able to check validation of objects I've uploaded

  Background:
    Given I have the site: "test site" set up
    And I have an "admin" API token

  Scenario: Creating Content Type with invalid order_by_attribute
    When I do an API POST to content_types.json with:
    """
    {
      "content_type": {
        "name": "Employees",
        "slug": "employees",
        "order_by_attribute": "nonexistant_attribute",
        "entries_custom_fields": [
          {
            "label": "Name",
            "name": "name",
            "type": "string"
          },
          {
            "label": "Position",
            "name": "position",
            "type": "string"
          }
        ]
      }
    }
    """
    Then the JSON response at "order_by_attribute/0" should be "is invalid"
    When I do an API GET request to content_types.json
    Then the JSON response should be an array
    And the JSON response should have 0 entries
