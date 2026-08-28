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

  @scenario:core.mark.many_success
  Scenario: Execute three equivalent marks
    Given a resolved stamp Porto
    When I create three equivalent marks together
    Then three marks should be returned
    And every returned mark should have an id
    And the returned mark ids should be distinct
