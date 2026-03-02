@offline
Feature: CLI Commands
  As a developer or integrator
  I want to use CLI commands for porto SDK
  So that I can inspect data, validate payloads, and calculate prices without writing code

  Background:
    Given I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: Display configuration
    When I call CLI config command
    Then the result should have field "data_path"
    And the result should have field "porto_data_version"

  Scenario: Show porto-data information
    When I call CLI data info command
    Then the result should have field "version"
    And the result should have field "generated_at"
    And the result should have field "entities"

  Scenario: List available products
    When I call CLI data products command
    Then the result should have array "products"
    And the products array should contain product with id "letter_standard"
    And the products array should contain product with id "letter_compact"
    And the products array should contain product with id "letter_large"

  Scenario: List available zones
    When I call CLI data zones command
    Then the result should have array "zones"
    And the zones array should contain zone with id "domestic"
    And the zones array should contain zone with id "zone_1_eu"
    And the zones array should contain zone with id "world"

  Scenario: List available services
    When I call CLI data services command
    Then the result should have array "services"
    And the services array should contain service with id "registered_mail"
    And the services array should contain service with id "registered_mail_mailbox"

  Scenario: Get price for product-zone-weight combination
    When I call CLI data price command with product "letter_standard" zone "zone_1_eu" weight 20
    Then the result should have field "product" with value "letter_standard"
    And the result should have field "zone" with value "zone_1_eu"
    And the result should have field "weight" with value 20
    And the result should have field "price" as number
    And the result should have field "currency" with value "EUR"

  Scenario: Calculate price for domestic standard letter
    When I call CLI price command with type "STANDARD" country "DE" weight 20
    Then the result should have field "product" with nested "id" "letter_standard"
    And the result should have field "zone" with nested "id" "domestic"
    And the result should have field "base_price" as number
    And the result should have field "currency" with value "EUR"
    And the result should have field "is_valid" with value true

  Scenario: Calculate price for international letter
    When I call CLI price command with type "STANDARD" country "US" weight 20
    Then the result should have field "product"
    And the result should have field "zone" with nested "id" "world"
    And the result should have field "base_price" as number
    And the result should have field "currency" with value "EUR"

  Scenario: Simulate stamp generation
    When I call CLI stamp simulate command with type "STANDARD" country "DE" weight 20
    Then the result should have field "simulation" with value true
    And the result should have field "product" with nested "id" "letter_standard"
    And the result should have field "price" as number
    And the result should have field "valid" as boolean

  Scenario: Validate letter from JSON data
    Given I have a valid letter JSON data
    When I call CLI validate letter command
    Then the result should have field "valid" with value true
    And the result should have field "errors" as array

  Scenario: Validate invalid letter from JSON data
    Given I have an invalid letter JSON data
    When I call CLI validate letter command
    Then the result should have field "valid" with value false
    And the result should have field "errors" as array
    And the errors array should not be empty

  Scenario: Validate address from JSON data
    Given I have a valid address JSON data
    When I call CLI validate address command
    Then the result should have field "valid" with value true
    And the result should have field "errors" as array

  Scenario: Check restrictions for country
    When I call CLI restrictions command with country "DE"
    Then the result should have field "restricted" with value false
    And the result should have field "restrictions" as array

  Scenario: CLI commands produce identical results for price
    When I call CLI price command with type "STANDARD" country "DE" weight 20
    Then the result should be stored for comparison
    When I call CLI price command with type "STANDARD" country "DE" weight 20
    Then the results should be identical

  Scenario: CLI commands produce identical results for data price
    When I call CLI data price command with product "letter_standard" zone "zone_1_eu" weight 20
    Then the result should be stored for comparison
    When I call CLI data price command with product "letter_standard" zone "zone_1_eu" weight 20
    Then the results should be identical

  Scenario: CLI commands produce identical results for config
    When I call CLI config command
    Then the result should be stored for comparison
    When I call CLI config command
    Then the results should have same structure
    And the "data_path" fields should match
