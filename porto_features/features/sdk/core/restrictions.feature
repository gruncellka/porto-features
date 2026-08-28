@sdk
@core
Feature: Restrictions
  Durable destination facts through resolve() and restrictions.check().
  resolve attaches country-level Restrictions (impact + items).
  Region precision is an explicit follow-up via restrictions.check(country, region).
  resolve does not fail closed on restriction facts.

  Background:
    Given I have a Porto SDK client initialized
    And I have access to porto-data

  Rule: Unrestricted destinations
    Scenario: Resolve letter to unrestricted home country
      Given provider is "deutschepost"
      And I want to send a letter to country "DE"
      And the letter weight is 20 grams
      When I resolve the letter
      Then the resolution should be valid
      And the resolved Porto restrictions should have no impact
      And the resolved Porto restrictions list should be empty

    Scenario: Resolve letter to an unrestricted EU country
      Given provider is "deutschepost"
      And I want to send a letter to country "FR"
      And the letter weight is 20 grams
      When I resolve the letter
      Then the resolution should be valid
      And the resolved Porto should include a restrictions result

  Rule: Country-level resolve
    Scenario: Country resolve returns UA legal items with warn aggregate
      Given provider is "deutschepost"
      And I want to send a letter to country "UA"
      And the letter weight is 20 grams
      When I resolve the letter
      And I check destination restrictions
      Then the resolution should be valid
      And the restriction result impact should be "warn"
      And the restriction result should include legal region "UA-43"
      And the restriction result should include legal region "UA-14"
      And the restriction result should include legal region "UA-65"
      And the resolved Porto restrictions should match standalone restriction lookup

  Rule: Region drill-down via check
    Scenario: Kherson partial region warns
      Given provider is "deutschepost"
      And I want to send a letter to country "UA"
      And destination region code is "UA-65"
      When I check destination restrictions
      Then the restriction result impact should be "warn"
      And the restriction result should include legal region "UA-65"
      And the restriction result should not include legal region "UA-43"
      And the restriction result legal region "UA-65" should be partial

    Scenario: Fully matched legal territory blocks
      Given provider is "deutschepost"
      And I want to send a letter to country "UA"
      And destination region code is "UA-43"
      When I check destination restrictions
      Then the restriction result impact should be "block"
      And the restriction result should include legal region "UA-43"

    Scenario: Unaffected region has no restriction
      Given provider is "deutschepost"
      And I want to send a letter to country "UA"
      And destination region code is "UA-32"
      When I check destination restrictions
      Then the restriction result impact should be null
      And the restriction result list should be empty

  Rule: Provider origin selects remaining legal jurisdictions
    Scenario Outline: EU origin providers share the EU jurisdiction
      Given provider is "<provider>"
      And I want to send a letter to country "UA"
      And destination region code is "UA-65"
      When I check destination restrictions
      Then the restriction result legal jurisdictions should include "eur-lex.europa.eu"
      And the restriction result legal jurisdictions should not include "seco.admin.ch"
      And the restriction result legal jurisdictions should not include "zakon.rada.gov.ua"

      Examples:
        | provider     |
        | deutschepost |
        | laposte      |

    Scenario: Swiss Post uses the CH jurisdiction
      Given provider is "swisspost"
      And I want to send a letter to country "UA"
      And destination region code is "UA-65"
      When I check destination restrictions
      Then the restriction result legal jurisdictions should include "seco.admin.ch"
      And the restriction result legal jurisdictions should not include "eur-lex.europa.eu"

    Scenario: Ukrposhta uses the UA jurisdiction
      Given provider is "ukrposhta"
      And I want to send a letter to country "UA"
      And destination region code is "UA-65"
      When I check destination restrictions
      Then the restriction result legal jurisdictions should include "zakon.rada.gov.ua"
      And the restriction result legal jurisdictions should not include "eur-lex.europa.eu"

  Rule: Routing facts
    Scenario: Cyprus destination-side handling at mixed district
      Given provider is "deutschepost"
      And I want to send a letter to country "CY"
      And destination region code is "CY-01"
      When I check destination restrictions
      Then the restriction result impact should be "warn"
      And the restriction result should include routing region "CY-01"
      And the restriction result routing region "CY-01" should be partial
      And the restriction result routing authority should be "CY"
