@sdk
@operator:deutschepost
Feature: Deutsche Post delivery resolution
  As a developer
  I want delivery hints from porto-data
  So that SLA facts are data-driven

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Domestic delivery hint
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "standardbrief"
    And delivery hint span should be "between"
    And delivery hint days max should be 2
    And delivery hint weekdays should be "mon_sat"
