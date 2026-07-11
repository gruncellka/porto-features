@sdk
@operator:laposte
Feature: La Poste delivery resolution
  As a developer
  I want delivery hints and product disambiguation from porto-data
  So that SLA facts and speed-tier picks are data-driven

  Background:
    Given provider is "laposte"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Fastest preference
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    And delivery preference is "fastest"
    When I resolve the shipping configuration
    Then I should get product with id "lettre_services_plus"

  Scenario: Ambiguous without delivery hint
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the shipping configuration
    Then resolution should be product ambiguous
