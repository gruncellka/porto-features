@sdk
@operator:deutschepost
Feature: Deutsche Post resolution
  As a developer
  I want to resolve product, zone, and weight tier from country code and porto_id
  So that I can determine the correct product and zone for a letter

  Rule: Happy-path resolution by zone and porto_id
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

  Scenario: Resolve domestic letter
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve EU zone letter
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "zone_1_eu"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve world zone letter
    Given I want to send a letter to country "US"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "world"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve zone 2 europe letter
    Given I want to send a letter to country "UA"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "zone_2_europe"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve medium letter for mid weight
    Given I want to send a letter to country "DE"
    And the letter weight is 30 grams
    And the letter porto_id is "medium"
    When I resolve the letter
    Then I should get product with id "kompaktbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0050"
    And the resolution should be valid

  Scenario: Resolve large letter for upper domestic weight
    Given I want to send a letter to country "DE"
    And the letter weight is 100 grams
    And the letter porto_id is "large"
    When I resolve the letter
    Then I should get product with id "grossbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0500"
    And the resolution should be valid

  Scenario: Resolve extra large letter
    Given I want to send a letter to country "DE"
    And the letter weight is 501 grams
    And the letter porto_id is "extra_large"
    When I resolve the letter
    Then I should get product with id "maxibrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W1000"
    And the resolution should be valid

  Scenario: Resolve extra large international letter
    Given I want to send a letter to country "FR"
    And the letter weight is 1700 grams
    And the letter porto_id is "extra_large"
    When I resolve the letter
    Then I should get product with id "maxibrief_ausland"
    And I should get zone with id "zone_1_eu"
    And I should get weight tier "W2000"
    And the resolution should be valid

  Rule: Resolution error handling
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

  Scenario: Resolve with invalid country code
    Given I want to send a letter to country "XX"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get an error about invalid country code

  Scenario: Resolve with weight exceeding maximum
    Given I want to send a letter to country "DE"
    And the letter weight is 2500 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get an error about weight exceeding maximum

  Rule: Resolution pricing metadata
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

  Scenario: Resolve returns base price
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then the resolution should include base price
    And the base price should be a positive number
    And the resolution should include currency "EUR"
