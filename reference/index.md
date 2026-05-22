# Package index

## E-process core

- [`compute_eprocess()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/compute_eprocess.md)
  : Compute predictive e-processes from log predictive densities.
- [`make_predictive_diagnostic()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/make_predictive_diagnostic.md)
  : Common interface for predictive e-diagnostics.
- [`summarise_predictive_diagnostic()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/summarise_predictive_diagnostic.md)
  : Summarise predictive e-diagnostic results.
- [`plot_eprocess()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/plot_eprocess.md)
  : Plot a predictive e-process

## Simulation and densities

- [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md)
  : Create movement-HMM parameters
- [`simulate_hmm_movement()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hmm_movement.md)
  : Simulate movement from a finite-state HMM
- [`simulate_hmm_movement_copula()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hmm_movement_copula.md)
  : Simulate movement with residual step-angle dependence
- [`simulate_hmm_movement_local_copula()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hmm_movement_local_copula.md)
  : Simulate movement with localized residual copula dependence
- [`simulate_hsmm_movement()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hsmm_movement.md)
  : Simulate movement from an HSMM-like dwell-time generator
- [`simulate_hmm_movement_ar_angles()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hmm_movement_ar_angles.md)
  : Simulate movement with autoregressive angle residuals
- [`simulate_wrapped_normal()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_wrapped_normal.md)
  : Simulate wrapped-normal angles
- [`d_wrapped_normal()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/d_wrapped_normal.md)
  : Wrapped-normal density
- [`p_wrapped_normal()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/p_wrapped_normal.md)
  : Wrapped-normal distribution function
- [`hmm_forward_filter()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_forward_filter.md)
  : Forward filter a finite-state HMM
- [`hmm_predictive_log_density()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_predictive_log_density.md)
  : Compute observable HMM predictive log-density
- [`hmm_movement_log_emission()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_movement_log_emission.md)
  : Compute state-dependent log-emission densities
- [`hmm_movement_predictive_log_density()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_movement_predictive_log_density.md)
  : Compute movement-HMM observable predictive log-density

## Diagnostics

- [`diagnostic_extra_state()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_extra_state.md)
  : Diagnostic for an insufficient number of states
- [`diagnostic_angle()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_angle.md)
  : Diagnostic for angular distribution misspecification
- [`diagnostic_step_angle_dependence()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_step_angle_dependence.md)
  : Diagnostic for residual step-angle dependence
- [`diagnostic_duration_blockwise()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_duration_blockwise.md)
  : Blockwise diagnostic for duration misspecification
- [`diagnostic_long_horizon_straightness()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_long_horizon_straightness.md)
  : Long-horizon straightness diagnostic
- [`diagnostic_composite_envelope()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_composite_envelope.md)
  : Conservative finite-family composite-null diagnostic

## Diagnostic combinations and localization

- [`diagnostic_mixture()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_mixture.md)
  : Predictable mixture of diagnostic e-increments
- [`diagnostic_switch()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_switch.md)
  : Predictable switch between diagnostics
- [`localize_predictive_diagnostic()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/localize_predictive_diagnostic.md)
  : Localize or temper a predictive diagnostic
- [`time_window_weights()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/time_window_weights.md)
  : Time-window localization weights
- [`hmm_predictive_state_weights()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_predictive_state_weights.md)
  : Predictive state weights from an HMM filter

## Feature and composite helpers

- [`gaussian_copula_log_density()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/gaussian_copula_log_density.md)
  : Gaussian copula log-density
- [`hmm_movement_rosenblatt_residuals()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_movement_rosenblatt_residuals.md)
  : Sequential Rosenblatt residuals for movement HMMs
- [`compute_block_straightness()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/compute_block_straightness.md)
  : Compute block straightness
- [`simulate_block_straightness_values()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_block_straightness_values.md)
  : Simulate block straightness values
- [`fit_block_straightness_laws()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/fit_block_straightness_laws.md)
  : Fit beta approximations to block-straightness laws
- [`hmm_family_predictive_log_density()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_family_predictive_log_density.md)
  : Predictive log-densities for a finite HMM family
- [`hmm_composite_envelope_log_density()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_composite_envelope_log_density.md)
  : Composite-envelope predictive log-density
- [`summarise_hmm_parameter_family()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/summarise_hmm_parameter_family.md)
  : Summarise a finite HMM parameter family

## Simulation-study helpers

- [`estimate_hmm_movement_oracle()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/estimate_hmm_movement_oracle.md)
  : Estimate movement-HMM parameters from known states
- [`perturb_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/perturb_hmm_movement_parameters.md)
  : Perturb movement-HMM parameters
- [`summarise_hmm_parameter_error()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/summarise_hmm_parameter_error.md)
  : Summarise parameter error for simulated HMMs
