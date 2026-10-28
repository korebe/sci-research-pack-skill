# Cell 写作规范（Research Article）

> Cell Press 的规则按刊、按年调整。本文给的是**结构与评审逻辑**，数字为常见参考值；
> 投稿前必须以目标刊（Cell / Cell Reports / Molecular Cell / Cell Systems…）的
> Guide for Authors 为准。官方入口见文末。

---

## 1. Cell 要什么

Cell 编辑最看重的不是"做了很多实验"，而是：

1. **Conceptual advance**：是否提出了一个新的机制、模型、原则，而不只是又一个案例。
2. **Mechanistic depth**：是否把"是什么"推进到"为什么/怎么发生"。
3. **Causal evidence**：是否有 loss-of-function / gain-of-function / rescue 这类因果链，而不只是相关性。
4. **Broad relevance**：是否对 Cell 的广泛生命科学读者有意义。

一句话：**Cell 要的是"机制 + 概念"，不是"数据量"。**

---

## 2. 结构顺序

1. Title
2. Authors
3. Affiliations
4. **Lead contact**（通讯作者，单独标注）
5. **Summary**（单段，约 150 词）
6. **Graphical abstract**
7. **Highlights**（3–4 条，每条 ≤85 字符）
8. **eTOC blurb**（约 50 词）
9. Introduction
10. Results（带 claim-style 小标题）
11. Discussion
12. **Limitations of the study**（必写）
13. **STAR Methods**
14. **Resource availability**
15. Author contributions
16. Declaration of interests
17. References

---

## 3. 硬指标（参考值）

| 项目 | 常见要求 |
|---|---|
| 标题 | ≤ **120 个字符**（含空格）；避免缩写；要能被非本行读者读懂 |
| Summary | 约 **150 词**，单段，不引用文献，不含未定义缩写 |
| Highlights | **3–4 条**，每条 ≤ **85 个字符**（含空格） |
| eTOC blurb | 约 **50 词**，面向普通读者，一句话说清"发现了什么、为什么重要" |
| Graphical abstract | 一张图，与 Summary 一致，不引入新数据 |
| 主图 | 通常 **4–7 个** display item；面板要有明确的逻辑顺序 |
| 参考文献 | 按刊型变化大，以 Guide 为准 |

> 再次提醒：以上数字是常见值，不是跨刊通用常量。

---

## 4. Summary 的四句结构

Cell 的 Summary 比 Nature 更"机制导向"：

1. **Background**：这个生物学问题为什么重要（一句）。
2. **Gap**：此前不知道什么（一句）。
3. **Result + mechanism**：我们发现了什么、机制是什么（两到三句，核心）。
4. **Implication**：对领域/疾病/治疗的意义（一句，克制）。

不要：

- 在 Summary 里写"we performed RNA-seq, ChIP-seq, and..."。
- 用 "novel"、"first"、"unprecedented" 撑场面。
- 把 Discussion 的推测塞进 Summary。

---

## 5. Results 的写法

Cell 的 Results 小标题通常是**一个完整的 claim**，不是 "RNA-seq analysis"：

- 好：`X recruits Y to promote Z`
- 差：`RNA-seq of X-deficient cells`

每个 Results 小节的标准结构：

1. 小标题给出 claim。
2. 第一段说明**为什么做这个实验**（问题，不是操作）。
3. 关键图 + 关键数字（n、效应量、P、置信区间）。
4. 对照与替代解释的排除。
5. 最后一句**桥接**到下一小节。

Cell 审稿人非常在意：

- 是否有 **rescue**（把表型救回来）。
- 是否有 **epistasis / 上位性** 实验确定通路顺序。
- 是否有 **in vivo** 验证（若声称生理相关）。
- 抗体/试剂是否有 validation（ knockdown/knockout 验证、RRID）。
- 样本量、重复数、是否盲法。

---

## 6. Limitations of the study（必写）

Cell 要求单独一节，通常 3–5 条，每条：

- 具体（不是 "further studies are needed"）。
- 指向本文的边界（模型系统、样本来源、时间尺度、技术分辨率）。
- 说明它如何影响结论的适用范围。

这一节写得好，会显著降低审稿人对 overclaim 的攻击面。

---

## 7. STAR Methods

STAR = **S**tructured, **T**ransparent, **A**ccessible **R**eporting。它不是"补充材料"，是正文的一部分。

必备子节：

1. **Key resources table**（试剂、抗体、细胞系、软件、沉积数据；抗体要有 RRID）
2. **Experimental model and study participant details**
   - 人类受试者：伦理批号、知情同意、纳入排除、人口学
   - 动物：品系、来源、年龄、性别、饲养、伦理批号、ARRIVE 关键项
   - 细胞系：来源、STR 鉴定、支原体检测、传代数
3. **Method details**（按实验逐个写，足以复现）
4. **Quantification and statistical analysis**
   - 每个检验的名称、n、双尾/单尾、配对与否、校正方法
   - 误差棒定义（SD / SEM / 95% CI）
   - 样本量如何确定（power analysis 或先验）
   - 排除标准、盲法、随机化
5. **Data and code availability**
   - accession number、仓库 URL、DOI
   - 自定义代码的版本与许可证

---

## 8. Resource availability

标准三行：

- **Lead contact**：姓名 + 邮箱。
- **Materials availability**：是否可通过 MTA 获取；unique reagents 的存放。
- **Data and code availability**：同 STAR Methods，但更简短。

---

## 9. 图表

- Graphical abstract 与 Summary 必须一致；不要放未在正文出现的数据。
- 主图面板按论证顺序编号（A→B→C），不要按实验日期。
- 每个面板：n、误差棒、统计检验、尺度 bar、单位。
- 颜色要色盲安全；不要用红绿对比作为唯一区分。
- Western blot 必须给原始条带（补充图），并标注分子量、上样量、重复次数。
- 显微镜图必须标注 scale bar、染色/通道、z-stack 投影方式。

---

## 10. 常见拒稿/大修原因

1. **只有相关性，没有因果**（缺 rescue / epistasis / loss-of-function）。
2. **机制停留在"可能通过 X"**，没有直接证据。
3. **in vitro 结论外推到 in vivo / 人类**，没有验证。
4. **n 太小、重复是技术重复而非生物学重复**。
5. **抗体/试剂未验证**，或关键试剂不可得。
6. **统计报告不完整**（只给 P，不给效应量与 CI）。
7. **Limitations 缺失或写成套话**。
8. **Graphical abstract 与 Summary 不一致**。

---

## 11. 官方入口

- Cell Guide for Authors: <https://www.cell.com/cell/authors>
- Cell Press STAR Methods: <https://www.cell.com/star-methods>
- Cell Press author resources: <https://www.cell.com/author-resources>
- Reporting guidelines: CONSORT / PRISMA / STROBE / ARRIVE / TRIPOD
