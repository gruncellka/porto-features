@adapters
Feature: Internetmarke adapter purchases
  As a developer
  I want to purchase stamps via Deutsche Post Internetmarke
  So that adapter integration and Portokasse checkout are verified

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  @canary
  Scenario: Generate stamp with pre-calculation
    Given I have a letter with porto_id "small"
    And destination country "DE"
    And weight 20 grams
    And valid destination address
    And valid origin address
    And Internetmarke credentials are configured
    When I generate a digital stamp
    Then the stamp should be generated successfully
    And the stamp should have an id
    And the stamp should have a barcode
    And the stamp should have a valid until date
    And the stamp should include pre-calculated price
    And the stamp should include final API price

  @full
  Scenario: Compare pre-calculated and API prices
    Given I have a letter with porto_id "small"
    And destination country "DE"
    And weight 20 grams
    And Internetmarke credentials are configured
    When I generate a digital stamp
    Then the system should compare pre-calculated and API prices
    And if prices match, no mismatch should be reported
    And if prices differ, a mismatch should be reported
    And the price difference should be calculated

  @full
  Scenario Outline: Generate stamp for product-zone combinations
    Given I have a letter with porto_id "<porto_id>"
    And destination country "<country_code>"
    And weight <weight> grams
    And valid destination address for country "<country_code>"
    And valid origin address
    And Internetmarke credentials are configured
    When I generate a digital stamp
    Then the stamp should be generated successfully
    And the stamp should have an id
    And the stamp should have a barcode
    And the stamp should have a qr_code
    And the stamp should have a valid until date
    And the stamp should include pre-calculated price
    And the stamp should include final API price
    And the API price should match pre-calculated price or show mismatch
    And the stamp should have an image_url
    And the stamp should have a print_format

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
