@sdk
@operator:deutschepost
Feature: Stamp Generation
  As a developer
  I want to simulate digital stamp generation
  So that I can verify stamp payloads without carrier credentials

  Background:
    Given provider is "deutschepost"
    And I have access to porto-data

  Scenario: Simulate stamp generation
    Given I have a letter with porto_id "small"
    And I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I simulate stamp generation
    Then I should get simulation result
    And the result should indicate simulation mode
    And the result should include product information
    And the result should include price information
    And the result should include validation status
