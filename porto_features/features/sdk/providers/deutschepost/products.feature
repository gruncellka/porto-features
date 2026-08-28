@sdk
@provider:deutschepost
Feature: Deutsche Post products
  As a developer
  I want ambiguous product resolution to return product options
  So that apps can disambiguate when multiple native products match at the same weight

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: 501 g domestic options include maxibrief
    Given I want to send a letter to country "DE"
    And the letter weight is 501 grams
    When I list product options
    Then product options should include "maxibrief"

  Scenario: 1700 g international options include maxibrief_ausland
    Given I want to send a letter to country "FR"
    And the letter weight is 1700 grams
    When I list product options
    Then product options should include "maxibrief_ausland"
