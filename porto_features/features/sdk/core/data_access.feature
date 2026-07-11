@sdk
@core
Feature: Data Access
  As a developer
  I want to access porto-data entities
  So that I can retrieve products, zones, prices, services, restrictions, envelopes, and metadata

  Background:
    Given I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: Access products data
    When I access products data
    Then I should get an array of products
    And the products array should contain product with id "standardbrief"
    And the products array should contain product with id "kompaktbrief"
    And the products array should contain product with id "grossbrief"
    And each product should have field "id"
    And each product should have field "porto_id"
    And each product should have field "name"
    And each product should have field "envelope_ids"
    And each product should have field "zones"

  Scenario: Access zones data
    When I access zones data
    Then I should get an array of zones
    And the zones array should contain zone with id "domestic"
    And the zones array should contain zone with id "zone_1_eu"
    And the zones array should contain zone with id "world"
    And each zone should have field "id"
    And each zone should have field "name"
    And each zone should have field "country_codes"

  Scenario: Access prices data
    When I access prices data
    Then I should get product prices
    And prices should have structure for product "standardbrief"
    And prices should have structure for product "kompaktbrief"
    And each price entry should have field "product_id"
    And each price entry should have field "zone"
    And each price entry should have field "weight_tier"
    And each price entry should have field "price" as array
    And each price in array should have field "price" as number
    And each price in array should have field "effective_from"
    And each price in array should have field "effective_to"

  Scenario: Access services data
    When I access services data
    Then I should get an array of services
    And the services array should contain service with id "einschreiben"
    And the services array should contain service with id "einschreiben_einwurf"
    And each service should have field "id"
    And each service should have field "porto_id"
    And each service should have field "name"
    And each service should have field "features"

  Scenario: Access restrictions data
    When I access restrictions data
    Then I should get restrictions information
    And restrictions should have field "sanctions_information"
    And restrictions should have field "denied_party_screening"
    And restrictions should have array "restrictions"
    And each restriction should have field "country_code"
    And each restriction should have field "framework_id"

  Scenario: Access envelopes data
    When I access envelopes data
    Then I should get an array of envelopes
    And the envelopes array should contain envelope with id "DL"
    And the envelopes array should contain envelope with id "C6"
    And the envelopes array should contain envelope with id "C5"
    And the envelopes array should contain envelope with id "C4"
    And each envelope should have field "id"
    And each envelope should have field "width"
    And each envelope should have field "height"

  Scenario: Access weight tiers data
    When I access weight tiers data
    Then I should get weight tiers
    And weight tiers should contain tier "W0020"
    And weight tiers should contain tier "W0050"
    And weight tiers should contain tier "W0500"
    And each weight tier should have field "min"
    And each weight tier should have field "max"
    And each weight tier should have field "label"

  Scenario: Access features data
    When I access features data
    Then I should get an array of features
    And the features array should contain feature with id "tracking_number"
    And the features array should contain feature with id "proof_of_mailing"
    And each feature should have field "id"
    And each feature should have field "porto_id"
    And each feature should have field "name"
    And each feature should have field "label"

  Scenario: Access provider registry
    When I access provider registry
    Then I should get providers information
    And providers should include provider "deutschepost"
    And providers should include provider "laposte"
    And providers should include provider "swisspost"
    And providers should include provider "ukrposhta"

  Scenario: Access integrations manifest
    When I access integrations manifest
    Then I should get integrations information
    And integrations should describe adapter capabilities
    And integrations should list adapter ids for online purchase
