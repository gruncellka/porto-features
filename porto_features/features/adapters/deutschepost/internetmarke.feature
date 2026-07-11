@adapters
@operator:deutschepost
@wire:internetmarke
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
    And I want to send a letter to country "DE"
    And the letter weight is 20 grams
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
    And I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And Internetmarke credentials are configured
    When I generate a digital stamp
    Then the system should compare pre-calculated and API prices
    And if prices match, no mismatch should be reported
    And if prices differ, a mismatch should be reported
    And the price difference should be calculated

  @full
  Scenario Outline: stamp_order
    Given product id is "<product_id>"
    And zone id is "<zone_id>"
    And I want to send a letter to country "<country_code>"
    And the letter weight is <weight> grams
    And service ids are "<service_ids>"
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
      | product_id | zone_id | country_code | weight | service_ids |
      | grossbrief | domestic | DE | 1 |  |
      | grossbrief | domestic | DE | 1 | einschreiben |
      | grossbrief | domestic | DE | 1 | einschreiben_einwurf |
      | grossbrief | domestic | DE | 1 | einschreiben_rueckschein |
      | grossbrief | world | US | 1 |  |
      | grossbrief | world | US | 1 | einschreiben |
      | grossbrief | zone_1_eu | FR | 1 |  |
      | grossbrief | zone_1_eu | FR | 1 | einschreiben |
      | grossbrief | zone_2_europe | UA | 1 |  |
      | grossbrief | zone_2_europe | UA | 1 | einschreiben |
      | kompaktbrief | domestic | DE | 1 |  |
      | kompaktbrief | domestic | DE | 1 | einschreiben |
      | kompaktbrief | domestic | DE | 1 | einschreiben_einwurf |
      | kompaktbrief | domestic | DE | 1 | einschreiben_rueckschein |
      | kompaktbrief | world | US | 1 |  |
      | kompaktbrief | world | US | 1 | einschreiben |
      | kompaktbrief | zone_1_eu | FR | 1 |  |
      | kompaktbrief | zone_1_eu | FR | 1 | einschreiben |
      | kompaktbrief | zone_2_europe | UA | 1 |  |
      | kompaktbrief | zone_2_europe | UA | 1 | einschreiben |
      | maxibrief | domestic | DE | 1 |  |
      | maxibrief | domestic | DE | 1 | einschreiben |
      | maxibrief | domestic | DE | 1 | einschreiben_einwurf |
      | maxibrief | domestic | DE | 1 | einschreiben_rueckschein |
      | maxibrief | world | US | 1 |  |
      | maxibrief | world | US | 1 | einschreiben |
      | maxibrief | zone_1_eu | FR | 1 |  |
      | maxibrief | zone_1_eu | FR | 1 | einschreiben |
      | maxibrief | zone_2_europe | UA | 1 |  |
      | maxibrief | zone_2_europe | UA | 1 | einschreiben |
      | maxibrief_ausland | world | US | 1 |  |
      | maxibrief_ausland | world | US | 1 | einschreiben |
      | maxibrief_ausland | zone_1_eu | FR | 1 |  |
      | maxibrief_ausland | zone_1_eu | FR | 1 | einschreiben |
      | maxibrief_ausland | zone_2_europe | UA | 1 |  |
      | maxibrief_ausland | zone_2_europe | UA | 1 | einschreiben |
      | standardbrief | domestic | DE | 1 |  |
      | standardbrief | domestic | DE | 1 | einschreiben |
      | standardbrief | domestic | DE | 1 | einschreiben_einwurf |
      | standardbrief | domestic | DE | 1 | einschreiben_rueckschein |
      | standardbrief | world | US | 1 |  |
      | standardbrief | world | US | 1 | einschreiben |
      | standardbrief | zone_1_eu | FR | 1 |  |
      | standardbrief | zone_1_eu | FR | 1 | einschreiben |
      | standardbrief | zone_2_europe | UA | 1 |  |
      | standardbrief | zone_2_europe | UA | 1 | einschreiben |
