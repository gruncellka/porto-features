# STEP_VOCABULARY

Canonical phrasing for shared BDD language across `porto-features`, Python SDK tests, and TypeScript SDK tests.

This file prevents step drift where semantically identical phrases are treated as different steps.

## Rules

- Use canonical phrases in new feature files.
- SDK step definitions must support canonical phrases first.
- Legacy phrase variants are supported via aliases in SDK test suites.
- Do not duplicate semantics with slightly different wording.

## Semantic Rule

Each business concept must map to exactly one canonical step.

Multiple phrases that represent the same meaning must resolve to the same step definition via aliases.

Avoid creating new steps when an existing semantic concept already exists.

## Shared Test Context

All step definitions operate on a shared scenario context object.

The context may include:

- sender
- recipient
- product
- weight
- calculated_price
- currency

Step implementations should read/write this shared context instead of duplicating setup logic in isolated local variables.

## Parameter Naming

Use consistent parameter names:

- `<letter_type>` for product identifiers
- `<weight>` for grams
- `<price>` for cents

Avoid introducing alternative parameter names for the same concept.

## Canonical Phrases

These phrases must be used when writing new feature scenarios:

- `Given a sender`
- `Given a recipient`
- `Given a letter product "<letter_type>"`
- `Given weight <weight> grams`
- `When calculate postage`
- `Then price should be returned`

## Allowed Aliases

Aliases are accepted for backward compatibility only.

### Sender

Canonical:

- `Given a sender`

Aliases:

- `Given a valid sender`
- `Given a domestic sender`
- `Given valid origin address`

### Recipient

Canonical:

- `Given a recipient`

Aliases:

- `Given valid destination address`

### Product

Canonical:

- `Given a letter product "<letter_type>"`

Aliases:

- `Given I have a letter with type "<letter_type>"`

### Weight

Canonical:

- `Given weight <weight> grams`

Aliases:

- `Given I have weight <weight> grams`
- `Given I have a letter with weight <weight> grams`

### Price calculation action

Canonical:

- `When calculate postage`

Aliases:

- `When I calculate the price`

### Price assertion

Canonical:

- `Then price should be returned`

Aliases:

- `Then I should get a price in cents`

## Implementation Guidance

### Python (`pytest-bdd`)

Use multi-decorator aliases for one function:

```python
@given("a sender")
@given("a valid sender")
@given("a domestic sender")
def given_sender(context):
    ...
```

### TypeScript (`@cucumber/cucumber`)

Use regex aliases for equivalent wording:

```ts
Given(/^(?:a )?(?:valid |domestic )?sender$/, async function () {
  ...
})
```

## Review Checklist for New Features

- Does a new step duplicate an existing semantic meaning?
- Can it reuse existing canonical phrase instead?
- If alias is needed, was canonical phrase kept as the primary one?

## Example Scenario

```gherkin
Scenario: Calculate domestic letter postage
  Given a sender
  And a recipient
  And a letter product "letter_standard"
  And weight 20 grams
  When calculate postage
  Then price should be returned
```
