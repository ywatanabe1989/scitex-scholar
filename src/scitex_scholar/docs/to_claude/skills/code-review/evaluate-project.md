Evaluate the project from the following perspectives.

## Your evaluation format

```
## Layer 0 - Raison d'être (Why): X/10
    - DESCRIBE ONLY MAIN REASONS IN ONE LINE HERE
## Layer 2 - Solution Legitimacy (What): X/10
    - DESCRIBE ONLY MAIN REASONS IN ONE LINE HERE
...
...

## Summary: X/10
PROS:
    - SUMMARY DESCRIPTION HERE
CONS:
    - SUMMARY DESCRIPTION HERE
```


## Layer 0: Raison d'être (Why)

Is it worth doing at all?

1. Pain Point Reality (Real Pain)
   - Is the pain felt by real people right now?
   - Do you personally suffer from it daily?
   - Is there motivation to "solve" rather than "avoid" the pain?
   - Good signs:
     - Many workarounds exist, all unsatisfactory
     - Everyone accepts it as "unavoidable"
     - Same struggle appears repeatedly in papers, practice, or field work

2. Pain Point Depth (Depth)
   - Does it waste time?
   - Does it increase cognitive load?
   - Does it undermine reproducibility, reliability, or dignity?
   - Is it pain that "degrades research quality or life quality" rather than just "inconvenience"?

## Layer 1: Solution Legitimacy (What)

Does it truly solve the pain?

1. Solution Directness (Directness)
   - Does it directly address the pain point?
   - Is it not a roundabout alternative?
   - Is manual work truly eliminated?
   - Common failures:
     - Only UI is polished
     - Automation with too many exceptions
     - Essential parts still require human effort

2. Problem Definition Precision (Problem Framing)
    - Is the problem scoped at the right granularity?
    - Are technical and human responsibilities separated?
    - Does it address "causes" rather than "symptoms"?

## Layer 2: Approach Validity (How)

Is there necessity for this method?

1. Solution Approach Necessity
    - Why this architecture?
    - Why this data structure?
    - Why this abstraction level?
    - Good designs can always explain: "Given these constraints, this is the only way"

2. Scale Resilience (Time, People, Complexity)
    - Does it remain robust as features increase?
    - Will you understand it one year later?
    - Can others extend it?

## Layer 3: Implementation Quality (Execution)

Can the built artifact be trusted?

1. Code Honesty
    - Is it readable for future self?
    - Does it lie (naming, types, responsibilities)?
    - Does exception handling align with philosophy?
    - Metrics: cognitive load and reliability, not "beauty"

2. Boundary Clarity
    - Are API, internals, cache, and derivatives separated?
    - Is it clear what can and cannot be deleted?
    - Are persistence and temporary generation unmixed?

## Layer 4: Replaceability (Alternatives)

Is it truly better than others?

1. Comparative Advantage over Existing Methods
    - Cannot be replaced by existing tools plus effort?
    - Even if replaceable, psychological cost is not too high?
    - Does it eliminate "only insiders benefit" situations?

2. Irreversibility (Lock-in Legitimacy)
    - Does using it bring more benefits?
    - Is there "irreplaceable" value when discarded?
    - But does it not become a cage?

## Layer 5: Future Resilience (Longevity)

Can it withstand time?

1. Trend Independence
    - Will it survive framework obsolescence?
    - Are data, concepts, and outputs independent?

2. Worldview Consistency
    - Are design decisions consistent?
    - Are there principles to return to when confused?
    - Can you state "why it exists" in one sentence?
