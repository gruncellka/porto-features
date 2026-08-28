@sdk
@core
Feature: Public resolution contract
  Cross-provider invariants through ProviderClient.resolve and price.
  Provider-native product ids belong in provider features.

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Destination and weight resolve a Porto without product pin
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then the resolution should be valid
    And the resolved Porto should have a product id
    And the resolved amount should be a positive number
    And the resolved currency is present
    And the resolved Porto should include a restrictions result

  Scenario: Quoted amount equals resolved amount
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    And I get the price
    Then the quoted amount should equal the resolved amount

  Scenario: Price components sum to the resolved amount
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered_return_receipt"
    When I resolve the letter
    Then the resolution should be valid
    And the resolved Porto components should sum to the resolved amount

  Scenario: Envelope id is an optional physical filter
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And envelope id is "DL"
    When I resolve the letter
    Then the resolution should be valid
    And the resolved Porto should have a product id

  Scenario: Optional product id pins a concrete product
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And a concrete product id is pinned from catalog options
    When I resolve the letter
    Then the resolution should be valid
    And the resolved Porto should have the pinned product id

  Scenario: Unique service kind binds without a catalog pin
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered_return_receipt"
    When I resolve the letter
    And I get the price
    Then the resolution should be valid
    And the resolved Porto should include service kind "registered_return_receipt"
    And the quoted amount should equal the resolved amount

  Scenario: Ambiguous service kind fails closed
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_SERVICE_AMBIGUOUS"

  Scenario: Unsupported service kind fails closed
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "thickness"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_SERVICE_UNSUPPORTED"
