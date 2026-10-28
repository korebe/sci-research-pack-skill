---
name: CFD Fluent Pipeline
description: >-
  Run an auditable CFD study end to end with Ansys Fluent, PyFluent and the
  official pyfluent-mcp server: frame the physics, check mesh and y+, choose
  solver and turbulence model, run a smoke test, judge convergence by residuals
  plus monitors plus conservation, validate against experiment or theory, and
  produce publication-grade figures and a methods paragraph. Use for Fluent,
  PyFluent, CFD, 流体仿真, 网格, 边界条件, 湍流模型, 残差, 收敛, 后处理, or
  OpenFOAM comparison.
license: MIT
---

# CFD / Fluent Pipeline

You operate Fluent through MCP. The MCP is the **hands**; this skill is the
**judgment**. Never let a tool call substitute for a physics decision.

## 0. Pre-flight

1. Confirm the objective quantity (pressure drop, drag, lift, heat transfer
   coefficient, mixing efficiency, etc.) and its acceptance criterion.
2. Confirm the regime: steady/transient, laminar/turbulent, incompressible/
   compressible, single/multiphase, reacting, conjugate heat transfer,
   rotating machinery.
3. Compute the governing dimensionless groups before meshing:
   Re, Ma, Pr, Ra, We, Kn, y+ target.
4. State that launching Fluent **will occupy a license**. Ask before launching
   if the user has not authorized it.
5. Record the Fluent version, solver precision, and machine.

If any of 1–3 is unknown, stop and ask. A beautiful converged wrong problem is
still wrong.

## 1. Tool map (official `ansys-fluent-mcp`)

The upstream `fluent-cfd` skill was written against an older community server
whose tool names differ. Map them as follows:

| Older name in `fluent-cfd` | Official pyfluent-mcp tool |
|---|---|
| `server_info` | `session_status` + `solver_status` |
| `launch_fluent` | `connect` |
| `connect_to_fluent` | `connect` (attach mode) |
| `read_case` | `run_code` → `solver.file.read_case(...)` |
| `run_tui` | `run_code` → `solver.tui.<path>` |
| `iterate` | `run_code` → `solver.solution.run_calculation.iterate(...)` |
| `write_case_data` | `run_code` → `solver.file.write_case_data(...)` |
| `execute_python` | `run_code` (same risk; gate it) |
| `exit_fluent` | `disconnect` |

Supporting tools: `find_api`, `get_help`, `get_state`, `get_targeted_context`,
`list_named_objects`, `find_named_object`, `select_named_objects`,
`validate_code`, `summarize_setup`, `simulation_report`, `screenshot`,
`mesh_quality`, `list_fields`, `compare_files`.

**`run_code` executes arbitrary Python inside the Fluent session.** Treat it as
a privileged operation: only run code you have read, never paste unreviewed
model output, and never enable `PYFLUENT_MCP_ENABLE_PYTHON` in an untrusted
session.

## 2. Gates

### Gate 1 — Physics
- Geometry cleaned, units confirmed, coordinate system stated.
- Fluid properties and operating conditions sourced (not guessed).
- Boundary conditions physically justified; turbulence inlet conditions
  (intensity + hydraulic diameter) stated.

### Gate 2 — Mesh
- `mesh_quality` run and recorded: minimum orthogonal quality, maximum
  skewness, maximum aspect ratio, cell count.
- y+ target chosen from the wall treatment:
  wall-function → y+ ≈ 30–300; low-Re / enhanced wall treatment → y+ ≈ 1.
- Mesh independence: at least two meshes (ideally three), report the
  quantity of interest and the observed order of convergence or % change.
- Boundary zone names are human-readable and match the BC plan.

### Gate 3 — Solver
- Pressure-based vs density-based justified.
- Turbulence model justified physically (k-ε for fully turbulent internal
  flows; k-ω SST for adverse pressure gradients / separation; transition
  models only with evidence).
- Numerics: discretization order, relaxation, initialization, time step /
  CFL, convergence criteria.
- `summarize_setup` used to produce a human-readable setup record.

### Gate 4 — Smoke test
- Run 20–50 iterations (or a few time steps) first.
- Check: no reversed flow at outlets without physical cause, no divergence,
  no NaN, residuals decreasing, monitors stable.
- Only then run the full solve.

### Gate 5 — Convergence
Residuals alone are **not** convergence. Require all four:
1. Residuals plateau (typically < 1e-4 for continuity/momentum, tighter for
   energy/species — justify the target).
2. Monitors for the objective quantity stabilize (report drift over the last
   N iterations).
3. Integral conservation: mass imbalance < 0.1–1 % (state your tolerance),
   energy balance for thermal cases.
4. Physical plausibility: values inside the expected range from theory,
   experiment, or literature.

If any check fails, do not "improve" the plot. Diagnose: mesh, BC, relaxation,
initialization, turbulence model, or transient time step.

### Gate 6 — Validation
- Compare against at least one independent source: analytical solution,
  benchmark case, experiment, or published DNS/LES.
- Report error with uncertainty, not a single best-case number.
- Grid convergence index (GCI) or equivalent where feasible.
- State the validity envelope: Re range, geometry, assumptions.

### Gate 7 — Reporting
- `simulation_report` for the run record.
- `screenshot` for key contours; export publication figures separately with
  `scipilot-figure` conventions.
- Save case/data with a deterministic name; never overwrite the baseline.
- Methods paragraph must contain: solver, turbulence model, mesh size and
  quality, BCs, numerics, convergence criteria, validation source, software
  version.

## 3. Common failure modes

| Symptom | First suspects | Do not |
|---|---|---|
| Residuals stall at 1e-2 | poor mesh, BC inconsistency, bad initial guess | lower the convergence target |
| Reversed flow at outlet | outlet too close to wake, wrong BC | switch outlet to pressure-inlet blindly |
| Divergence in first 50 iters | relaxation too high, bad mesh, compressibility | reduce time step only |
| Monitors oscillate | unsteady physics run as steady | call it "converged" |
| Mass imbalance > 5 % | leaking zone, wrong interior boundary | ignore it |
| y+ far from target | first-layer height wrong | change wall treatment to match mesh |

## 4. Output contract

```
CASE: <name / version>
OBJECTIVE: <quantity + acceptance criterion>
MESH: <cells, min orthogonal quality, max skewness, y+ range>
MODEL: <solver, turbulence, multiphase/energy>
BC: <inlet/outlet/wall summary>
CONVERGENCE: residuals <x>, monitor drift <y>, mass imbalance <z>%
VALIDATION: <source, error, uncertainty>
LICENSE: <session state, released yes/no>
FILES: <case, data, report, figures>
OPEN RISKS: <list>
```

## 5. No Fluent license?

Use the `fluidsim` skill for spectral/LBM Python simulations, or OpenFOAM via
the optional MCP in `config/mcp-optional.md`. Do not claim Fluent-equivalent
accuracy for a different solver without validation.
