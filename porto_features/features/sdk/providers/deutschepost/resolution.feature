@sdk
@provider:deutschepost
Feature: Deutsche Post resolution
  As a developer
  I want Deutsche Post catalog facts to map onto the public resolve contract

  Rule: Happy-path resolution by zone and weight
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

  Scenario: Resolve 20 g domestic to standardbrief
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve 20 g to France as zone_1_eu
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "zone_1_eu"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve 20 g to the United States as world
    Given I want to send a letter to country "US"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "world"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve 20 g to Ukraine as zone_2_europe
    Given I want to send a letter to country "UA"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And I should get zone with id "zone_2_europe"
    And I should get weight tier "W0020"
    And the resolution should be valid

  Scenario: Resolve 30 g domestic to kompaktbrief
    Given I want to send a letter to country "DE"
    And the letter weight is 30 grams
    When I resolve the letter
    Then I should get product with id "kompaktbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0050"
    And the resolution should be valid

  Scenario: Resolve 100 g domestic to grossbrief
    Given I want to send a letter to country "DE"
    And the letter weight is 100 grams
    When I resolve the letter
    Then I should get product with id "grossbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0500"
    And the resolution should be valid

  Scenario: Resolve 501 g domestic to maxibrief
    Given I want to send a letter to country "DE"
    And the letter weight is 501 grams
    When I resolve the letter
    Then I should get product with id "maxibrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W1000"
    And the resolution should be valid

  Scenario: Resolve 1700 g to France as maxibrief_ausland
    Given I want to send a letter to country "FR"
    And the letter weight is 1700 grams
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
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_DESTINATION_INVALID"

  Scenario: Resolve with weight exceeding maximum
    Given I want to send a letter to country "DE"
    And the letter weight is 2500 grams
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_TOO_HEAVY"

  Rule: Resolution quote
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

  Scenario: Resolve returns amount
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then the resolved amount should be a positive number
    And the resolution should include currency "EUR"

  Scenario: Domestic delivery hint
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And delivery hint span should be "between"
    And delivery hint days max should be 2
    And delivery hint weekdays should be "mon_sat"
