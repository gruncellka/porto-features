@sdk
@provider:laposte
Feature: La Poste resolution
  As a developer
  I want La Poste catalog facts to map onto the public resolve contract

  Background:
    Given provider is "laposte"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Pin lettre_verte at 20 g
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And product id is "lettre_verte"
    When I resolve the letter
    Then I should get product with id "lettre_verte"
    And I should get zone with id "domestic"
    And the resolution should be valid

  Scenario: Fastest preference
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And delivery preference is "fastest"
    When I resolve the letter
    Then I should get product with id "lettre_services_plus"

  Scenario: Ambiguous without delivery hint
    Given I want to send a letter to country "FR"
    And the letter weight is 20 grams
    When I resolve the letter
    Then resolution should be product ambiguous
