@offline
Feature: Resolution
  As a developer
  I want to resolve product, zone, and weight tier from country code and weight
  So that I can determine the correct shipping configuration for a letter

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Resolve domestic letter
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then I should get product with id "letter_standard"
    And I should get zone with id "domestic"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve EU zone letter
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then I should get product with id "letter_standard"
    And I should get zone with id "zone_1_eu"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve world zone letter
    Given I want to send a letter to country "US"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then I should get product with id "letter_standard"
    And I should get zone with id "world"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve zone 2 europe letter
    Given I want to send a letter to country "CH"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then I should get product with id "letter_standard"
    And I should get zone with id "zone_2_europe"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve compact letter for medium weight
    Given I want to send a letter to country "DE"
    And the letter weight is 30 grams
    And the letter type is "COMPACT"
    When I resolve the shipping configuration
    Then I should get product with id "letter_compact"
    And I should get zone with id "domestic"
    And I should get weight tier "W0050"
    And the resolution should be valid

  Scenario: Resolve large letter for heavy weight
    Given I want to send a letter to country "DE"
    And the letter weight is 100 grams
    And the letter type is "LARGE"
    When I resolve the shipping configuration
    Then I should get product with id "letter_large"
    And I should get zone with id "domestic"
    And I should get weight tier "W0500"
    And the resolution should be valid

  Scenario: Resolve maxi letter for very heavy weight
    Given I want to send a letter to country "DE"
    And the letter weight is 500 grams
    And the letter type is "MAXI"
    When I resolve the shipping configuration
    Then I should get product with id "letter_maxi"
    And I should get zone with id "domestic"
    And I should get weight tier "W1000"
    And the resolution should be valid

  Scenario: Resolve merchandise letter
    Given I want to send a letter to country "DE"
    And the letter weight is 1000 grams
    And the letter type is "MERCHANDISE"
    When I resolve the shipping configuration
    Then I should get product with id "merchandise"
    And I should get zone with id "domestic"
    And I should get weight tier "W2000"
    And the resolution should be valid

  Scenario: Resolve with invalid country code
    Given I want to send a letter to country "XX"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then the resolution should be invalid
    And I should get an error about invalid country code

  Scenario: Resolve with weight exceeding maximum
    Given I want to send a letter to country "DE"
    And the letter weight is 2500 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then the resolution should be invalid
    And I should get an error about weight exceeding maximum

  Scenario: Resolve returns base price
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then the resolution should include base price
    And the base price should be a positive number
    And the resolution should include currency "EUR"
