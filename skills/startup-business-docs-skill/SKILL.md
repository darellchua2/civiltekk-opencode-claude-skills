---
name: startup-business-docs-skill
description: >-
  Business document workflows for startup founders — reports, quotations,
  spreadsheets, presentations with professional formatting.
license: Apache-2.0
compatibility: opencode
category: Startup/Business
---

## What I do

I provide structured workflow patterns for creating professional business documents efficiently:

1. **Reports**: Status, investor, board, and team reports with clear metrics and next steps
2. **Quotations & Proposals**: Client quotations, SOWs, project proposals, and partnership proposals
3. **Spreadsheets**: Financial models, tracking sheets, data analysis, and planning tools
4. **Presentations**: Pitch decks, sales decks, and internal presentations (delegated to specialized subagents)
5. **Communications**: Professional emails to investors, partners, and clients

## When to use me

Use this skill when you need to create:
- Business reports (status updates, investor updates, board updates, team reports)
- Quotations or proposals (client quotes, SOWs, project proposals, partnership proposals)
- Spreadsheets (financial models, tracking sheets, data analysis, planning tools)
- Presentations (pitch decks, sales decks, internal slides)
- Professional communications (investor emails, partner outreach, client communications)

**Trigger phrases**:
- "create a report", "generate quotation", "update slides"
- "make a spreadsheet", "prepare a proposal"
- "draft an investor update", "write a client email"
- "build a financial model", "create a tracking sheet"

## Report Workflow

### Step 1: Gather Context

Ask for:
- Data sources and metrics to include
- Time period covered (weekly, monthly, quarterly)
- Key updates, wins, and blockers
- Specific decisions or requests needed from audience

### Step 2: Clarify Audience

Understand:
- Who will read this? (investors, board, team, clients)
- What decisions depend on this report?
- What level of detail is needed?
- What tone is appropriate? (formal board update vs. internal team sync)

### Step 3: Structure Content

Use this template:

```
# [Report Title]

## Executive Summary
[1-2 sentences max: What's the headline? What's the bottom line?]

## Key Metrics / Status
[Most important numbers, trends, and status indicators]

## Details by Category
### [Category 1]
- Update 1
- Update 2

### [Category 2]
- Update 1
- Update 2

## Risks / Blockers
[What's standing in the way? What could go wrong?]

## Next Steps / Ask
[What needs to happen next? What support is needed?]
```

### Step 4: Generate Document

Choose format:
- **Primary**: `.docx` for formal reports
- **Alternative**: `.md` for internal updates, `.pdf` for distribution

### Step 5: Review

- Verify all numbers are accurate
- Ensure clarity and conciseness
- Offer revisions if needed

## Quotation Workflow

### Step 1: Clarify Scope

Ask for:
- What products/services are being quoted?
- Timeline for delivery
- Volume or quantity
- Any special requirements or customizations
- Payment terms and conditions

### Step 2: Structure Pricing

Use this format:

```
# [Company Name] - Quotation

## Client Information
Client: [Name]
Date: [Date]
Quote #: [Number]

## Line Items
| Item | Description | Quantity | Unit Price | Total |
|------|-------------|----------|------------|-------|
| [Item 1] | [Details] | [Qty] | [Price] | [Total] |
| [Item 2] | [Details] | [Qty] | [Price] | [Total] |

## Summary
### Subtotal: [Amount]
### Taxes: [Amount]
### Discounts: [Amount]
### **Total: [Amount] [Currency]**

## Terms and Conditions
[Payment terms, delivery timeline, validity, etc.]
```

### Step 3: Professional Formatting

- Clean, professional layout
- Include company branding (logo, colors)
- Clear typography and spacing
- Consistent number formatting

### Step 4: Deliver

- **Primary**: `.docx` for editable copy
- **Alternative**: `.pdf` for final delivery, `.md` for internal records

## Spreadsheet Workflow

### Step 1: Understand Requirements

Ask for:
- What data structure? (columns, rows, relationships)
- What calculations are needed? (formulas, summaries)
- What analysis will be performed? (trends, comparisons, projections)
- Any specific formatting requirements? (currency, dates, percentages)

### Step 2: Build Structure

- Define headers in first row
- Set data types for each column (text, number, date, currency)
- Add summary rows or sheets as needed
- Include data validation if applicable

### Step 3: Add Formulas

Common formulas:
- **Sum**: `=SUM(range)`
- **Average**: `=AVERAGE(range)`
- **Growth**: `=((New-Old)/Old)`
- **Percent Change**: `=((New-Old)/Old)*100`
- **Conditional**: `=IF(condition, true_value, false_value)`
- **VLOOKUP**: `=VLOOKUP(lookup_value, table_array, col_index, [range_lookup])`

### Step 4: Format Professionally

- Number formats (currency, percentage, date)
- Conditional formatting for visual cues
- Charts and graphs if needed
- Clear labels and legends
- Freeze header rows for readability

### Step 5: Export

- **Primary**: `.xlsx` (Excel with formulas intact)
- **Alternative**: `.csv` for data portability

## Presentation Workflow

### Step 1: Gather Content

Collect:
- Key messages and value propositions
- Data points and metrics
- Visuals needed (charts, images, diagrams)
- Story arc and flow

### Step 2: Delegate

Hand off to specialized subagents:

| Presentation Type | Delegate To |
|-------------------|-------------|
| Pitch Decks | `startup-ceo-subagent` |
| Investor Presentations | `startup-ceo-subagent` |
| Board Updates | `startup-ceo-subagent` |
| Sales Decks | `pptx-specialist-subagent` |
| Internal Slides | `pptx-specialist-subagent` |

### Step 3: Provide Structure

Include:
- Slide outline with titles
- Key points per slide
- Talking points or script
- Visual direction (what charts/images to include)
- Design preferences (colors, style)

### Step 4: Review Output

- Ensure alignment with founder's intent
- Check for clarity and impact
- Verify all data is accurate
- Test flow and timing

### Step 5: Iterate

- Gather feedback
- Refine content and design
- Finalize for delivery

### Output Formats

- **Primary**: `.pptx` (PowerPoint)
- **Alternative**: `.pdf` for distribution

## Communications Workflow

### Step 1: Understand Purpose

Clarify:
- What outcome is desired? (meeting, decision, action, acknowledgment)
- What is the urgency level?
- What context does the recipient need?

### Step 2: Identify Recipient

Determine:
- Investor (partner, VC, angel)
- Partner (strategic, vendor, co-founder)
- Client (prospect, active, churned)
- Team (all-hands, department, individual)
- What is their relationship to the sender?
- What tone is appropriate?

### Step 3: Draft Message

Use this structure:

```
[Clear subject line - specific and actionable]

Hi [Name],

[Opening - 1 sentence: acknowledge relationship or context]

[Body - 2-3 sentences: main message, details, value]

[Ask - 1 sentence: what action or response is needed]

[Closing - 1 sentence: next steps or timeframe]

Best,
[Name]
```

### Step 4: Format Appropriately

- **Email**: Professional email format with clear subject line
- **Formal Letter**: Business letter format with header
- **Slack/Message**: Concise, informal but professional
- **Template**: `.md` for reusable templates

### Output Formats

- **Primary**: Email/Text (send directly or provide draft)
- **Alternative**: `.md` for templates and records

## Output Format Reference

| Document Type | Primary Format | Alternative |
|--------------|----------------|-------------|
| Reports | .docx | .md, .pdf |
| Quotations | .docx | .pdf, .md |
| Spreadsheets | .xlsx | .csv |
| Presentations | .pptx | .pdf |
| Communications | Email/Text | .md |

## Best Practices

### 1. Clarify First

Always confirm scope before generating:
- What specifically needs to be created?
- Who is the audience?
- What format is required?
- What is the deadline?

### 2. Use Templates

Maintain consistency across documents:
- Keep reusable templates for common document types
- Standardize formatting, fonts, and layouts
- Use consistent terminology and structure

### 3. Version Control

Suggest file naming conventions:
- Include date and version: `Report_2025-05-17_v1.docx`
- Use descriptive names: `ClientQuotation_AcmeCorp_May2025.docx`
- Track changes between versions

### 4. Data Accuracy

Verify before finalizing:
- Check all numbers and calculations
- Cross-reference data sources
- Ensure currency symbols and units are correct
- Validate dates and timelines

### 5. Iterate Quickly

Offer fast revision cycles:
- Provide first drafts quickly
- Solicit feedback early
- Make targeted revisions
- Don't over-engineer initial versions

### 6. Format Professionally

Maintain high presentation standards:
- Clean layouts with ample white space
- Consistent typography (fonts, sizes, weights)
- Professional color schemes
- Proper alignment and indentation
- Company branding where appropriate

## Error Handling

### Document Generation Fails

- Offer alternative formats (e.g., if .docx fails, try .md)
- Check for missing dependencies or tools
- Provide partial output if possible
- Escalate to specialized subagents if needed

### Data Incomplete

- Prompt for missing information explicitly
- Highlight what's needed and why
- Use placeholders with clear labels
- Proceed with assumptions if approved

### Scope Unclear

- Ask clarifying questions before proceeding
- Provide options or examples
- Recommend best practices based on context
- Iterate on scope as needed

### Specialized Subagent Unavailable

- Handle directly with available tools
- Use alternative skills (e.g., `docx-creation` for documents)
- Provide best-effort output
- Document limitations

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `docx-creation` | Primary skill for reports, quotations, and formal documents |
| `xlsx-specialist` | Primary skill for spreadsheet creation and manipulation |
| `pptx-specialist-subagent` | Primary subagent for general presentations |
| `pdf-specialist` | Export documents to PDF format for distribution |

## Tone & Style

- **Professional**: Business-appropriate language
- **Concise**: Get to the point, respect founder's time
- **Action-Oriented**: Focus on deliverables and next steps
- **Startup-Appropriate**: Lean, efficient, adaptable
- **Clarifying**: Ask questions when scope is unclear

## References

- `docx-creation` - Word document generation
- `xlsx-specialist` - Spreadsheet creation and manipulation
- `pptx-specialist-subagent` - PowerPoint presentation creation (routes to pptx-generate-slide/template/template-modifier)
- `pdf-specialist` - PDF conversion and manipulation