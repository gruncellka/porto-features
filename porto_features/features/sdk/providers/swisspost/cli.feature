@sdk
@provider:swisspost
Feature: Swiss Post CLI catalog
  Provider-native CLI inventory and public price output for Swiss Post.

  Background:
    Given provider is "swisspost"
    And I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: [swisspost] Display configuration
    When I call CLI config command
    Then the result should have field "provider" with value "swisspost"
    And the result should have field "data_path"

  Scenario: [swisspost] List available products
    When I call CLI data products command
    Then the result should have array "products"
    And the products array should contain product with id "a_post_standardbrief"
    And the products array should contain product with id "b_post_standardbrief"

  Scenario: [swisspost] List available zones
    When I call CLI data zones command
    Then the result should have array "zones"
    And the zones array should contain zone with id "domestic"
    And the zones array should contain zone with id "zone_1_eu"
    And the zones array should contain zone with id "world"

  Scenario: [swisspost] List available services
    When I call CLI data services command
    Then the result should have array "services"
    And the services array should contain service with id "a_mail_plus"
    And the services array should contain service with id "zuschlag_dicke"

  Scenario: [swisspost] Catalog data price row for product-zone-weight
    When I call CLI data price command with product "a_post_standardbrief" zone "domestic" weight 20
    Then the result should have field "product" with value "a_post_standardbrief"
    And the result should have field "zone" with value "domestic"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "CHF"

  Scenario: [swisspost] Get price for domestic 20 g
    Given product id is "a_post_standardbrief"
    When I call CLI price command with country "CH" weight 20
    Then the result should have field "product" with nested "id" "a_post_standardbrief"
    And the result should have field "zone" with nested "id" "domestic"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "CHF"
    And the result should have field "is_valid" with value true

  Scenario: [swisspost] Get price for international letter
    When I call CLI price command with country "US" weight 20
    Then the result should have field "product"
    And the result should have field "zone" with nested "id" "world"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "CHF"

  Scenario: [swisspost] CLI commands produce identical results for price
    Given product id is "a_post_standardbrief"
    When I call CLI price command with country "CH" weight 20
    Then the result should be stored for comparison
    When I call CLI price command with country "CH" weight 20
    Then the results should be identical

  Scenario: [swisspost] CLI commands produce identical results for data price
    When I call CLI data price command with product "a_post_standardbrief" zone "domestic" weight 20
    Then the result should be stored for comparison
    When I call CLI data price command with product "a_post_standardbrief" zone "domestic" weight 20
    Then the results should be identical

  Scenario: [swisspost] CLI commands produce identical results for config
    When I call CLI config command
    Then the result should be stored for comparison
    When I call CLI config command
    Then the results should have same structure
    And the "data_path" fields should match
