# Research plan

## Goal and question

Evaluate whether a transparent multi-factor Smart ER rule can improve appropriate destination utility over nearest-hospital and seeded-random baselines in fixed synthetic or institutionally approved scenarios.

## Hypothesis framework

Independent variable: selection strategy (nearest, seeded random, Smart ER). Dependent measures: estimated arrival time, appropriate destination/resource/specialty match rates, congestion penalty, and a pre-registered composite utility. Controls: fixed scenario dataset, reference-data snapshot, weight set, route estimator, and random seed.

## Procedure and reproducibility

Assign experiment ID, dataset version/checksum, algorithm version, configuration weights, and seed. For each scenario, calculate all three strategies, export row-level JSON and CSV, and run one-at-a-time plus grid sensitivity analysis for weights. Report ties and missing data instead of silently breaking them.

## Limitations and risk

Synthetic/retrospective results do not establish clinical benefit. Hospital resources and congestion are time-sensitive; no real availability may be inferred. De-identify data, minimize location/medical fields, obtain governance/ethics review, and never use experimental output as dispatch authority. No results have been created or claimed in this repository.
