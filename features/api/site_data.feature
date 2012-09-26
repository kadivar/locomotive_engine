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
    And I have a custom model named "Projects" with
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
      | current_site/name               | "my site"             |
      | pages/0/fullpath                | "index"               |
      | snippets/0/name                 | "My Snippet"          |
      | theme_assets/0/local_path       | "my_javascript.js"    |
