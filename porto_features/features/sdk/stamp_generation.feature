@sdk
Feature: Stamp Generation
  As a developer
  I want to generate digital stamps
  So that I can create postage for letters

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Pre-calculate price before stamp generation
    Given I have a letter with porto_id "small"
    And destination country "DE"
    And weight 20 grams
    When I pre-calculate the price
    Then I should get a pre-calculated price in cents
    And the currency should be "EUR"
    And the pre-calculated price should be greater than 0

  Scenario: Generate stamp without credentials shows pre-calculation only
    Given I have a letter with porto_id "small"
    And destination country "DE"
    And weight 20 grams
    And Internetmarke credentials are not configured
    When I attempt to generate a digital stamp
    Then pre-calculation should still work
    And I should get a pre-calculated price
    And stamp generation should indicate credentials are required

  Scenario: Simulate stamp generation
    Given I have a letter with porto_id "small"
    And destination country "DE"
    And weight 20 grams
    When I simulate stamp generation
    Then I should get simulation result
    And the result should indicate simulation mode
    And the result should include product information
    And the result should include price information
    And the result should include validation status

  Scenario: Stamp generation validates letter first
    Given I have a letter with porto_id "small"
    And destination country "DE"
    And weight 20 grams
    And invalid dimensions
    When I attempt to generate a digital stamp
    Then validation should fail
    And stamp generation should be rejected
    And I should get validation errors

  Scenario: Resolve mark profile for domestic registered
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    And service porto_id is "registered"
    When I resolve mark layout
    Then mark profile should be "registered"
    And mark type should be "stamp"
