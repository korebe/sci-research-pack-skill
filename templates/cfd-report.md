# CFD Study Report 模板

> 用于组会/论文 Methods/审稿回复。先填数字，再写解释。

---

## 1. Case identity

| Item | Value |
|---|---|
| Case name | |
| Solver / version | Ansys Fluent <version> |
| Solver type | pressure-based / density-based |
| Steady / transient | |
| Date / operator | |
| Git commit of setup scripts | |

## 2. Physics

| Item | Value |
|---|---|
| Objective quantity | |
| Acceptance criterion | |
| Fluid / material | |
| Re | |
| Ma | |
| Pr / Ra / We / Kn (if relevant) | |
| Turbulence model | |
| Wall treatment | |
| y+ target / achieved | |

## 3. Geometry and mesh

| Item | Value |
|---|---|
| Geometry source | |
| Mesher | |
| Cell count | |
| Node count | |
| Min orthogonal quality | |
| Max skewness | |
| Max aspect ratio | |
| Boundary layer | first height / layers / growth |
| Mesh independence | 2–3 meshes; GCI or % change |

## 4. Boundary conditions

| Zone | Type | Value | Justification |
|---|---|---|---|
| inlet | | | |
| outlet | | | |
| wall | | | |
| symmetry / periodic | | | |

## 5. Numerics

| Item | Value |
|---|---|
| Pressure–velocity coupling | |
| Convection scheme | |
| Gradient scheme | |
| Relaxation | |
| Initialization | |
| Time step / CFL | |
| Convergence criteria | residuals < ; monitor drift < ; mass imbalance < |

## 6. Results

| Quantity | Value | Unit | Uncertainty | Reference | Error |
|---|---|---|---|---|---|
| | | | | | |

## 7. Validation

- Source:
- Comparison method:
- Relative / L2 error:
- Validity envelope:

## 8. Figures

| Figure | What it proves | File |
|---|---|---|
| | | |

## 9. Risks and open issues

1.
2.
3.

## 10. Methods paragraph (paper-ready)

> Simulations were performed with Ansys Fluent `<version>` ...
