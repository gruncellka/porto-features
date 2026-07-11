@sdk
@operator:ukrposhta
Feature: Ukrposhta product options
  As a developer
  I want ambiguous porto_id resolution to return product options
  So that apps can disambiguate when multiple native products share a bucket

  Background:
    Given provider is "ukrposhta"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Large is domestic only
    Given I want to send a letter to country "UA"
    And the letter weight is 100 grams
    And the letter porto_id is "large"
    When I list product options
    Then product options should include "dokument"
