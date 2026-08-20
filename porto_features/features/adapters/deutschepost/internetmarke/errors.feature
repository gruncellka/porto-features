@adapters
@operator:deutschepost
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
  Scenario: Missing credentials returns feature not supported
    Given Internetmarke credentials are not configured
    When I attempt to create a mark
    Then mark creation should fail
    And I should get Porto error code "PORTO_FEATURE_UNSUPPORTED"

  @error
  @scenario:internetmarke.letter.overweight
  Scenario: Letter overweight fails before purchase
    Given Internetmarke credentials are not configured
    And the letter weight is 50000 grams
    When I determine the envelope type for error testing
    Then I should get Porto error code "PORTO_LETTER_TOO_HEAVY"

  @error
  @scenario:core.address.invalid
  Scenario: Invalid address format fails before purchase
    Given Internetmarke credentials are configured
    And the mark destination address is invalid for testing
    When I prepare a mark order for error testing
    Then mark creation should fail
    And I should get Porto error code "PORTO_ADDRESS_INVALID"

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
    Given Internetmarke credentials are configured
    And Internetmarke DHL app credentials are invalid for testing
    When I probe Internetmarke authentication
    Then mark creation should fail
    And I should get Porto error code "PORTO_AUTH_DENIED"

  @error
  @auth
  @scenario:internetmarke.auth.invalid_portokasse_password
  Scenario: Invalid Portokasse password
    Given Internetmarke credentials are configured
    And Internetmarke Portokasse password is invalid for testing
    When I probe Internetmarke authentication
    Then mark creation should fail
    And I should get Porto error code "PORTO_AUTH_DENIED"

  @error
  @mark
  @scenario:internetmarke.wallet_insufficient
  Scenario: Insufficient Portokasse wallet at mark purchase
    Given Internetmarke credentials are configured
    When I attempt to create a mark
    Then mark creation should fail
    And I should get Porto error code "PORTO_WALLET_INSUFFICIENT"

  @error
  @mark
  @scenario:internetmarke.mark.invalid_product
  Scenario: Invalid product code at API checkout
    Given Internetmarke credentials are configured
    When I attempt to purchase a mark with invalid wire code for testing
    Then mark creation should fail
    And I should get Porto error code "PORTO_MARK_GENERATION_FAILED"
