@sdk
@operator:deutschepost
Feature: Pricing matrix
  As a developer
  I want to price letters across products, zones, and weights
  So that I can verify coverage without carrier purchase

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario Outline: Get price for product-zone combinations
    Given zone id is "<zone_id>"
    And I want to send a letter to country "<country_code>"
    And the letter weight is <weight> grams
    When I get the price
    Then I should get a price in cents
    And the currency should be "EUR"
    And the price should be greater than 0
    And the price should be consistent with product and zone

    Examples:
      | country_code | weight | zone_id       |
      | DE | 1 | domestic |
      | FR | 1 | zone_1_eu |
      | US | 1 | world |
      | DE | 21 | domestic |
      | FR | 21 | zone_1_eu |
      | US | 21 | world |
      | DE | 51 | domestic |
      | FR | 51 | zone_1_eu |
      | US | 51 | world |
      | DE | 501 | domestic |
      | FR | 501 | zone_1_eu |
      | US | 501 | world |
      | FR | 1001 | zone_1_eu |
      | US | 1001 | world |
      | UA | 1 | zone_2_europe |
      | UA | 21 | zone_2_europe |
      | UA | 51 | zone_2_europe |
      | UA | 501 | zone_2_europe |
      | UA | 1001 | zone_2_europe |
