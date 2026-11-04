@sdk
@core
Feature: PortoStatus catalog contract

  @status
  @scenario:core.status.catalog_includes_created
  Scenario: created is declared in the PortoStatus catalog
    Then "created" should be declared in the PortoStatus catalog
