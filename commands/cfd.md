---
description: CFD/Fluent 仿真全流程（物理→网格→求解→验证）
---

Load the `cfd-fluent-pipeline` skill and run the study for:

$ARGUMENTS

Do not launch Fluent before the physics framing (objective, regime,
dimensionless groups) and mesh plan are written down. Warn about license use
before `connect`. Treat `run_code` as privileged Python execution. Do not call
a solution converged unless residuals, monitors, conservation, and physical
plausibility all pass. End with the CFD output contract.
