@sdk
@provider:deutschepost
Feature: Pricing
  As a developer
  I want Deutsche Post quotes through price()
  So that catalog amounts match resolved Portos

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Get price for domestic 20 g
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I get the price
    Then the quoted amount should be 95
    And the quoted product id should be "standardbrief"
    And the resolved zone id should be "domestic"
    And the currency should be "EUR"
    And the quoted components should sum to the quoted amount

  Scenario: Get price for EU 20 g
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    When I get the price
    Then the quoted amount should be 125
    And the quoted product id should be "standardbrief"
    And the resolved zone id should be "zone_1_eu"
    And the currency should be "EUR"

  Scenario: Get price for world 20 g
    Given I want to send a letter to country "US"
    And the letter weight is 20 grams
    When I get the price
    Then the quoted amount should be 125
    And the quoted product id should be "standardbrief"
    And the resolved zone id should be "world"
    And the currency should be "EUR"

  Scenario: Get price for 30 g domestic
    Given I want to send a letter to country "DE"
    And the letter weight is 30 grams
    When I get the price
    Then the quoted amount should be 110
    And the quoted product id should be "kompaktbrief"
    And the resolved zone id should be "domestic"
    And the currency should be "EUR"

  Scenario: Get price for 100 g domestic
    Given I want to send a letter to country "DE"
    And the letter weight is 100 grams
    When I get the price
    Then the quoted amount should be 180
    And the quoted product id should be "grossbrief"
    And the resolved zone id should be "domestic"
    And the currency should be "EUR"

  Scenario: Get price for 501 g domestic
    Given I want to send a letter to country "DE"
    And the letter weight is 501 grams
    When I get the price
    Then the quoted amount should be 290
    And the quoted product id should be "maxibrief"
    And the resolved zone id should be "domestic"
    And the currency should be "EUR"

  Scenario: Price is consistent
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I get the price
    Then I should store the result
    When I get the price again with the same parameters
    Then the prices should be identical

  Scenario Outline: Public price derives zone from country
    Given I want to send a letter to country "<country_code>"
    And the letter weight is <weight> grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be greater than 0
    And the resolved zone id should be "<expected_zone>"

    Examples:
      | country_code | weight | expected_zone   |
      | DE           | 1      | domestic        |
      | FR           | 1      | zone_1_eu       |
      | US           | 1      | world           |
      | DE           | 21     | domestic        |
      | FR           | 21     | zone_1_eu       |
      | US           | 21     | world           |
      | DE           | 51     | domestic        |
      | FR           | 51     | zone_1_eu       |
      | US           | 51     | world           |
      | DE           | 501    | domestic        |
      | FR           | 501    | zone_1_eu       |
      | US           | 501    | world           |
      | FR           | 1001   | zone_1_eu       |
      | US           | 1001   | world           |
      | UA           | 1      | zone_2_europe   |
      | UA           | 21     | zone_2_europe   |
      | UA           | 51     | zone_2_europe   |
      | UA           | 501    | zone_2_europe   |
      | UA           | 1001   | zone_2_europe   |
