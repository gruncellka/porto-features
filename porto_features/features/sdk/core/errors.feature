@sdk
@core
Feature: Normalized Porto error codes (provider-agnostic)
  As a developer
  I want stable PortoErrorCode values from offline SDK paths
  So that consumers branch on codes instead of message prose

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  @scenario:core.product.ambiguous
  Scenario: Ambiguous porto_id without delivery preference
    Given provider is "laposte"
    And I want to send a letter to country "FR"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_PRODUCT_AMBIGUOUS"

  @scenario:core.destination.invalid
  Scenario: Invalid country code during resolution
    Given I want to send a letter to country "XX"
    And the letter weight is 20 grams
    And the letter porto_id is "small"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_DESTINATION_INVALID"

  @scenario:core.letter.overweight
  Scenario: Letter weight exceeds product maximum
    Given I want to send a letter to country "DE"
    And the letter porto_id is "small"
    And the letter weight is 50000 grams
    When I resolve the letter
    Then I should get Porto error code "PORTO_LETTER_TOO_HEAVY"
