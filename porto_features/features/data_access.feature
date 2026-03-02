@offline
Feature: Data Access
  As a developer
  I want to access porto-data entities
  So that I can retrieve products, zones, prices, services, restrictions, dimensions, weight tiers, and features

  Background:
    Given I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: Access products data
    When I access products data
    Then I should get an array of products
    And the products array should contain product with id "letter_standard"
    And the products array should contain product with id "letter_compact"
    And the products array should contain product with id "letter_large"
    And each product should have field "id"
    And each product should have field "name"
    And each product should have field "dimension_ids"
    And each product should have field "supported_zones"
    And each product should have field "weight_tier"

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
    And prices should have structure for product "letter_standard"
    And prices should have structure for product "letter_compact"
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
    And the services array should contain service with id "registered_mail"
    And the services array should contain service with id "registered_mail_mailbox"
    And each service should have field "id"
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

  Scenario: Access dimensions data
    When I access dimensions data
    Then I should get an array of dimensions
    And the dimensions array should contain dimension with id "DL"
    And the dimensions array should contain dimension with id "C6"
    And the dimensions array should contain dimension with id "C5"
    And the dimensions array should contain dimension with id "C4"
    And each dimension should have field "id"
    And each dimension should have field "size"
    And each dimension size should have field "width"
    And each dimension size should have field "height"
    And each dimension size should have field "thickness"

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
    And the features array should contain feature with id "delivery_confirmation"
    And each feature should have field "id"
    And each feature should have field "name"
    And each feature should have field "label"

  Scenario: Access data links metadata
    When I access data links metadata
    Then I should get data links information
    And data links should have field "dependencies"
    And data links should have field "links"
    And dependencies should describe relationships between data files
    And links should provide lookup mappings for products
