@sdk
@core
Feature: Address validation
  As a developer
  I want to validate addresses
  So that I can ensure shipping requirements are met

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Validate address with all required fields
    Given I have an address with name "John Doe"
    And street "Main Street"
    And house number "123"
    And postal code "10115"
    And city "Berlin"
    And country code "DE"
    When I validate the address
    Then the validation should pass
    And there should be no errors

  Scenario: Reject address with missing required fields
    Given I have an address with name "John Doe"
    And missing street
    And missing postal code
    And country code "DE"
    When I validate the address
    Then the validation should fail
    And I should get errors about missing required fields

  Scenario: Reject address with invalid country code
    Given I have an address with name "John Doe"
    And street "Main Street"
    And house number "123"
    And postal code "10115"
    And city "Berlin"
    And country code "XX"
    When I validate the address
    Then the validation should fail
    And I should get an error about invalid country code

  Scenario Outline: Validate jurisdiction address form fixture
    Given I have destination address fixture "<fixture>"
    When I validate the address
    Then the validation should pass
    And there should be no errors

    Examples:
      | fixture         |
      | valid_DE        |
      | valid_CH        |
      | valid_FR        |
      | valid_UA        |
      | valid_postbox_DE |
      | valid_postbox_UA |

  Scenario Outline: Reject invalid postal code for jurisdiction form
    Given I have destination address fixture "<fixture>"
    When I validate the address
    Then the validation should fail
    And I should get an error about invalid address

    Examples:
      | fixture            |
      | invalid_postal_DE |
      | invalid_postal_CH |
      | invalid_postal_FR |
      | invalid_postal_UA |
