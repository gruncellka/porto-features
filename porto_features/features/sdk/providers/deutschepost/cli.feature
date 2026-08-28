@sdk
@provider:deutschepost
Feature: Deutsche Post CLI catalog
  Provider-native CLI inventory and public price output for Deutsche Post.
  Catalog data price rows use field "price" (product + zone + weight). Public quote CLI uses "amount".

  Background:
    Given provider is "deutschepost"
    And I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: [deutschepost] Display configuration
    When I call CLI config command
    Then the result should have field "provider" with value "deutschepost"
    And the result should have field "data_path"

  Scenario: [deutschepost] List available products
    When I call CLI data products command
    Then the result should have array "products"
    And the products array should contain product with id "standardbrief"
    And the products array should contain product with id "kompaktbrief"

  Scenario: [deutschepost] List available zones
    When I call CLI data zones command
    Then the result should have array "zones"
    And the zones array should contain zone with id "domestic"
    And the zones array should contain zone with id "zone_1_eu"
    And the zones array should contain zone with id "world"

  Scenario: [deutschepost] List available services
    When I call CLI data services command
    Then the result should have array "services"
    And the services array should contain service with id "einschreiben"
    And the services array should contain service with id "einschreiben_einwurf"

  Scenario: [deutschepost] Catalog data price row for product-zone-weight
    When I call CLI data price command with product "standardbrief" zone "zone_1_eu" weight 20
    Then the result should have field "product" with value "standardbrief"
    And the result should have field "zone" with value "zone_1_eu"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "EUR"

  Scenario: [deutschepost] Get price for domestic 20 g
    When I call CLI price command with country "DE" weight 20
    Then the result should have field "product" with nested "id" "standardbrief"
    And the result should have field "zone" with nested "id" "domestic"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "EUR"
    And the result should have field "is_valid" with value true

  Scenario: [deutschepost] Get price for international letter
    When I call CLI price command with country "US" weight 20
    Then the result should have field "product"
    And the result should have field "zone" with nested "id" "world"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "EUR"

  Scenario: [deutschepost] CLI commands produce identical results for price
    When I call CLI price command with country "DE" weight 20
    Then the result should be stored for comparison
    When I call CLI price command with country "DE" weight 20
    Then the results should be identical

  Scenario: [deutschepost] CLI commands produce identical results for data price
    When I call CLI data price command with product "standardbrief" zone "zone_1_eu" weight 20
    Then the result should be stored for comparison
    When I call CLI data price command with product "standardbrief" zone "zone_1_eu" weight 20
    Then the results should be identical

  Scenario: [deutschepost] CLI commands produce identical results for config
    When I call CLI config command
    Then the result should be stored for comparison
    When I call CLI config command
    Then the results should have same structure
    And the "data_path" fields should match
