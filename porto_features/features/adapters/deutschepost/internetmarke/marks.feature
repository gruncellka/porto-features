@adapters
@provider:deutschepost
@wire:internetmarke
Feature: Internetmarke adapter mark purchases
  As a developer
  I want to purchase PortoMarks via Deutsche Post Internetmarke
  So that wire execution and Portokasse mark purchase are verified

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  @canary
  Scenario: Purchase mark with pricing
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And valid destination address
    And valid origin address
    And Internetmarke credentials are configured
    When I create a mark
    Then the mark should be created successfully
    And the mark should have an id

  @heavy
  Scenario Outline: mark_order
    Given product id is "<product_id>"
    And zone id is "<zone_id>"
    And I want to send a letter to country "<country_code>"
    And the letter weight is <weight> grams
    And service ids are "<service_ids>"
    And valid destination address for country "<country_code>"
    And valid origin address
    And Internetmarke credentials are configured
    When I create a mark
    Then the mark should be created successfully
    And the mark should have an id

    Examples:
      | product_id | zone_id | country_code | weight | service_ids |
      | grossbrief | domestic | DE | 100 | none |
      | grossbrief | domestic | DE | 100 | einschreiben |
      | grossbrief | domestic | DE | 100 | einschreiben_einwurf |
      | grossbrief | domestic | DE | 100 | einschreiben_rueckschein |
      | grossbrief | world | US | 100 | none |
      | grossbrief | world | US | 100 | einschreiben |
      | grossbrief | zone_1_eu | FR | 100 | none |
      | grossbrief | zone_1_eu | FR | 100 | einschreiben |
      | grossbrief | zone_2_europe | UA | 100 | none |
      | grossbrief | zone_2_europe | UA | 100 | einschreiben |
      | kompaktbrief | domestic | DE | 50 | none |
      | kompaktbrief | domestic | DE | 50 | einschreiben |
      | kompaktbrief | domestic | DE | 50 | einschreiben_einwurf |
      | kompaktbrief | domestic | DE | 50 | einschreiben_rueckschein |
      | kompaktbrief | world | US | 50 | none |
      | kompaktbrief | world | US | 50 | einschreiben |
      | kompaktbrief | zone_1_eu | FR | 50 | none |
      | kompaktbrief | zone_1_eu | FR | 50 | einschreiben |
      | kompaktbrief | zone_2_europe | UA | 50 | none |
      | kompaktbrief | zone_2_europe | UA | 50 | einschreiben |
      | maxibrief | domestic | DE | 1000 | none |
      | maxibrief | domestic | DE | 1000 | einschreiben |
      | maxibrief | domestic | DE | 1000 | einschreiben_einwurf |
      | maxibrief | domestic | DE | 1000 | einschreiben_rueckschein |
      | maxibrief | world | US | 1000 | none |
      | maxibrief | world | US | 1000 | einschreiben |
      | maxibrief | zone_1_eu | FR | 1000 | none |
      | maxibrief | zone_1_eu | FR | 1000 | einschreiben |
      | maxibrief | zone_2_europe | UA | 1000 | none |
      | maxibrief | zone_2_europe | UA | 1000 | einschreiben |
      | maxibrief_ausland | world | US | 2000 | none |
      | maxibrief_ausland | world | US | 2000 | einschreiben |
      | maxibrief_ausland | zone_1_eu | FR | 2000 | none |
      | maxibrief_ausland | zone_1_eu | FR | 2000 | einschreiben |
      | maxibrief_ausland | zone_2_europe | UA | 2000 | none |
      | maxibrief_ausland | zone_2_europe | UA | 2000 | einschreiben |
      | standardbrief | domestic | DE | 20 | none |
      | standardbrief | domestic | DE | 20 | einschreiben |
      | standardbrief | domestic | DE | 20 | einschreiben_einwurf |
      | standardbrief | domestic | DE | 20 | einschreiben_rueckschein |
      | standardbrief | world | US | 20 | none |
      | standardbrief | world | US | 20 | einschreiben |
      | standardbrief | zone_1_eu | FR | 20 | none |
      | standardbrief | zone_1_eu | FR | 20 | einschreiben |
      | standardbrief | zone_2_europe | UA | 20 | none |
      | standardbrief | zone_2_europe | UA | 20 | einschreiben |

  @heavy
  Scenario: Purchase three equivalent domestic base marks
    Given a resolved stamp Porto covering "domestic base"
    And Internetmarke credentials are configured
    When I create three equivalent marks together
    Then three marks should be returned
    And every returned mark should have an id
    And the returned mark ids should be distinct
    And the returned marks should share one external id

  @heavy
  Scenario: Purchase three equivalent other-zone service marks
    Given a resolved stamp Porto covering "other-zone + service"
    And Internetmarke credentials are configured
    When I create three equivalent marks together
    Then three marks should be returned
    And every returned mark should have an id
    And the returned mark ids should be distinct
    And the returned marks should share one external id

  @heavy
  Scenario: Purchase three equivalent feature-bearing marks
    Given a resolved stamp Porto covering "feature-bearing"
    And Internetmarke credentials are configured
    When I create three equivalent marks together
    Then three marks should be returned
    And every returned mark should have an id
    And the returned mark ids should be distinct
    And the returned marks should share one external id
