@sdk
@operator:deutschepost
Feature: Services
  As a developer
  I want additional services on a letter
  So that I can add additional services like registered mail to letters

  Background:
    Given provider is "deutschepost"
    And I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: List available services
    When I list available services
    Then I should get an array of services
    And the services array should contain service with id "einschreiben"
    And the services array should contain service with id "einschreiben_einwurf"
    And the services array should contain service with id "einschreiben_rueckschein"
    And each service should have field "id"
    And each service should have field "name"
    And each service should have field "features"

  Scenario: Get service features
    Given I have service "einschreiben"
    When I get the service features
    Then I should get an array of features
    And the features should include "tracking"
    And the features should include "proof_of_mailing"

  Scenario: Get service features for mailbox delivery
    Given I have service "einschreiben_einwurf"
    When I get the service features
    Then I should get an array of features
    And the features should include "tracking"

  Scenario: Add registered mail service to letter
    Given I have a letter order
    And service porto_id is "registered"
    When I add the service to the order
    Then the order should include service "einschreiben"
    And the order should have tracking number capability
    And the order should have proof of mailing capability

  Scenario: Add registered mail with return receipt
    Given I have a letter order
    And service porto_id is "registered_return_receipt"
    When I add the service to the order
    Then the order should include service "einschreiben_rueckschein"
    And the order should have recipient signature requirement
    And the order should have return receipt capability

  Scenario: Get total price with registered mail service
    Given I have a letter with base price
    And service porto_id is "registered"
    When I get the total price
    Then the total price should include base price
    And the total price should include registered mail fee
    And the total price should be higher than base price

  Scenario: Validate service compatibility with product
    Given I have product "standardbrief"
    And service porto_id is "registered"
    When I check service compatibility
    Then the service should be compatible
    And I should get no compatibility errors
