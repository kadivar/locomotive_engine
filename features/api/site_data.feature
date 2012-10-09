Feature: Site Data
  In order to manage an entire site programmatically
  As an API user
  I will be able to create, read, update, and destroy many pieces of data at once

  Background:
    Given I have the site: "test site" set up with name: "my site"
    And I have an "admin" API token
    And I have the following content assets:
      | id                          | file      |
      | 4f832c2cb0d86d3f42000000    | 5k.png    |
    And I have a custom model named "Projects" with id "4f832c2cb0d86d3f42000005" and
      | label       | type      | required        |
      | Name        | string    | true            |
    And I have entries for "Projects" with
      | id                          | name        | description           |
      | 4f832c2cb0d86d3f42000001    | Project 1   | The first project     |
    And a page named "hello-world" with id "4f832c2cb0d86d3f42000002"
    And a javascript asset named "my_javascript.js" with id "4f832c2cb0d86d3f42000004"
    And a snippet named "My Snippet" with id "4f832c2cb0d86d3f42000003" and template:
    """
    My Snippet
    """

  Scenario: Listing all data
    When I do an API GET request to site_data.json
    Then the JSON should have the following:
      | content_assets/0/filename       | "5k.png"              |
      | content_entries/projects/0/name | "Project 1"           |
      | content_types/0/name            | "Projects"            |
      | pages/0/fullpath                | "index"               |
      | snippets/0/name                 | "My Snippet"          |
      | theme_assets/0/local_path       | "my_javascript.js"    |

  Scenario: Simple create
    When I do an API POST to site_data.json with:
    """
    {
      "site_data": {
        "content_types": [
          {
            "name": "Employees",
            "entries_custom_fields": [
              {
                "label": "Name",
                "type": "string"
              }
            ]
          }
        ],
        "content_entries": {
          "projects": [
            {
              "name": "Another Project"
            }
          ],
          "employees": [
            {
              "name": "John Smith"
            }
          ]
        },
        "pages": [
          {
            "title": "My New Page",
            "parent_fullpath": "index"
          }
        ],
        "snippets": [
          {
            "name": "Another snippet",
            "template": "The best snippet ever!"
          }
        ]
      }
    }
    """
    When I do an API GET request to site_data.json
    Then the JSON should have the following:
      | content_entries/projects/1/name     | "Another Project"     |
      | content_types/1/name                | "Employees"           |
      | content_entries/employees/0/name    | "John Smith"          |
      | pages/3/title                       | "My New Page"         |
      | snippets/1/name                     | "Another snippet"     |

  Scenario: Failed create
    When I do an API POST to site_data.json with:
    """
    {
      "site_data": {
        "content_entries": {
          "projects": [
            {
              "_slug": "",
              "name": "Another Project"
            }
          ],
          "employees": [
            {
              "name": "John Smith"
            }
          ]
        },
        "pages": [
          {
            "slug": "hello-world",
            "title": "My New Page",
            "parent_fullpath": "index"
          }
        ],
        "snippets": [
          {
            "name": "Another snippet",
            "template": "The best snippet ever!"
          }
        ]
      }
    }
    """
    Then the JSON response should be:
    """
    {
      "errors": {
        "pages": {
          "0": {
            "slug": ["is already taken"]
          }
        },
        "content_entries": {
          "employees": ["content type does not exist"]
        }
      }
    }
    """
    When I do an API GET request to site_data.json
    Then the JSON should not have "content_entries/projects/1"
    And the JSON should not have "content_entries/employees"
    And the JSON should not have "content_types/1"
    And the JSON should not have "pages/3"
    And the JSON should not have "snippets/1"

  Scenario: Simple update
    When I do an API PUT to site_data.json with:
    """
    {
      "site_data": {
        "content_types": {
          "4f832c2cb0d86d3f42000005": {
            "name": "Awesome Projects"
          }
        },
        "content_entries": {
          "projects": {
            "4f832c2cb0d86d3f42000001": {
              "name": "My Awesome Project"
            }
          }
        },
        "pages": {
          "4f832c2cb0d86d3f42000002": {
            "title": "Awesomest page ever"
          }
        },
        "snippets": {
          "4f832c2cb0d86d3f42000003": {
            "name": "Awesome Snippet"
          }
        }
      }
    }
    """
    When I do an API GET request to site_data.json
    Then the JSON should have the following:
      | content_entries/projects/0/name | "My Awesome Project"  |
      | content_types/0/name            | "Awesome Projects"    |
      | pages/1/title                   | "Awesomest page ever" |
      | snippets/0/name                 | "Awesome Snippet"     |

  Scenario: Failed update
    When I do an API PUT to site_data.json with:
    """
    {
      "site_data": {
        "content_types": {
          "4f832c2cb0d86d3f42000005": {
            "name": ""
          }
        },
        "snippets": {
          "4f832c2cb0d86d3f42000003": {
            "name": "Awesome Snippet"
          }
        }
      }
    }
    """
    Then the JSON response should have the following:
      | "errors/content_types/4f832c2cb0d86d3f42000005/name/0" | "can't be blank"  |
    When I do an API GET request to site_data.json
    Then the JSON at "content_types/0/name" should not be ""
    And the JSON at "pages/1/title" should not be "Awesomest page ever"
    And the JSON at "snippets/0/name" should not be "Awesome snippet"

  Scenario: Simple delete
    When I do an API DELETE to site_data.json with:
    """
    {
      "site_data": {
        "content_assets": [
          "4f832c2cb0d86d3f42000000"
        ],
        "content_types": [
          "4f832c2cb0d86d3f42000005"
        ],
        "pages": [
          "4f832c2cb0d86d3f42000002"
        ],
        "theme_assets": [
          "4f832c2cb0d86d3f42000004"
        ],
        "snippets": [
          "4f832c2cb0d86d3f42000003"
        ]
      }
    }
    """
    Then I print the JSON response
    When I do an API GET request to site_data.json
    Then I print the JSON response
    Then the JSON at "content_assets" should have 0 entries
    And the JSON at "content_entries" should have 0 entries
    And the JSON at "content_types" should have 0 entries
    And the JSON at "pages" should have 2 entries
    And the JSON at "theme_assets" should have 0 entries
    And the JSON at "snippets" should have 0 entries
