@sdk
@provider:ukrposhta
Feature: Ukrposhta resolution
  As a developer
  I want Ukrposhta catalog facts to map onto the public resolve contract

  Background:
    Given provider is "ukrposhta"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Resolve 20 g domestic
    Given I want to send a letter to country "UA"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "lyst_standartnyi"
    And I should get zone with id "domestic"
    And the resolution should be valid
