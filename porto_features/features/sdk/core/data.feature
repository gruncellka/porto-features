@sdk
@core
Feature: Data
  As a developer
  I want public catalog surfaces
  So that I can list envelopes, providers, and product options without private loaders

  Background:
    Given I have porto-data available
    And I have a Porto SDK client initialized

  Scenario: Inspect envelopes data
    When I inspect envelopes data
    Then I should get an array of envelopes
    And the envelopes array should contain envelope with id "DL"
    And the envelopes array should contain envelope with id "C6"
    And the envelopes array should contain envelope with id "C5"
    And the envelopes array should contain envelope with id "C4"
    And each envelope should have field "id"
    And each envelope should have field "width"
    And each envelope should have field "height"

  Scenario: Inspect provider registry
    When I inspect the provider registry
    Then I should get providers information
    And providers should include provider "deutschepost"
    And providers should include provider "ukrposhta"
    And providers should include provider "laposte"
    And providers should include provider "swisspost"

  Scenario: Product options are listable
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I list product options
    Then I should get a non-empty list of product options

  Scenario Outline: Country alpha-3 via jurisdictions
    When I look up country code 3 for "<country_code>"
    Then the country code 3 should be "<country_code_3>"

    Examples:
      | country_code | country_code_3 |
      | IE           | IRL            |
      | BG           | BGR            |
      | US           | USA            |
