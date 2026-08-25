@sdk
@core
Feature: Mark address requirements
  Address roles come from Porto.requires, not from registered mail or leftover request fields.

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Stamp needs no address
    Given a resolved stamp Porto
    When I create a mark without sender or recipient
    Then mark creation should succeed

  Scenario: Registered stamp needs no address
    Given the resolved Porto includes registered mail
    When I create a mark without sender or recipient
    Then mark creation should succeed

  @error
  @scenario:core.mark.sender_required
  Scenario: Address-bearing Porto missing sender
    Given a resolved Porto that requires ADDRESS_SENDER and ADDRESS_RECIPIENT
    And recipient is valid
    And sender is missing
    When I attempt to create a mark
    Then I should get Porto error code "PORTO_ADDRESS_SENDER_REQUIRED"

  @error
  @scenario:core.mark.recipient_required
  Scenario: Address-bearing Porto missing recipient
    Given a resolved Porto that requires ADDRESS_SENDER and ADDRESS_RECIPIENT
    And sender is valid
    And recipient is missing
    When I attempt to create a mark
    Then I should get Porto error code "PORTO_ADDRESS_RECIPIENT_REQUIRED"

  @error
  @scenario:core.mark.sender_invalid
  Scenario: Address-bearing Porto invalid sender
    Given a resolved Porto that requires ADDRESS_SENDER and ADDRESS_RECIPIENT
    And sender fails the jurisdiction form
    When I attempt to create a mark
    Then I should get Porto error code "PORTO_ADDRESS_SENDER_INVALID"

  @error
  @scenario:core.mark.recipient_invalid
  Scenario: Address-bearing Porto invalid recipient
    Given a resolved Porto that requires ADDRESS_SENDER and ADDRESS_RECIPIENT
    And recipient fails the jurisdiction form
    When I attempt to create a mark
    Then I should get Porto error code "PORTO_ADDRESS_RECIPIENT_INVALID"

  Scenario: Address-bearing Porto with valid addresses
    Given a resolved Porto that requires ADDRESS_SENDER and ADDRESS_RECIPIENT
    And sender and recipient are valid
    When I create a mark
    Then mark creation should succeed

  @error
  @scenario:core.mark.many_mismatch
  Scenario: Many call with inequivalent Portos
    Given two resolved Portos with different products
    When I attempt to create marks in one many call
    Then I should get Porto error code "PORTO_MARKS_MISMATCH"

  @error
  @scenario:core.mark.many_address
  Scenario: Many call when resolved Porto requires an address
    Given the resolved Porto requires ADDRESS_RECIPIENT
    When I attempt to create marks in one many call
    Then I should get Porto error code "PORTO_MARKS_MANY_UNSUPPORTED"
