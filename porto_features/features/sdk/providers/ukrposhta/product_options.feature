@sdk
@operator:ukrposhta
Feature: Ukrposhta product options
  As a developer
  I want ambiguous product resolution to return product options
  So that apps can disambiguate when multiple native products match at the same weight

  Background:
    Given provider is "ukrposhta"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Large is domestic only
    Given I want to send a letter to country "UA"
    And the letter weight is 500 grams
    When I list product options
    Then product options should include "dokument"
