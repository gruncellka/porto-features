@sdk
@operator:swisspost
Feature: Swiss Post resolution
  As a developer
  I want to resolve product, zone, and weight tier from country code and weight
  So that I can determine the correct product and zone for a letter

  Background:
    Given provider is "swisspost"
    And I have access to porto-data

  Scenario: Resolve domestic A-Post standard letter
    Given I want to send a letter to country "CH"
    And the letter weight is 20 grams
    When I resolve the letter
    Then I should get product with id "a_post_standardbrief"
    And I should get zone with id "domestic"
    And I should get weight tier "W0020"
    And the resolution should be valid
