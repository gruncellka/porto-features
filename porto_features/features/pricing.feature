@offline
Feature: Pricing
  As a developer
  I want to calculate prices for letters
  So that I can determine shipping costs

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Calculate price for domestic standard letter
    Given I have a letter with type "STANDARD"
    And the destination country is "DE"
    And the weight is 20 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be greater than 0

  Scenario: Calculate price for EU zone standard letter
    Given I have a letter with type "STANDARD"
    And the destination country is "FR"
    And the weight is 20 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than domestic price

  Scenario: Calculate price for world zone standard letter
    Given I have a letter with type "STANDARD"
    And the destination country is "US"
    And the weight is 20 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than domestic price

  Scenario: Calculate price for compact letter
    Given I have a letter with type "COMPACT"
    And the destination country is "DE"
    And the weight is 30 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than standard letter price

  Scenario: Calculate price for large letter
    Given I have a letter with type "LARGE"
    And the destination country is "DE"
    And the weight is 100 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than compact letter price

  Scenario: Calculate price for maxi letter
    Given I have a letter with type "MAXI"
    And the destination country is "DE"
    And the weight is 500 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be higher than large letter price

  Scenario: Calculate price for merchandise letter
    Given I have a letter with type "MERCHANDISE"
    And the destination country is "DE"
    And the weight is 1000 grams
    When I calculate the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be greater than 0

  Scenario: Get price by product, zone, and weight
    Given I have product "letter_standard"
    And I have zone "zone_1_eu"
    And I have weight 20 grams
    When I get the price
    Then I should get a price in cents
    And the result should have field "product" with value "letter_standard"
    And the result should have field "zone" with value "zone_1_eu"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "EUR"

  Scenario: Price calculation is consistent
    Given I have a letter with type "STANDARD"
    And the destination country is "DE"
    And the weight is 20 grams
    When I calculate the price
    Then I should store the result
    When I calculate the price again with the same parameters
    Then the prices should be identical
