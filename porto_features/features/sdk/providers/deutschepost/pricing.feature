@sdk
@operator:deutschepost
Feature: Pricing
  As a developer
  I want to get prices for letters
  So that I can determine the price

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Get price for domestic small letter
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be greater than 0

  Scenario: Get price for EU zone small letter
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than domestic price

  Scenario: Get price for world zone small letter
    Given I want to send a letter to country "US"
    And the letter weight is 20 grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than domestic price

  Scenario: Get price for medium letter
    Given I want to send a letter to country "DE"
    And the letter weight is 30 grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than small letter price

  Scenario: Get price for large letter
    Given I want to send a letter to country "DE"
    And the letter weight is 100 grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than medium letter price

  Scenario: Get price for extra large letter
    Given I want to send a letter to country "DE"
    And the letter weight is 501 grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than large letter price

  Scenario: Get price by product, zone, and weight
    Given I have product "standardbrief"
    And I have zone "zone_1_eu"
    And I have weight 20 grams
    When I get the price
    Then I should get a price in cents
    And the result should have field "product" with value "standardbrief"
    And the result should have field "zone" with value "zone_1_eu"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "EUR"

  Scenario: Price is consistent
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I get the price
    Then I should store the result
    When I get the price again with the same parameters
    Then the prices should be identical
