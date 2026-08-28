@sdk
@core
Feature: Metadata access
  As a developer
  I want to read the provider registry and global envelope catalog
  So that SDKs report inventory through public APIs

  Scenario: List postal providers
    Given I have a Porto SDK client initialized
    When I list postal providers
    Then the providers list should contain provider id "deutschepost"
    And the providers list should contain provider id "laposte"
    And the providers list should contain provider id "swisspost"
    And the providers list should contain provider id "ukrposhta"

  Scenario: List global envelope catalog
    Given I have a Porto SDK client initialized
    When I list envelope catalog
    Then the envelopes list should contain envelope id "DL"
    And the envelopes list should contain envelope id "C6"
