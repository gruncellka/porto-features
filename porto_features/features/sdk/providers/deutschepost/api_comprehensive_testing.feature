@sdk
@operator:deutschepost
Feature: Comprehensive API Testing
  As a developer
  I want to test all SDK capabilities with minimal API requests
  So that I can verify functionality across products, zones, and services with broad coverage

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario Outline: Pre-calculate price for product-zone combinations
    Given I have a letter with porto_id "<porto_id>"
    And zone id is "<zone_id>"
    And I want to send a letter to country "<country_code>"
    And the letter weight is <weight> grams
    When I pre-calculate the price
    Then I should get a pre-calculated price in cents
    And the currency should be "EUR"
    And the pre-calculated price should be greater than 0
    And the price should be consistent with product and zone

    Examples:
      | porto_id     | country_code | weight | zone_id       |
      | small        | DE           | 1      | domestic      |
      | small        | FR           | 1      | zone_1_eu     |
      | small        | US           | 1      | world         |
      | medium       | DE           | 21     | domestic      |
      | medium       | FR           | 21     | zone_1_eu     |
      | medium       | US           | 21     | world         |
      | large        | DE           | 51     | domestic      |
      | large        | FR           | 51     | zone_1_eu     |
      | large        | US           | 51     | world         |
      | extra_large  | DE           | 501    | domestic      |
      | extra_large  | FR           | 501    | zone_1_eu     |
      | extra_large  | US           | 501    | world         |
      | extra_large  | FR           | 1001   | zone_1_eu     |
      | extra_large  | US           | 1001   | world         |
      | small        | UA           | 1      | zone_2_europe |
      | medium       | UA           | 21     | zone_2_europe |
      | large        | UA           | 51     | zone_2_europe |
      | extra_large  | UA           | 501    | zone_2_europe |
      | extra_large  | UA           | 1001   | zone_2_europe |
