---
name: orochi-scientific-figure-standards
description: Fleet-wide standards for scientific figures and statistics — sample size disclosure, H₀ mandatory, mean±SD shading, null controls, event annotations, per-subject summary lines, and per-patient PDF layout. Consolidates ywatanabe guidance from 2026-04-13 neurovista review.
---

# Scientific Figure & Statistics Standards

Any figure, table, or statistical claim an Orochi agent produces for a scientific deliverable (paper, grant, progress report, neurovista review shared with David-sensei / Yanagisawa-sensei) must satisfy the rules below. These are fleet-wide defaults; projects may tighten but never loosen them.

> **Source wording verified**: ✅ 2026-04-13 (msgs #8550, #8556, #8557, #8592, #8593, #8594, #8596, #8599, #8607, #8611, #8613 on #neurovista, pasted in #agent msg #8618).

## 0. Meta rule — capture scientific learnings as they happen

ywatanabe msg #8594: *"科学的スキルということで私とのやり取りの中で学んだことがあればスキルや CLAUDE.md に追記していってください。"*

Every agent that observes a scientific critique — a figure rejection, a stats pushback, a methodology question — must add the learning to a skill or to the project's CLAUDE.md **in the same session**, not later. Scientific standards are institutional knowledge; losing them to context compaction is worse than losing a fix. If you don't own the relevant skill file, ping @mamba-skill-manager with the learning and the source msg id.

## 1. Sample size disclosure

Every figure must make its sample size(s) unambiguous without reading the caption twice (msg #8556: *"サンプルサイズと何が描かれているのか、を正しく書いて欲しい。figure legend な感じで"*).

- State `n` for every group, arm, or subject split shown — in the figure legend.
- For cross-subject aggregates disclose **both** per-subject `n` and cross-subject `N`.
- The legend must also answer *"what is drawn"* in one sentence — the reader must not guess whether a line is mean, median, a single trace, or a smoothed kernel.
- Hidden-in-methods sample sizes are a reject condition.

## 2. Layout conventions

- **One feature per column, one condition per row** (or the project's locked convention), held consistent across subplots in the same figure. Mixing row/column semantics between subplots is a reject condition.
- **Aligned subplots for related metrics.** msg #8557: *"PAC と Bimodality Coeff が整列されずにまざっている、ちょっと整理してみて欲しい"* — when two metrics belong to the same analytical family, they must share aligned axes, aligned time windows, and aligned patient ordering. Never interleave unrelated metric families on one row.
- **No duplicate panels.** msg #8556: *"PAC のヒートマップが二か所に描かれていそう"* — same data must not appear twice in one figure unless the second appearance is explicitly a cross-reference with a note saying so.
- **Axis units always present**, even when the unit is `a.u.`. A blank axis is a reject.
- **Every non-trivial line style needs a legend entry.** Dashed, dotted, thicker, colored — if the reader has to guess what a line means, the legend is missing. This applies to reference lines, thresholds, and null bands as well as data traces.
- **Color is categorical**, not ordinal, unless explicitly annotated as a colormap with a scale bar.
- **Time axis ticks must not be silently rounded.** msg #8607: *"時間軸、tick が丸められてしまっている、正しく書きなおして"* — matplotlib's auto-ticking rounds aggressively. If you're plotting time-locked data, set ticks explicitly and show the real time values; do not let the formatter hide the alignment.

## 3. Summary lines — per-subject mean ± SD, shaded

msg #8556: *"被験者ごとに同じ時間帯で mean and std かな？で shaded line にできますか"*

For time-locked or frequency-locked aggregates:

- Use **mean as the center line** and **shade ± 1 SD** as a translucent band.
- Align the time window across subjects (same `t=0` reference, same window length). Do not mix subject-specific time crops.
- Report the `n` that went into the mean in the panel.
- For small `n` (<5), show individual traces **instead of** (not "in addition to") the shaded band — a "distribution" of 3 samples is misleading.
- SEM may supplement SD (thinner inner band) but does not replace it.

Heatmap equivalent: when aggregating a 2D density (e.g. bimodality coefficient map) across subjects, the aggregate must preserve the distribution shape. msg #8556: *"bimodality heatmap ですが、今一本の線になってる"* — collapsing a bimodal 2D density into a single line is a methodology bug; keep the 2D structure or show the full distribution.

## 4. Event annotations on time-locked plots

For seizure-locked, stimulus-locked, or any event-locked figure:

- **`t=0` must have a clearly visible vertical marker.** msg #8613: *"0h のところ、発作のタイミングには赤ラインがあるといい"* — convention: **red vertical line** at event time, solid, thin enough not to obscure data but thick enough to register at paper zoom.
- Pre-event and post-event windows must be symmetric unless asymmetry is analytically required and labelled.
- Unhelpful reference lines must be removed — msg #8611: *"1h と 24h のラインは消して"*. Reference lines that don't answer a question in the current figure are clutter; delete them rather than leaving them "for context".

## 5. Deliverable structure — per-subject + grand summary

msg #8592/#8593: *"全被験者バージョンで"* + *"二枚目にグランドサマリーを入れて"*.

- **Page 1: per-subject panels** (one subject per panel or one subject per row), with shared axes so the reader can eye-compare.
- **Page 2: grand summary** — cross-subject aggregate + the §6 stats block + effect sizes. One page the PI can read in 90 seconds.
- **Pages 3..N: per-patient detail** pages when the per-subject panels on page 1 are too dense; otherwise omit.
- **Consistent axes** across all pages. No per-page auto-scaling unless the page explicitly flags it.
- **Page footer**: commit hash of the analysis code, data cutoff timestamp, author agent name, figure generation timestamp. Reproducibility provenance lives on the page, not in a separate lab notebook.

## 6. Statistical test reporting block — H₀ mandatory, H₁ when defined

msg #8596: *"統計検定には必ず null hypothesis を書いてください。"*
msg #8599: *"H0 としてくれればいいですね。うんうん。H1 もあれば"*

Every statistical claim (every p-value, every "significant difference", every "no difference") must state the following **inline in the caption or figure annotation**:

| Field | Example | Requirement |
|---|---|---|
| **H₀** | "feature X pre-ictal mean = inter-ictal mean" | **Mandatory.** "No difference" is not a hypothesis — state the equality explicitly. |
| **H₁** | "feature X pre-ictal mean > inter-ictal mean" | **Include when defined.** One-sided vs two-sided is decided *before* seeing the data. |
| **Test** | "paired Wilcoxon signed-rank" | Parametric/non-parametric, paired/unpaired. |
| **α** | "0.05" | Default 0.05; state it. |
| **Correction** | "Benjamini-Hochberg, 127 comparisons" | Method and family size. |
| **Effect size** | "Cliff's δ = 0.34 [95% CI 0.21, 0.48]" | **Required.** p-values are not effect sizes. |
| **Null control** | "shuffled labels, 1000 permutations" | Required for time-locked / condition-locked claims. |

A claim that can't fill this block is not yet ready to be published.

## 7. Null / sanity controls — watch the FDR floor

msg #8550 (implied): a grand summary showed 18–25% of features "significant" under a shuffled-label null — i.e. the null is already noisy at the FDR floor. Rules:

- Every condition plot needs a **label-shuffled control** on the same axes as the real data so readers can eyeball the effect size.
- If the null control itself fires above the nominal FDR, the methodology has a bug **or** the test family is not independent — investigate before claiming any real effect. A real effect at 40% significant and a null at 25% significant is not a real effect.
- Classifier "chance level" lines must come from a permutation null, not a theoretical `1/K`, unless the sampler is exactly balanced and the prior is flat.
- Figures with no null control are preliminary; label them as such in the title.

## 8. Anti-patterns (hard rejects when shared with collaborators)

Context: deliverables in this channel are shared with David-sensei and Yanagisawa-sensei (msg #8556). Paper-level quality is the bar; lab-internal shortcuts are not acceptable.

- **"Representative example"** without a selection criterion. State the criterion or replace with a random draw + null.
- **Bar charts without overlaid dots** for `n < 50` — bars hide bimodality and outliers.
- **Dual-axis line plots** with independently-rescaled axes. Split into stacked subplots instead.
- **`jet` / `hsv` colormaps** — perceptually non-uniform. Use `viridis`, `cividis`, `magma`, or a named diverging map.
- **"p < 0.05"** as the only statistic. See §6.
- **"Trend toward significance"** — it either crossed α or it didn't.
- **Silent time-axis rounding** — see §2.
- **Duplicate panels** — see §2.
- **Manual Photoshop touch-ups** — the figure must be regenerable end-to-end from code.

## 9. Tooling

- `scitex-python` plotting utilities should emit figures that satisfy §1–§3 by default. Gaps are scitex-python bugs — file them.
- PDF generation goes through one pipeline, no hand edits.
- Figure scripts live under `scripts/` (SciTeX convention), output under `./data/` or `./figures/`, never into the repo root.
- Commit hash for the footer comes from `git rev-parse --short HEAD` at generation time.

## Related

- memory `feedback_visibility_is_existence.md` — UI / screenshot as first-class deliverable
- `fleet-communication-discipline.md` — how to report scientific findings to ywatanabe
- `scitex-python` plotting module — implementation home for the defaults described here
- (future) `reference_neurovista_review_protocol.md` — end-to-end review workflow

## Change log

- **2026-04-13 (initial + verified)**: Drafted from general principles, then reconciled against ywatanabe msgs #8550/#8556/#8557/#8592/#8593/#8594/#8596/#8599/#8607/#8611/#8613 pasted in #agent #8618. Added §0 meta rule, §2 aligned-subplots + duplicate-panels + time-axis, §3 per-subject aligned windows + bimodality heatmap note, §4 event annotations (red line at `t=0`, remove 1h/24h reference lines), §5 per-subject + grand summary page layout, §6 H₀ mandatory + H₁ when defined, §7 FDR-floor rule from msg#8550 grand summary. Author: mamba-skill-manager.
