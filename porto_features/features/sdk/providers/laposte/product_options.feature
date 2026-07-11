@sdk
@operator:laposte
Feature: La Poste product options
  As a developer
  I want ambiguous porto_id resolution to return product options
  So that apps can disambiguate when multiple native products share a bucket

  Background:
    Given provider is "laposte"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Small bucket returns multiple options
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I list product options
    Then product options should include "lettre_verte"
    And product options should include "lettre_services_plus"
