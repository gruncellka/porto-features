@offline
Feature: Services
  As a developer
  I want to work with shipping services
  So that I can add additional services like registered mail to letters

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Scenario: List available services
    When I list available services
    Then I should get an array of services
    And the services array should contain service with id "registered_mail"
    And the services array should contain service with id "registered_mail_mailbox"
    And the services array should contain service with id "registered_mail_return_receipt"
    And each service should have field "id"
    And each service should have field "name"
    And each service should have field "features"

  Scenario: Get service features
    Given I have service "registered_mail"
    When I get the service features
    Then I should get an array of features
    And the features should include "tracking_number"
    And the features should include "proof_of_mailing"
    And the features should include "delivery_confirmation"

  Scenario: Get service features for mailbox delivery
    Given I have service "registered_mail_mailbox"
    When I get the service features
    Then I should get an array of features
    And the features should include "tracking_number"
    And the features should include "mailbox_delivery"
    And the features should include "photo_proof_delivery"

  Scenario: Add registered mail service to letter
    Given I have a letter order
    And I want to add service "registered_mail"
    When I add the service to the order
    Then the order should include service "registered_mail"
    And the order should have tracking number capability
    And the order should have proof of mailing capability

  Scenario: Add registered mail with return receipt
    Given I have a letter order
    And I want to add service "registered_mail_return_receipt"
    When I add the service to the order
    Then the order should include service "registered_mail_return_receipt"
    And the order should have recipient signature requirement
    And the order should have return receipt capability

  Scenario: Calculate price with registered mail service
    Given I have a letter with base price
    And I want to add service "registered_mail"
    When I calculate the total price
    Then the total price should include base price
    And the total price should include registered mail fee
    And the total price should be higher than base price

  Scenario: Validate service compatibility with product
    Given I have product "letter_standard"
    And I want to add service "registered_mail"
    When I check service compatibility
    Then the service should be compatible
    And I should get no compatibility errors
