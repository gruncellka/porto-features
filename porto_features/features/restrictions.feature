@offline
Feature: Restrictions
  As a developer
  I want to check shipping restrictions and sanctions
  So that I can ensure compliance with shipping regulations

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Check restrictions for destination country
    Given I want to send a letter to country "DE"
    When I check restrictions
    Then there should be no restrictions
    And shipping should be allowed

  Scenario: Check restrictions for EU country
    Given I want to send a letter to country "FR"
    When I check restrictions
    Then there should be no restrictions
    And shipping should be allowed

  Scenario: Check restrictions for restricted country
    Given I want to send a letter to country "YE"
    When I check restrictions
    Then there should be restrictions
    And shipping should be restricted
    And I should get restriction information

  Scenario: Reject shipment to restricted region in Ukraine (Mariupol)
    Given I have destination address fixture "restricted_UA"
    And I want to send a letter to country "UA"
    And destination region code is "UA-14"
    When I check restrictions
    Then there should be restrictions
    And shipping should be prohibited
    And I should get an error about restricted destination region

  Scenario: Check restrictions returns framework information
    Given I want to send a letter to a restricted country
    When I check restrictions
    Then I should get framework information
    And the framework should indicate the legal basis
    And the framework should indicate effective dates

  Scenario: Check if country is under sanctions
    Given I want to send a letter to country "RU"
    When I check sanctions
    Then the country should be under sanctions
    And I should get sanctions information
    And shipping should be restricted

  Scenario: Check denied party screening information
    When I access denied party screening information
    Then I should get screening policy details
    And the information should include compliance frameworks
    And the information should include screening lists

  Scenario: Resolution includes restriction status
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And the letter type is "STANDARD"
    When I resolve the shipping configuration
    Then the resolution should include restriction status
    And the restriction status should indicate if shipping is allowed

  Scenario: Validation warns about restrictions
    Given I have a letter with type "STANDARD"
    And the destination country has restrictions
    And valid dimensions and weight
    When I validate the letter
    Then the validation should pass
    And I should get warnings about restrictions
    And the warnings should include restriction details
