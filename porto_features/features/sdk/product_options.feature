@sdk
Feature: Product options
  As a developer
  I want ambiguous porto_id resolution to return product options
  So that apps can disambiguate when multiple native products share a bucket

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: La Poste small bucket returns multiple options
    Given provider is "laposte"
    And I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I list product options
    Then product options should include "lettre_verte"
    And product options should include "lettre_services_plus"

  Scenario: Deutsche Post extra large domestic options
    Given provider is "deutschepost"
    And I want to send a letter to country "DE"
    And the letter weight is 500 grams
    And the letter porto_id is "extra_large"
    When I list product options
    Then product options should include "maxibrief"

  Scenario: Ukrposhta large is domestic only
    Given provider is "ukrposhta"
    And I want to send a letter to country "UA"
    And the letter weight is 100 grams
    And the letter porto_id is "large"
    When I list product options
    Then product options should include "dokument"
