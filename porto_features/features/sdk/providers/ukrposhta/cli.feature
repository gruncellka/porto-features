@sdk
@provider:ukrposhta
Feature: Ukrposhta CLI catalog
  Provider-native CLI inventory and public price output for Ukrposhta.
  Data-price scenarios pin a catalog product and map zone → example country through public price().

  Background:
    Given provider is "ukrposhta"
    And I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: [ukrposhta] Display configuration
    When I call CLI config command
    Then the result should have field "provider" with value "ukrposhta"
    And the result should have field "data_path"

  Scenario: [ukrposhta] List available products
    When I call CLI data products command
    Then the result should have array "products"
    And the products array should contain product with id "lyst_standartnyi"
    And the products array should contain product with id "dokument"

  Scenario: [ukrposhta] List available zones
    When I call CLI data zones command
    Then the result should have array "zones"
    And the zones array should contain zone with id "domestic"
    And the zones array should contain zone with id "world"

  Scenario: [ukrposhta] List available services
    When I call CLI data services command
    Then the result should have array "services"
    And the services array should contain service with id "mizhnarodne_zareiestrovane"
    And the services array should contain service with id "paperove_povidomlennia_vruchennia"

  Scenario: [ukrposhta] Public price for product via zone example country
    When I call CLI data price command with product "lyst_standartnyi" zone "domestic" weight 20
    Then the result should have field "product" with value "lyst_standartnyi"
    And the result should have field "zone" with value "domestic"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "UAH"

  Scenario: [ukrposhta] Get price for domestic 20 g
    When I call CLI price command with country "UA" weight 20
    Then the result should have field "product" with nested "id" "lyst_standartnyi"
    And the result should have field "zone" with nested "id" "domestic"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "UAH"
    And the result should have field "is_valid" with value true

  Scenario: [ukrposhta] Get price for international letter
    When I call CLI price command with country "US" weight 20
    Then the result should have field "product"
    And the result should have field "zone" with nested "id" "world"
    And the result should have field "amount" as number
    And the result should have field "currency" with value "USD"

  Scenario: [ukrposhta] CLI commands produce identical results for price
    When I call CLI price command with country "UA" weight 20
    Then the result should be stored for comparison
    When I call CLI price command with country "UA" weight 20
    Then the results should be identical

  Scenario: [ukrposhta] CLI commands produce identical results for data price
    When I call CLI data price command with product "lyst_standartnyi" zone "domestic" weight 20
    Then the result should be stored for comparison
    When I call CLI data price command with product "lyst_standartnyi" zone "domestic" weight 20
    Then the results should be identical

  Scenario: [ukrposhta] CLI commands produce identical results for config
    When I call CLI config command
    Then the result should be stored for comparison
    When I call CLI config command
    Then the results should have same structure
    And the "data_path" fields should match
