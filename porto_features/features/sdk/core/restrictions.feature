@sdk
@core
Feature: Restrictions policy
  As a developer
  I want destination eligibility during letter resolution
  So that I can comply with mailing restrictions

  Rule: Operational destinations
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

    Scenario: Resolve letter to home country
      Given I want to send a letter to country "DE"
      And the letter weight is 20 grams
      And the letter porto_id is "small"
      When I resolve the letter
      Then I should get product with id "standardbrief"
      And I should get zone with id "domestic"

    Scenario: Resolve letter to EU country
      Given I want to send a letter to country "FR"
      And the letter weight is 20 grams
      And the letter porto_id is "small"
      When I resolve the letter
      Then I should get product with id "standardbrief"
      And I should get zone with id "zone_1_eu"

  Rule: Restricted destinations
    Background:
      Given provider is "deutschepost"
      And I have a Porto SDK client initialized
      And I have access to porto-data

    Scenario: Cannot resolve letter to prohibited country
      Given I want to send a letter to country "YE"
      And the letter weight is 20 grams
      And the letter porto_id is "small"
      When I resolve the letter
      Then the resolution should be invalid
      And I should get Porto error code "PORTO_DESTINATION_RESTRICTED"

    Scenario: Cannot resolve letter to restricted region in Ukraine (UA-14)
      Given I have destination address fixture "restricted_UA"
      And I want to send a letter to country "UA"
      And destination region code is "UA-14"
      And the letter weight is 20 grams
      And the letter porto_id is "small"
      When I resolve the letter
      Then the resolution should be invalid
      And I should get Porto error code "PORTO_DESTINATION_RESTRICTED"
      And I should get an error about restricted destination region

    Scenario: Cannot resolve letter returns framework information
      Given I want to send a letter to country "YE"
      And the letter weight is 20 grams
      And the letter porto_id is "small"
      When I resolve the letter
      Then the resolution should be invalid
      And I should get Porto error code "PORTO_DESTINATION_RESTRICTED"
      And I should get framework information
      And the framework should indicate the legal basis
      And the framework should indicate effective dates

  Rule: Catalog inspection
    Background:
      Given I have a Porto SDK client initialized
      And I have access to porto-data

    Scenario: Inspect restrictions data
      When I inspect restrictions data
      Then I should get restrictions information
      And restrictions should have field "sanctions_information"
      And restrictions should have field "denied_party_screening"
      And restrictions should have array "restrictions"

    Scenario: Inspect denied party screening
      When I inspect denied party screening
      Then I should get screening policy details
      And the information should include compliance frameworks
      And the information should include screening lists
