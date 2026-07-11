@sdk
@operator:deutschepost
Feature: Deutsche Post letter validation
  As a developer
  I want to validate letters against Deutsche Post catalog rules
  So that I can ensure shipping requirements are met

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Validate valid small letter
    Given I have a letter with porto_id "small"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 20 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the resolved product id should be "standardbrief"

  Scenario: Validate valid medium letter
    Given I have a letter with porto_id "medium"
    And length 229 mm
    And width 162 mm
    And height 5 mm
    And weight 30 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the resolved product id should be "kompaktbrief"

  Scenario: Validate valid large letter
    Given I have a letter with porto_id "large"
    And length 324 mm
    And width 229 mm
    And height 5 mm
    And weight 100 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the resolved product id should be "grossbrief"

  Scenario: Validate valid extra large letter
    Given I have a letter with porto_id "extra_large"
    And length 353 mm
    And width 250 mm
    And height 60 mm
    And weight 501 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should pass
    And there should be no errors
    And the resolved product id should be "maxibrief"

  Scenario: Reject letter with invalid dimensions
    Given I have a letter with porto_id "small"
    And length 50 mm
    And width 50 mm
    And height 5 mm
    And weight 10 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should fail
    And I should get an error about invalid dimensions

  Scenario: Reject letter that is too heavy
    Given I have a letter with porto_id "small"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 2500 grams
    And valid destination address
    And valid origin address
    When I validate the letter
    Then the validation should fail
    And I should get an error about weight exceeding maximum

  Scenario: Reject letter with invalid address
    Given I have a letter with porto_id "small"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 20 grams
    And invalid destination address
    And valid origin address
    When I validate the letter
    Then the validation should fail
    And I should get an error about invalid address

  Scenario: Validation returns warnings for edge cases
    Given I have a letter with porto_id "small"
    And length 210 mm
    And width 148 mm
    And height 5 mm
    And weight 20 grams
    And valid destination address
    And valid origin address
    And the destination country has restrictions
    When I validate the letter
    Then the validation should pass
    And I should get warnings about restrictions
