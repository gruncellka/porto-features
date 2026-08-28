@sdk
@provider:laposte
Feature: La Poste CLI catalog
  Provider-native CLI inventory and public price output for La Poste.

  Background:
    Given provider is "laposte"
    And delivery preference is "cheapest"
    And I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: [laposte] Display configuration
    When I call CLI config command
    Then the result should have field "provider" with value "laposte"
    And the result should have field "data_path"

  Scenario: [laposte] List available products
    When I call CLI data products command
    Then the result should have array "products"
    And the products array should contain product with id "lettre_verte"
    And the products array should contain product with id "lettre_verte_suivie"

  Scenario: [laposte] List available zones
    When I call CLI data zones command
    Then the result should have array "zones"
    And the zones array should contain zone with id "domestic"
    And the zones array should contain zone with id "zone_1_eu"
    And the zones array should contain zone with id "world"

  Scenario: [laposte] List available services
    When I call CLI data services command
    Then the result should have array "services"
    And the services array should contain service with id "option_suivi"
    And the services array should contain service with id "avis_de_reception_national"

  Scenario: [laposte] Catalog data price row for product-zone-weight
    When I call CLI data price command with product "lettre_verte" zone "domestic" weight 20
    Then the result should have field "product" with value "lettre_verte"
    And the result should have field "zone" with value "domestic"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "EUR"

  Scenario: [laposte] Get price for domestic 20 g
    Given product id is "lettre_verte"
    When I call CLI price command with country "FR" weight 20
    Then the result should have field "product" with nested "id" "lettre_verte"
    And the result should have field "zone" with nested "id" "domestic"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "EUR"
    And the result should have field "is_valid" with value true

  Scenario: [laposte] Get price for international letter
    When I call CLI price command with country "US" weight 20
    Then the result should have field "product"
    And the result should have field "zone" with nested "id" "world"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "EUR"

  Scenario: [laposte] CLI commands produce identical results for price
    Given product id is "lettre_verte"
    When I call CLI price command with country "FR" weight 20
    Then the result should be stored for comparison
    When I call CLI price command with country "FR" weight 20
    Then the results should be identical

  Scenario: [laposte] CLI commands produce identical results for data price
    When I call CLI data price command with product "lettre_verte" zone "domestic" weight 20
    Then the result should be stored for comparison
    When I call CLI data price command with product "lettre_verte" zone "domestic" weight 20
    Then the results should be identical

  Scenario: [laposte] CLI commands produce identical results for config
    When I call CLI config command
    Then the result should be stored for comparison
    When I call CLI config command
    Then the results should have same structure
    And the "data_path" fields should match
