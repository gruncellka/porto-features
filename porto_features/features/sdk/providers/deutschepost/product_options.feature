@sdk
@operator:deutschepost
Feature: Deutsche Post product options
  As a developer
  I want ambiguous porto_id resolution to return product options
  So that apps can disambiguate when multiple native products share a bucket

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Extra large domestic options
    Given I want to send a letter to country "DE"
    And the letter weight is 501 grams
    And the letter porto_id is "extra_large"
    When I list product options
    Then product options should include "maxibrief"

  Scenario: Extra large international options
    Given I want to send a letter to country "FR"
    And the letter weight is 1700 grams
    And the letter porto_id is "extra_large"
    When I list product options
    Then product options should include "maxibrief_ausland"
