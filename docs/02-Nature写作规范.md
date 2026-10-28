# Nature 正刊写作规范（Research Article）

> 权威依据：本包 `skills/vendor/nature-shared/journal-formats/nature.md`（随 nature-skills 分发），
> 以及 Nature 官网 Guide to Authors。**数字会变，投稿前必须再核对一次官网。**
> 子刊（Nature Communications、NMI、Nat Methods 等）规则不同，见 `nature-portfolio-playbook`。

---

## 1. Nature 要什么

Nature 编辑的判断顺序不是"写得漂亮"，而是：

1. **是否重要**：结论是否对跨学科读者都有意义，而不只是对本领域有意义。
2. **是否新**：是否第一次给出某个机制、材料、方法或观测。
3. **是否可靠**：结论是否有足够的对照、独立验证和统计支撑。
4. **是否可读**：非本行读者能否在摘要和前两段看懂问题与答案。

一句话：**Nature 不是"最长的论文"，是"最重要的那一句话 + 足够硬的证据"。**

---

## 2. 结构顺序（必须按此顺序 audit）

1. Title
2. Authors
3. Affiliations / present addresses
4. **Bold summary paragraph**（约 200 词）
5. Main text
6. Main references
7. Tables
8. Figure legends
9. Methods（含独立的 Data Availability / Code Availability）
10. Methods references
11. Acknowledgements
12. Funding statement
13. Author contributions
14. Competing-interests declaration
15. Additional information（Supplementary Information、通讯作者）
16. Extended Data figure/table legends

---

## 3. 硬指标（正刊 Article，参考值）

| 项目 | 要求 |
|---|---|
| 标题 | ≤ **75 个字符**（含空格），最多两行；避免数字、缩写、缩写词、标点；避免技术术语和主动动词 |
| Summary paragraph | 约 **200 词**，可引用文献；面向非本领域读者；少用数字/缩写/测量值 |
| 正文 | 6 页约 **2,500 词 + 4 个中等 display item**；8 页约 **4,300 词 + 5–6 个**；标题、作者、致谢、参考文献不计入 |
| 小标题 | ≤ **40 个字符**（含空格） |
| 主参考文献 | 约 **50 条**以内（随篇幅调整） |
| Methods | 通常 ≤ **3,000 词**，必要时可更长；不放图/表 |
| 图注 | ≤ **250 词**，以一句简短标题开头 |
| Extended Data | ≤ **10 个**多面板图/表 |
| 初始投稿文件 | 正文+图合并为一个 Word 或 PDF，≤ **30 MB**；图注与图同页；加行号 |

> 这些是旗舰刊 *Nature* 的规则，不要套到子刊。

---

## 4. Summary paragraph 的五句结构

Nature 的摘要不是 IMRaD 摘要，而是一个"给全科学界看的短故事"：

1. **Broad field**：这个领域在关心什么（一句，最大公约数）。
2. **Background / gap**：已知什么、缺什么（一到两句）。
3. **Here we show**：本文做了什么、发现了什么（核心句，通常以 "Here we show that..." 开头）。
4. **Key result**：最硬的一个结果/机制/数字。
5. **Implication**：它改变了什么，下一步是什么。

要求：

- 不出现 "novel"、"important"、"significantly"（除非是统计显著）这类空词。
- 不引用本文图号。
- 不把 Methods 写进摘要。
- 最后一句不要过度外推；Nature 审稿人最常打的就是 overclaim。

---

## 5. 标题写法

好标题的三个特征：

- 有一个**具体名词**（机制、材料、现象、对象），不是一个抽象名词。
- 有一个**动词或关系**，让读者知道发生了什么。
- 不靠冒号和副标题堆信息。

避免：

- "A novel approach to..." / "Study on..." / "Research on..."
- 未被正文支持的大词：universal、unprecedented、first-ever、paradigm shift。
- 缩写（除非比全称更常用，如 DNA、RNA、COVID-19）。

---

## 6. Results 与 Discussion

**Results 的每一段只做一件事**：

1. 这一段的 claim（一句）。
2. 哪个图/表支持它。
3. 关键数字（带误差/样本量）。
4. 必要的对照或排除替代解释。
5. 一句过渡到下一段。

不要把 Results 写成"我们做了 A，然后做了 B"的实验日志。读者要的是**证据链**，不是**操作顺序**。

**Discussion 要回答四个问题**：

1. 我们知道了什么原来不知道的？
2. 为什么这个结果不是 artifact？（对照、独立验证、机制）
3. 边界在哪里？（模型、样本、体系、时间尺度）
4. 下一步最值得做的实验是什么？

Nature 的 Discussion 通常很短（几段），不重复 Results，不写成综述。

---

## 7. Methods

- 必须足以让别人复现，而不是"我们按标准流程"。
- 用短粗体小标题；统计、试剂、动物模型可单列。
- 不放图/表；必须放的走 Extended Data 或 SI。
- Methods 参考文献编号接在主文之后继续。
- 引用已存档的 protocol（protocols.io、Bio-protocol 等）并注明。
- 自定义代码/算法：单独的 Code Availability，给出仓库 URL 和版本/tag。

---

## 8. Extended Data 与 Supplementary Information

- 支撑主结论的完整数据放 **Extended Data**（≤10 个多面板图/表）。
- SI 只放"审稿需要、但太大/太专门/不适合印刷"的材料。
- 每个 SI 文件都要在正文被引用；SI 图 ≤640×480 px；单个音视频/PDF ≤30 MB，总计 ≤150 MB。
- 需要 `SIGuide.doc`：每个文件的标题 + ≤50 词说明（音视频 ≤100 词）。

---

## 9. 声明与政策

必须齐全：

- **Data Availability**：数据在哪、accession number、限制条件。
- **Code Availability**：核心自定义代码的仓库、版本、许可证。
- **Author contributions**：用 CRediT 或等价描述，不能只写 "all authors contributed"。
- **Competing interests**：即使没有也要写 "The authors declare no competing interests."
- **Funding**：只写真正支持该项工作的 grant。
- **Ethics**：动物/人类/临床注册/知情同意，按对应报告规范（ARRIVE/CONSORT/PRISMA）。
- **AI 使用**：LLM 不能署名；人类作者对原创性、准确性、诚信负全责；在 Methods 或合适章节披露 LLM 的使用方式与范围。

---

## 10. 最常见的 desk-reject / 一审大修原因

1. ** Significance 不够**：结论只对本领域有意义。
2. ** overclaim**：摘要最后一句比数据走得更远。
3. **缺关键对照**：无法排除替代解释。
4. **统计不完整**：只有 P 值，没有 n、效应量、置信区间、多重比较校正。
5. **图不能独立读懂**：图注缺 n、误差棒定义、尺度、统计检验。
6. **数据/代码不可得**：没有 accession 或仓库。
7. **写作不可读**：前三段全是术语，非本行读者看不懂问题是什么。

---

## 11. 官方入口

- Nature Guide to Authors: <https://www.nature.com/nature/for-authors/formatting-guide>
- Nature Portfolio editorial policies: <https://www.nature.com/nature-portfolio/editorial-policies>
- Reporting standards: <https://www.nature.com/nature-portfolio/editorial-policies/reporting-standards>
- 本包权威细则：`skills/vendor/nature-shared/journal-formats/nature.md`
- Nature 图表规范：`skills/vendor/nature-figure/SKILL.md`
