@sdk
@core
Feature: CLI core commands
  As a developer or integrator
  I want generic CLI commands for the Porto SDK
  So that I can inspect data and validate addresses without provider catalog inventories
  Catalog data price rows use field "price"; public quote CLI uses "amount".

  Background:
    Given I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: Show porto-data information
    When I call CLI data info command
    Then the result should have field "version"
    And the result should have field "generated_at"
    And the result should have field "entities"

  Scenario: Validate address from JSON data
    Given I have a valid address JSON data
    When I call CLI validate address command
    Then the result should have field "valid" with value true
    And the result should have field "errors" as array

  Scenario: Generic config summary shape
    When I call CLI config command
    Then the result should have field "data_path"
    And the result should have field "timeout" as number
    And the result should have field "retries" as number

  Scenario: CLI config command is deterministic
    When I call CLI config command
    Then the result should be stored for comparison
    When I call CLI config command
    Then the results should have same structure
    And the "data_path" fields should match

  Scenario: Changing provider updates catalog listing
    Given provider is "deutschepost"
    And I have porto-data available
    And I have a Porto SDK client initialized
    When I call CLI data products command
    Then the result should have array "products"
    And the products array should be stored for comparison
    Given provider is "ukrposhta"
    When I call CLI data products command
    Then the products array should differ from the stored products array
    Given provider is "laposte"
    When I call CLI data products command
    Then the products array should differ from the stored products array
    Given provider is "swisspost"
    When I call CLI data products command
    Then the products array should differ from the stored products array
