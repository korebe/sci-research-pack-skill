# CFD 验证清单（Fluent / 通用）

> 目标：让审稿人相信你的数不是"跑出来的"，而是"验证过的"。

---

## 1. 物理与量纲

- [ ] 目标量明确（压降、阻力、升力、Nu、混合效率、分离角…），并有验收标准。
- [ ] 几何、单位、坐标系、重力方向已确认。
- [ ] 流体物性来源明确（不是"默认值"）。
- [ ] 工况：稳态/瞬态、层流/湍流、不可压/可压、单相/多相、是否传热/反应/旋转。
- [ ] 无量纲数已算：Re、Ma、Pr、Ra、We、Kn。
- [ ] 湍流入口条件：湍流强度 + 水力直径（或 k/ω 直接给）。
- [ ] 边界条件物理上可实现（不是"因为收敛所以改成 pressure-inlet"）。

## 2. 网格

- [ ] 网格类型与生成工具已记录（poly-hexcore / tetra / hex）。
- [ ] 单元数、节点数、最小正交质量、最大 skewness、最大 aspect ratio 已记录。
- [ ] 边界层：第一层高度、层数、增长率；y+ 目标与壁面处理匹配。
  - 壁面函数：y+ ≈ 30–300
  - 低 Re / enhanced wall treatment：y+ ≈ 1
- [ ] 至少两套网格（理想三套），报告目标量随网格的变化。
- [ ] 网格无关性：GCI 或目标量变化 < 设定阈值（如 2%）。
- [ ] 边界 zone 命名可读，且与 BC 计划一一对应。
- [ ] 无负体积、无孤立单元、无未连接区域。

## 3. 求解设置

- [ ] 压力基 vs 密度基有理由。
- [ ] 湍流模型有物理理由：
  - 充分发展内流：k-ε（可扩展壁面函数）
  - 逆压梯度/分离：k-ω SST
  - 转捩：γ-Reθ 等，且有实验依据
  - LES/DES：只在网格与时间步支持时使用
- [ ] 离散格式：对流项阶数、压力-速度耦合方案。
- [ ] 松弛因子、初始化方式、时间步/CFL。
- [ ] 收敛判据事先设定（不是跑完再挑一个好看的）。
- [ ] `summarize_setup` 已生成可读的设置记录。

## 4. 试跑（smoke test）

- [ ] 先跑 20–50 步（或几个时间步）。
- [ ] 无发散、无 NaN、无温度/压力越界。
- [ ] 出口无明显非物理回流。
- [ ] 残差在下降，monitor 没有剧烈振荡。
- [ ] 通过后再跑完整算例。

## 5. 收敛（四项全过才算）

- [ ] **残差**：连续/动量 < 1e-4（或设定值）；能量/组分更严；且进入平台。
- [ ] **Monitor**：目标量在最后 N 步内漂移 < 设定阈值（如 0.5%）。
- [ ] **守恒**：质量不平衡 < 0.1–1%（写明容差）；传热算例能量平衡。
- [ ] **物理合理性**：目标量落在理论/实验/文献的合理范围。

> 残差下降 ≠ 收敛。残差平台但 monitor 漂移，是没收敛。
> 残差还在降但 monitor 已稳，可能只是数值耗散，仍要检查守恒。

## 6. 验证与确认（V&V）

- [ ] **Verification**：代码/离散是否正确（网格收敛、时间步收敛、与解析解对比）。
- [ ] **Validation**：物理模型是否代表真实（与实验/基准数据对比）。
- [ ] 至少一个独立来源：解析解、基准案例、实验、已发表 DNS/LES。
- [ ] 报告误差：相对误差、L2 误差、或 GCI，而不是"看起来一致"。
- [ ] 给出适用范围：Re 范围、几何、假设、模型局限。
- [ ] 不确定度：输入不确定度如何传播到目标量（可用 `uncertainty-and-units`）。

## 7. 后处理与出图

- [ ] 云图：色标范围统一、标注单位、不截断关键区域。
- [ ] 矢量图/流线：密度适中，不遮挡结构。
- [ ] 定量曲线：与实验/理论叠图，误差棒/带宽清晰。
- [ ] 图注写清：Re、模型、网格、BC、变量定义。
- [ ] 保存 case/data，命名可追溯；不覆盖 baseline。

## 8. 论文 Methods 段落模板

> Simulations were performed with Ansys Fluent `<version>` using a
> `<pressure-/density-based>` solver. The `<geometry>` was meshed with
> `<tool>`; the baseline mesh contained `<N>` cells with a minimum orthogonal
> quality of `<q>` and maximum skewness of `<s>`. A `<turbulence model>` model
> with `<wall treatment>` was used, targeting y+ `<range>`. Inlet conditions
> were `<...>`; outlet `<...>`; walls `<...>`. Second-order upwind schemes were
> used for `<...>`, with `<coupling scheme>` pressure–velocity coupling.
> Convergence was assessed by residuals below `<...>`, stabilization of
> `<monitor>` to within `<...>` over the last `<N>` iterations, and a global
> mass imbalance below `<...>`. Mesh independence was verified with `<N>`
> meshes; the GCI for `<quantity>` was `<...>`. The model was validated against
> `<source>`, with a relative error of `<...>` for `<quantity>`.

## 9. 常见审稿人问题（提前准备答案）

1. 为什么选这个湍流模型？做过敏感性分析吗？
2. 网格无关性怎么做的？GCI 是多少？
3. y+ 分布是什么？壁面处理与 y+ 匹配吗？
4. 收敛判据是什么？只看残差吗？
5. 与实验对比了吗？误差多少？
6. 二维/轴对称假设合理吗？
7. 入口湍流条件怎么定的？
8. 时间步/CFL 怎么选的？做过时间步无关性吗？
9. 这个结论在什么范围内成立？
10. 代码/数据能提供吗？
