@sdk
@provider:laposte
Feature: La Poste products
  As a developer
  I want ambiguous product resolution to return product options
  So that apps can disambiguate when multiple native products match at the same weight

  Background:
    Given provider is "laposte"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Light weight returns multiple options
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    When I list product options
    Then product options should include "lettre_verte"
    And product options should include "lettre_services_plus"
