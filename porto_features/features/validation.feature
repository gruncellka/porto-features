@offline
Feature: Validation
  As a developer
  I want to validate letters and addresses
  So that I can ensure shipping requirements are met

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Validate valid standard letter
    Given I have a letter with type "STANDARD"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 20 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the letter type should be confirmed as "letter_standard"

  Scenario: Validate valid compact letter
    Given I have a letter with type "COMPACT"
    And length 229 mm
    And width 162 mm
    And height 5 mm
    And weight 30 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the letter type should be confirmed as "letter_compact"

  Scenario: Validate valid large letter
    Given I have a letter with type "LARGE"
    And length 324 mm
    And width 229 mm
    And height 5 mm
    And weight 100 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the letter type should be confirmed as "letter_large"

  Scenario: Validate valid maxi letter
    Given I have a letter with type "MAXI"
    And length 353 mm
    And width 250 mm
    And height 60 mm
    And weight 500 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the letter type should be confirmed as "letter_maxi"

  Scenario: Validate valid merchandise letter
    Given I have a letter with type "MERCHANDISE"
    And length 353 mm
    And width 250 mm
    And height 60 mm
    And weight 1000 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the letter type should be confirmed as "merchandise"

  Scenario: Reject letter with invalid dimensions
    Given I have a letter with type "STANDARD"
    And length 50 mm
    And width 50 mm
    And height 5 mm
    And weight 10 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should fail
    And I should get an error about invalid dimensions

  Scenario: Reject letter that is too heavy
    Given I have a letter with type "STANDARD"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 2500 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should fail
    And I should get an error about weight exceeding maximum

  Scenario: Reject letter with invalid address
    Given I have a letter with type "STANDARD"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 20 grams
    And invalid destination address
    And valid origin address
    When I validate the letter
    Then the validation should fail
    And I should get an error about invalid address

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

  Scenario: Validation returns warnings for edge cases
    Given I have a letter with type "STANDARD"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 20 grams
    And valid destination address
    And valid origin address
    And the destination country has restrictions
    When I validate the letter
    Then the validation should pass
    And I should get warnings about restrictions
