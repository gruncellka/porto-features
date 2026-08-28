@adapters
@provider:deutschepost
@wire:internetmarke
Feature: Internetmarke adapter errors
  As a developer
  I want predictable PortoErrorCode mapping when Internetmarke execution fails
  So that consumers branch on stable error codes

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized

  @error
  @scenario:internetmarke.missing_credentials
  Scenario: Missing credentials returns auth failed
    Given Internetmarke credentials are not configured
    When I attempt to create a mark
    Then mark creation should fail
    And I should get Porto error code "PORTO_AUTH_FAILED"

  @error
  @scenario:internetmarke.letter.overweight
  Scenario: Letter overweight fails before purchase
    Given Internetmarke credentials are not configured
    And I want to send a letter to country "DE"
    And the letter weight is 50000 grams
    When I resolve the letter
    Then I should get Porto error code "PORTO_TOO_HEAVY"

  @error
  @scenario:core.address.invalid
  Scenario: Invalid address format fails before purchase
    Given Internetmarke credentials are configured
    And the mark destination address is invalid for testing
    When I attempt to create a mark
    Then mark creation should fail
    And I should get Porto error code "PORTO_ADDRESS_RECIPIENT_INVALID"

  @error
  @auth
  @scenario:internetmarke.auth.generic_401
  Scenario: OpenAPI unauthorized maps to provider auth failed
    Given Internetmarke auth test trigger is "unauthorized_prose"
    When I map the Internetmarke auth HTTP error for testing
    Then mark creation should fail
    And I should get Porto error code "PORTO_AUTH_FAILED"

  @error
  @auth
  @scenario:internetmarke.auth.invalid_dhl_app
  Scenario: Invalid DHL developer app credentials
    Given Internetmarke auth test trigger is "dhl_app_token_denied"
    When I map the Internetmarke auth HTTP error for testing
    Then mark creation should fail
    And I should get Porto error code "PORTO_AUTH_DENIED"

  @error
  @auth
  @scenario:internetmarke.auth.invalid_portokasse_password
  Scenario: Invalid Portokasse password
    Given Internetmarke auth test trigger is "invalid_portokasse_password"
    When I map the Internetmarke auth HTTP error for testing
    Then mark creation should fail
    And I should get Porto error code "PORTO_AUTH_FAILED"

  @error
  @scenario:internetmarke.wallet_insufficient
  Scenario: Insufficient Portokasse wallet maps to wallet insufficient
    Given Internetmarke mark-execution test trigger is "wallet_balance_not_enough"
    When I map the Internetmarke mark-execution HTTP error for testing
    Then mark creation should fail
    And I should get Porto error code "PORTO_WALLET_INSUFFICIENT"
