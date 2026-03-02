Feature: Stamp Generation
  As a developer
  I want to generate digital stamps
  So that I can create postage for letters

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  @offline
  Scenario: Pre-calculate price before stamp generation
    Given I have a letter with type "STANDARD"
    And destination country "DE"
    And weight 20 grams
    When I pre-calculate the price
    Then I should get a pre-calculated price in cents
    And the currency should be "EUR"
    And the pre-calculated price should be greater than 0

  @canary @online @api
  Scenario: Generate stamp with pre-calculation
    Given I have a letter with type "STANDARD"
    And destination country "DE"
    And weight 20 grams
    And valid destination address
    And valid origin address
    And Internetmarke credentials are configured
    When I generate a digital stamp
    Then the stamp should be generated successfully
    And the stamp should have an id
    And the stamp should have a barcode
    And the stamp should have a valid until date
    And the stamp should include pre-calculated price
    And the stamp should include final API price

  @release @online @api
  Scenario: Compare pre-calculated and API prices
    Given I have a letter with type "STANDARD"
    And destination country "DE"
    And weight 20 grams
    And Internetmarke credentials are configured
    When I generate a digital stamp
    Then the system should compare pre-calculated and API prices
    And if prices match, no mismatch should be reported
    And if prices differ, a mismatch should be reported
    And the price difference should be calculated

  @offline
  Scenario: Generate stamp without credentials shows pre-calculation only
    Given I have a letter with type "STANDARD"
    And destination country "DE"
    And weight 20 grams
    And Internetmarke credentials are not configured
    When I attempt to generate a digital stamp
    Then pre-calculation should still work
    And I should get a pre-calculated price
    And stamp generation should indicate credentials are required

  @offline
  Scenario: Simulate stamp generation
    Given I have a letter with type "STANDARD"
    And destination country "DE"
    And weight 20 grams
    When I simulate stamp generation
    Then I should get simulation result
    And the result should indicate simulation mode
    And the result should include product information
    And the result should include price information
    And the result should include validation status

  @offline
  Scenario: Stamp generation validates letter first
    Given I have a letter with type "STANDARD"
    And destination country "DE"
    And weight 20 grams
    And invalid dimensions
    When I attempt to generate a digital stamp
    Then validation should fail
    And stamp generation should be rejected
    And I should get validation errors
