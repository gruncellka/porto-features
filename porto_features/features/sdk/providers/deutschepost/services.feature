@sdk
@provider:deutschepost
Feature: Services
  As a developer
  I want Deutsche Post services bound through public resolve
  So that kinds and catalog ids stay distinct

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: Available services after resolve include registered variants
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I resolve the letter
    Then available services should include "einschreiben"
    And available services should include "einschreiben_einwurf"
    And available services should include "einschreiben_rueckschein"
    And each available service should have field "id"
    And each available service should have field "kind"

  Scenario: Unique return-receipt kind binds Einschreiben Rückschein
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered_return_receipt"
    When I resolve the letter
    Then the resolved Porto should include service id "einschreiben_rueckschein"
    And the resolved Porto should include service kind "registered_return_receipt"

  Scenario: Ambiguous registered kind fails closed
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_SERVICE_AMBIGUOUS"

  Scenario: Pinned registered binds einschreiben
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered"
    And service ids are "einschreiben"
    When I resolve the letter
    Then the resolution should be valid
    And the resolved Porto should include service id "einschreiben"
    And the resolved amount should be greater than the product component amount

  Scenario: Discover service option then pin registered
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    When I list product options
    Then product options should include "standardbrief"
    And product option "standardbrief" should include service "einschreiben"
    When I resolve using product "standardbrief" and discovered service "einschreiben"
    Then the resolution should be valid
    And the resolved Porto should include service id "einschreiben"
    And the resolved Porto should include service kind "registered"

  Scenario: Registered is compatible with standardbrief
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And product id is "standardbrief"
    And service kind is "registered"
    And service ids are "einschreiben"
    When I resolve the letter
    Then the resolution should be valid
    And I should get product with id "standardbrief"
    And the resolved Porto should include service id "einschreiben"

  Scenario: Incompatible registered variants fail closed
    Given I want to send a letter to country "DE"
    And the letter weight is 20 grams
    And service kind is "registered"
    And service ids are "einschreiben,einschreiben_einwurf"
    When I resolve the letter
    Then the resolution should be invalid
    And I should get Porto error code "PORTO_SERVICES_INCOMPATIBLE"
