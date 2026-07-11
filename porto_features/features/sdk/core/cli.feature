@sdk
@core
Feature: CLI Commands
  As a developer or integrator
  I want to use CLI commands for porto SDK
  So that I can inspect data, validate payloads, and calculate prices without writing code

  Rule: Provider-neutral commands
    Background:
      Given I have porto-data available
      And I have a Porto SDK client initialized

    Scenario: Show porto-data information
      When I call CLI data info command
      Then the result should have field "version"
      And the result should have field "generated_at"
      And the result should have field "entities"

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

  Rule: Deutsche Post CLI
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

    Scenario: [deutschepost] Get price for product-zone-weight combination
      When I call CLI data price command with product "standardbrief" zone "zone_1_eu" weight 20
      Then the result should have field "product" with value "standardbrief"
      And the result should have field "zone" with value "zone_1_eu"
      And the result should have field "weight" with value 20
      And the result should have field "price" as number
      And the result should have field "currency" with value "EUR"

    Scenario: [deutschepost] Calculate price for domestic small letter
      When I call CLI price command with porto_id "small" country "DE" weight 20
      Then the result should have field "product" with nested "id" "standardbrief"
      And the result should have field "zone" with nested "id" "domestic"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "EUR"
      And the result should have field "is_valid" with value true

    Scenario: [deutschepost] Calculate price for international letter
      When I call CLI price command with porto_id "small" country "US" weight 20
      Then the result should have field "product"
      And the result should have field "zone" with nested "id" "world"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "EUR"

    Scenario: [deutschepost] Simulate stamp generation
      When I call CLI stamp simulate command with porto_id "small" country "DE" weight 20
      Then the result should have field "simulation" with value true
      And the result should have field "product" with nested "id" "standardbrief"
      And the result should have field "price" as number
      And the result should have field "valid" as boolean

    Scenario: [deutschepost] Check restrictions for home country
      When I call CLI restrictions command with country "DE"
      Then the result should have field "restricted" with value false
      And the result should have field "restrictions" as array

    Scenario: [deutschepost] CLI commands produce identical results for price
      When I call CLI price command with porto_id "small" country "DE" weight 20
      Then the result should be stored for comparison
      When I call CLI price command with porto_id "small" country "DE" weight 20
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

  Rule: La Poste CLI
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

    Scenario: [laposte] Get price for product-zone-weight combination
      When I call CLI data price command with product "lettre_verte" zone "domestic" weight 20
      Then the result should have field "product" with value "lettre_verte"
      And the result should have field "zone" with value "domestic"
      And the result should have field "weight" with value 20
      And the result should have field "price" as number
      And the result should have field "currency" with value "EUR"

    Scenario: [laposte] Calculate price for domestic small letter
      When I call CLI price command with porto_id "small" country "FR" weight 20
      Then the result should have field "product" with nested "id" "lettre_verte"
      And the result should have field "zone" with nested "id" "domestic"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "EUR"
      And the result should have field "is_valid" with value true

    Scenario: [laposte] Calculate price for international letter
      When I call CLI price command with porto_id "small" country "US" weight 20
      Then the result should have field "product"
      And the result should have field "zone" with nested "id" "world"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "EUR"

    Scenario: [laposte] Simulate stamp generation
      When I call CLI stamp simulate command with porto_id "small" country "FR" weight 20
      Then the result should have field "simulation" with value true
      And the result should have field "product" with nested "id" "lettre_verte"
      And the result should have field "price" as number
      And the result should have field "valid" as boolean

    Scenario: [laposte] Check restrictions for home country
      When I call CLI restrictions command with country "FR"
      Then the result should have field "restricted" with value false
      And the result should have field "restrictions" as array

    Scenario: [laposte] CLI commands produce identical results for price
      When I call CLI price command with porto_id "small" country "FR" weight 20
      Then the result should be stored for comparison
      When I call CLI price command with porto_id "small" country "FR" weight 20
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

  Rule: Swiss Post CLI
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

    Scenario: [swisspost] Get price for product-zone-weight combination
      When I call CLI data price command with product "a_post_standardbrief" zone "domestic" weight 20
      Then the result should have field "product" with value "a_post_standardbrief"
      And the result should have field "zone" with value "domestic"
      And the result should have field "weight" with value 20
      And the result should have field "price" as number
      And the result should have field "currency" with value "CHF"

    Scenario: [swisspost] Calculate price for domestic small letter
      Given product id is "a_post_standardbrief"
      When I call CLI price command with porto_id "small" country "CH" weight 20
      Then the result should have field "product" with nested "id" "a_post_standardbrief"
      And the result should have field "zone" with nested "id" "domestic"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "CHF"
      And the result should have field "is_valid" with value true

    Scenario: [swisspost] Calculate price for international letter
      When I call CLI price command with porto_id "small" country "US" weight 20
      Then the result should have field "product"
      And the result should have field "zone" with nested "id" "world"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "CHF"

    Scenario: [swisspost] Simulate stamp generation
      Given product id is "a_post_standardbrief"
      When I call CLI stamp simulate command with porto_id "small" country "CH" weight 20
      Then the result should have field "simulation" with value true
      And the result should have field "product" with nested "id" "a_post_standardbrief"
      And the result should have field "price" as number
      And the result should have field "valid" as boolean

    Scenario: [swisspost] Check restrictions for home country
      When I call CLI restrictions command with country "CH"
      Then the result should have field "restricted" with value false
      And the result should have field "restrictions" as array

    Scenario: [swisspost] CLI commands produce identical results for price
      Given product id is "a_post_standardbrief"
      When I call CLI price command with porto_id "small" country "CH" weight 20
      Then the result should be stored for comparison
      When I call CLI price command with porto_id "small" country "CH" weight 20
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

  Rule: Ukrposhta CLI
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

    Scenario: [ukrposhta] Get price for product-zone-weight combination
      When I call CLI data price command with product "lyst_standartnyi" zone "domestic" weight 20
      Then the result should have field "product" with value "lyst_standartnyi"
      And the result should have field "zone" with value "domestic"
      And the result should have field "weight" with value 20
      And the result should have field "price" as number
      And the result should have field "currency" with value "UAH"

    Scenario: [ukrposhta] Calculate price for domestic small letter
      When I call CLI price command with porto_id "small" country "UA" weight 20
      Then the result should have field "product" with nested "id" "lyst_standartnyi"
      And the result should have field "zone" with nested "id" "domestic"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "UAH"
      And the result should have field "is_valid" with value true

    Scenario: [ukrposhta] Calculate price for international letter
      When I call CLI price command with porto_id "small" country "US" weight 20
      Then the result should have field "product"
      And the result should have field "zone" with nested "id" "world"
      And the result should have field "base_price" as number
      And the result should have field "currency" with value "UAH"

    Scenario: [ukrposhta] Simulate stamp generation
      When I call CLI stamp simulate command with porto_id "small" country "UA" weight 20
      Then the result should have field "simulation" with value true
      And the result should have field "product" with nested "id" "lyst_standartnyi"
      And the result should have field "price" as number
      And the result should have field "valid" as boolean

    Scenario: [ukrposhta] Check restrictions for home country
      When I call CLI restrictions command with country "UA"
      Then the result should have field "restricted" with value false
      And the result should have field "restrictions" as array

    Scenario: [ukrposhta] CLI commands produce identical results for price
      When I call CLI price command with porto_id "small" country "UA" weight 20
      Then the result should be stored for comparison
      When I call CLI price command with porto_id "small" country "UA" weight 20
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

  Rule: Provider switching
    Scenario: Changing provider updates catalog listing
      Given provider is "deutschepost"
      And I have porto-data available
      And I have a Porto SDK client initialized
      When I call CLI data products command
      Then the products array should contain product with id "standardbrief"
      Given provider is "ukrposhta"
      When I call CLI data products command
      Then the products array should contain product with id "lyst_standartnyi"
      Given provider is "laposte"
      When I call CLI data products command
      Then the products array should contain product with id "lettre_verte"
      Given provider is "swisspost"
      When I call CLI data products command
      Then the products array should contain product with id "a_post_standardbrief"
