@sdk
Feature: Delivery resolution
  As a developer
  I want delivery hints and product disambiguation from porto-data
  So that SLA facts and speed-tier picks are data-driven

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Deutsche Post domestic delivery hint
    Given provider is "deutschepost"
    And I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the shipping configuration
    Then I should get product with id "standardbrief"
    And delivery hint span should be "between"
    And delivery hint days max should be 2
    And delivery hint weekdays should be "mon_sat"

  Scenario: La Poste fastest preference
    Given provider is "laposte"
    And I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    And delivery preference is "fastest"
    When I resolve the shipping configuration
    Then I should get product with id "lettre_services_plus"

  Scenario: La Poste ambiguous without delivery hint
    Given provider is "laposte"
    And I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the shipping configuration
    Then resolution should be product ambiguous
