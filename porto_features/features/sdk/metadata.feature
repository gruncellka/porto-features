@sdk
Feature: Metadata access
  As a developer
  I want to read bundle metadata and provider registry
  So that SDKs can report catalog version and entity inventory

  Scenario: List postal providers
    Given I have a Porto SDK client initialized for provider "deutschepost"
    When I list postal providers
    Then the providers list should contain provider id "deutschepost"
    And the providers list should contain provider id "laposte"
    And the providers list should contain provider id "swisspost"
    And the providers list should contain provider id "ukrposhta"

  Scenario: List Deutsche Post products
    Given I have a Porto SDK client initialized for provider "deutschepost"
    When I list products for provider "deutschepost"
    Then the products list should contain product id "standardbrief"
    And the products list should contain product id "kompaktbrief"

  Scenario: List envelope catalog
    Given I have a Porto SDK client initialized for provider "deutschepost"
    When I list envelopes for provider "deutschepost"
    Then the envelopes list should contain envelope id "DL"
    And the envelopes list should contain envelope id "C6"
