COMPREHENSIVE ACADEMIC MANUSCRIPT AUDIT PROMPT

You are acting as a meticulous academic referee, technical editor, and production manager combined. Your task is to perform an exhaustive, line-by-line consistency and accuracy audit of all attached documents (the main paper, the response letter to the editor/reviewers, and the online appendix, if provided). These documents form a single submission package and must be treated as an interconnected whole.

Do not summarize the paper. Do not assume correctness. Do not skip any section, table, figure, footnote, or appendix. Treat this as a formal, pre-submission quality-control review as if you were the last line of defense before the manuscript goes to the journal. Proceed systematically and explicitly document every issue you find, no matter how minor.

GENERAL INSTRUCTIONS

Work through each document page by page, paragraph by paragraph.
When you find an issue, quote the exact text or element and state precisely why it is problematic.
Distinguish between: 🔴 Major issues (factual errors, contradictions, wrong references, missing elements), 🟡 Medium issues (ambiguities, inconsistencies that could confuse readers), 🟢 Minor issues (typos, formatting inconsistencies, stylistic irregularities).
If a category has been fully checked and no problems were found, explicitly confirm this so I know nothing was skipped.
If you are uncertain about something, flag it as "Needs author verification" rather than silently passing over it.
Process all documents in sequence: first the main paper, then the online appendix, then the response letter — and finally perform cross-document consistency checks.

1. CROSS-REFERENCE AND CITATION AUDIT

1a. In-text references to tables

Verify that every table referenced in the text (e.g., "Table 3", "see Table A2") actually exists and that the reference points to the correct table.
Verify that every table that exists in the paper or appendix is referenced at least once in the text.
Check that when the text describes specific content from a table (e.g., "the coefficient on SIZE is 0.034 in Column 3 of Table 4"), this exactly matches what the table actually shows — correct variable, correct column, correct sign, correct magnitude, correct significance level.
Flag any vague or potentially misleading references (e.g., "as shown in the table above" without specifying which table).

1b. In-text references to figures

Apply the same checks as for tables: every figure referenced must exist, every figure must be referenced, and descriptions must match actual figure content.
Check that axis labels, legends, and visual content of figures match what the text claims they show.

1c. In-text references to equations

Verify that every equation number referenced in the text exists.
Check that descriptions of equations in the text match the actual equation content (e.g., "we include firm fixed effects" — does the equation actually show firm fixed effects?).

1d. In-text references to sections, appendices, and supplementary materials

Verify all cross-references to sections (e.g., "as discussed in Section 3.2") — does Section 3.2 actually discuss this?
Verify all cross-references to appendices (e.g., "see Online Appendix Table OA.3") — does this table exist in the online appendix, and does it contain what is claimed?
Verify all cross-references to footnotes or endnotes, if applicable.

1e. Bibliographic references

Check that every citation in the text (e.g., "(Smith and Jones 2020)") appears in the reference list.
Check that every entry in the reference list is actually cited somewhere in the text. Flag orphan references.
Verify citation formatting consistency: author names, year, use of "et al." rules (check if the journal style uses "et al." after 2 or 3 authors), ampersand vs. "and", semicolons between multiple citations.
Check for common errors: wrong year, misspelled author names, inconsistent use of first names vs. initials.
Check that references cited as "forthcoming," "working paper," or "in press" are still accurate or whether they may have been published in the meantime (flag for author verification).
Check for self-citations: are they properly formatted and do they match the reference list?

2. TABLE AUDIT (ALL TABLES WITHOUT EXCEPTION)

For every single table in the main paper and in the online appendix:

2a. Internal consistency

Check that column headers, row labels, and panel headers are clear, unambiguous, and internally consistent.
Verify that all numbers are plausible given the context (e.g., percentages between 0 and 100, correlation coefficients between -1 and 1, number of observations is a positive integer, R² between 0 and 1).
Check that the number of observations (N) is consistent across panels of the same table where it should be, and consistent with what the text states.
Check if significance stars (*, , *) are defined in a table note and whether the definitions are consistent across all tables.
Verify that standard errors, t-statistics, or z-statistics (whichever are reported) are correctly labeled and consistently formatted (e.g., always in parentheses or always in brackets — not mixed).
Check that decimal places are consistent within and across tables.

2b. Numbering and ordering

Verify that table numbers are sequential, unique, and correctly ordered (Table 1, Table 2, … with no gaps or duplicates).
Verify that appendix tables follow a consistent numbering scheme (e.g., Table A1, Table A2, … or Table OA.1, OA.2, …).
Confirm tables appear in the order they are first referenced in the text.

2c. Table notes and footnotes

Check that every symbol, abbreviation, or special notation used in a table is explained in the table note.
Verify that table notes do not contradict the text or other tables.
Check that the description of the sample, time period, or methodology in the table note is consistent with the text.

2d. Alignment with text descriptions

When the text discusses specific results from a table, verify every claim: correct sign, correct magnitude, correct significance level, correct column, correct panel.
If the text says "the effect is statistically significant at the 1% level," verify this matches the significance stars shown.
If the text says "the coefficient increases/decreases compared to…," verify the direction is correct.

3. FIGURE AUDIT (ALL FIGURES WITHOUT EXCEPTION)

Check that figure numbers are sequential, unique, and correctly ordered.
Verify that every figure has a title/caption, and that the caption accurately describes the figure content.
Check that axis labels are present, legible, and correctly described.
Verify that legends match the data series shown.
If the text refers to specific patterns or values in a figure, verify that these claims are visually consistent with the figure.
Check figure notes for completeness and consistency with the text.

4. VARIABLE DEFINITIONS AND LABELS

4a. Variable inventory

Compile a complete list of all variables mentioned anywhere in the paper (text, tables, figures, appendices, footnotes).
For each variable, record: name as used, where it is defined, and all locations where it appears.

4b. Consistency checks

Verify that each variable is defined at least once clearly (typically in a variable definitions table or in the text).
Check that variable names, abbreviations, and labels are used identically across all sections — no silent renaming, no pluralization changes (e.g., "Return" vs. "Returns"), no notation drift (e.g., "ROA" vs. "Roa" vs. "roa"), no switching between a full name and an abbreviation without establishing this equivalence.
Flag any variable that appears without a definition, or is defined but never used.
If a variable definitions table exists, verify that it covers all variables used in the regression tables.

5. SAMPLE AND DATA CONSISTENCY

Verify that the stated sample period (e.g., "1990–2020") is used consistently throughout the text, tables, and appendices.
Check that the stated sample size is consistent: does the text say "our sample comprises 45,320 firm-year observations" and do the tables show N = 45,320 (or an explained subset)?
If subsamples are used, verify that subsample descriptions and sizes are consistent across text, tables, and notes.
Check for consistency in data source descriptions: if the text says data comes from Compustat/CRSP/IBES, verify this is stated consistently and not contradicted elsewhere.
If the paper applies sample filters (e.g., excluding financial firms, requiring minimum observations), verify these filters are described consistently and the resulting sample sizes make sense.

6. METHODOLOGY AND ECONOMETRIC CONSISTENCY

Verify that the empirical model described in the text matches what is shown in equation form.
Check that the control variables mentioned in the text match those listed in the tables.
Verify that fixed effects described in the text (e.g., "we include industry and year fixed effects") match what is reported in the tables (e.g., a row saying "Industry FE: Yes, Year FE: Yes").
If the paper mentions clustering of standard errors (e.g., "clustered at the firm level"), verify this is stated consistently in all relevant table notes.
Check that robustness tests described in the text actually appear in the tables and vice versa.

7. STRUCTURAL AND FORMATTING CHECKS

7a. Section and heading structure

Verify that section numbering is sequential and consistent (no gaps, no duplicates).
Check that the structure described in any "roadmap" paragraph (e.g., "Section 2 reviews the literature…") matches the actual section structure.

7b. Footnotes and endnotes

Verify that footnote numbers are sequential and unique.
Check that footnotes do not contain critical information that should be in the main text (flag for author consideration).
Verify that footnotes do not contradict the main text.

7c. Formatting consistency

Check for consistent use of fonts, bold, italics, and spacing in tables and text.
Verify consistent number formatting (e.g., thousands separator, decimal separator).
Check for consistent use of abbreviations (e.g., "e.g.," vs. "for example"; "i.e.," vs. "that is").
Check that all parenthetical asides, quotation marks, and brackets are properly closed.

7d. Page and line references

If the document uses page numbers or line numbers, verify they are sequential and not missing.

8. CROSS-DOCUMENT CONSISTENCY (CRITICAL)

This section applies when multiple documents are provided (main paper, online appendix, response letter).

8a. Main paper ↔ Online appendix

Verify that every reference from the main paper to the online appendix (e.g., "see Online Appendix Table OA.5") points to an element that actually exists in the online appendix.
Verify that every element in the online appendix is referenced from the main paper (flag orphan appendix items).
Check that variable definitions, sample descriptions, and methodology descriptions are consistent between the main paper and the appendix.
Verify that results discussed in both documents are consistent (e.g., if the main paper says "results are robust as shown in the Online Appendix," verify this is actually the case).

8b. Main paper ↔ Response letter

If the response letter promises specific changes (e.g., "We now include an additional control for firm size in Table 5"), verify that these changes are actually reflected in the current version of the paper.
If the response letter references specific tables, figures, or sections in the revised paper, verify that these references are correct.
Flag any promises in the response letter that do not appear to have been implemented in the paper.
Check that any new analyses or tables added in response to reviewer comments are properly integrated (numbered, referenced, noted).

8c. Online appendix ↔ Response letter

If the response letter references new appendix items (e.g., "We provide this analysis in the new Online Appendix Table OA.7"), verify that these items exist in the online appendix.

9. LANGUAGE AND CLARITY CHECKS (ACCOUNTING-SPECIFIC)

Check for correct use of accounting and finance terminology (e.g., "earnings management" vs. "earnings manipulation," "accruals" vs. "accrual," "discretionary" vs. "non-discretionary").
Verify consistency in how accounting standards are referenced (e.g., "IFRS" vs. "IAS," "ASC 606" vs. "the new revenue recognition standard").
Flag any claims that appear to overstate or misrepresent results (e.g., claiming causality when the method only supports association).
Check for hedging language consistency: are similar results described with similar levels of certainty throughout?

10. COMMON PITFALLS CHECKLIST

Finally, specifically check for these frequently occurring errors in accounting research papers:

"Table X" references that are off by one (very common after reordering tables during revision)
Copy-paste errors where a paragraph describes Table 3 but was copied from the description of Table 2 and not fully updated
Significance levels described in text that don't match the stars in the table
Sample sizes that don't add up (e.g., subsamples should sum to full sample)
Control variables listed in the text that don't appear in the table, or vice versa
Inconsistent rounding (e.g., "0.034" in text but "0.0341" in table)
Orphan references (cited in text but missing from reference list, or in reference list but never cited)
Mismatched parenthetical citation formats
Tables where the dependent variable is not clearly stated
Appendix items that are referenced with wrong numbering scheme (e.g., "Table A3" in text but "Table A.3" in appendix)

OUTPUT FORMAT

Organize your findings into clearly labeled sections following the structure above (Sections 1–10). Within each section:

Quote or precisely describe the problematic element with its exact location (page, section, table, column, row).
Explain why it is an issue.
Mark severity: 🔴 Major / 🟡 Medium / 🟢 Minor.
If no issue is found in a category, explicitly state: "Checked — no issues detected."

At the end, provide a summary table listing all issues found, sorted by severity (major first), with columns: Issue #, Location, Category, Severity, Description.

Work slowly and carefully. Go through every single element. Precision and completeness are more important than speed. When in doubt, flag it.
