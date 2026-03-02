Feature: Comprehensive API Testing
  As a developer
  I want to test all SDK capabilities with minimal API requests
  So that I can verify functionality across all products, zones, and services with broad coverage

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  @offline
  Scenario Outline: Pre-calculate price for all product-zone combinations
    Given I have a letter with type "<letter_type>"
    And destination country "<country_code>"
    And weight <weight> grams
    When I pre-calculate the price
    Then I should get a pre-calculated price in cents
    And the currency should be "EUR"
    And the pre-calculated price should be greater than 0
    And the price should be consistent with product and zone

    Examples:
      | letter_type | country_code | weight | zone_id     |
      | STANDARD    | DE           | 1      | domestic    |
      | STANDARD    | FR           | 1      | zone_1_eu   |
      | STANDARD    | US           | 1      | world       |
      | COMPACT     | DE           | 21     | domestic    |
      | COMPACT     | FR           | 21     | zone_1_eu   |
      | COMPACT     | US           | 21     | world       |
      | LARGE       | DE           | 51     | domestic    |
      | LARGE       | FR           | 51     | zone_1_eu   |
      | LARGE       | US           | 51     | world       |
      | MAXI        | DE           | 501    | domestic    |
      | MAXI        | FR           | 501    | zone_1_eu   |
      | MAXI        | US           | 501    | world       |
      | MERCHANDISE | DE           | 1001   | domestic    |

  @release @online @api
  Scenario Outline: Generate stamp for all product-zone combinations with API
    Given I have a letter with type "<letter_type>"
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
      | letter_type | country_code | weight | zone_id     |
      | STANDARD    | DE           | 1      | domestic    |
      | STANDARD    | FR           | 1      | zone_1_eu   |
      | STANDARD    | US           | 1      | world       |
      | COMPACT     | DE           | 21     | domestic    |
      | COMPACT     | FR           | 21     | zone_1_eu   |
      | COMPACT     | US           | 21     | world       |
      | LARGE       | DE           | 51     | domestic    |
      | LARGE       | FR           | 51     | zone_1_eu   |
      | LARGE       | US           | 51     | world       |
      | MAXI        | DE           | 501    | domestic    |
      | MAXI        | FR           | 501    | zone_1_eu   |
      | MAXI        | US           | 501    | world       |
      | MERCHANDISE | DE           | 1001   | domestic    |
