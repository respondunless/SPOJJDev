# Power Apps Copilot Prompt — Professionalisation Support Application

Redesign the existing **SharePoint-integrated Power Apps form** for the SharePoint list **Professionalisation2 on Stage forms**.

This is an existing SharePoint customised list form. **Do not create a new standalone app, Dataverse table, data source, or replacement SharePoint list. Do not rename or recreate existing SharePoint columns.**

**Preserve the existing SharePointIntegration control and its New, Edit, View, Save and Cancel behaviour. Preserve the existing SharePoint list as the data source.**

Use **modern Power Apps controls and modern themes where supported**, with a Fluent 2 / current Microsoft 365 visual style. The target is a polished internal business application, not a default SharePoint form.

## Overall visual design

Create a soft light blue-grey application background.

Create a modern header at the top with:
- education/professional-development icon
- title: **Professionalisation Support Application**
- subtitle: **Apply for professional development support and funding**
- smaller supporting text explaining that the application will be routed for approval
- a status pill on the right using `StatusApprovals`
- use a sensible Draft/default status when appropriate

Use large white section cards with:
- approximately 12–16 px corner radius
- subtle drop shadow
- generous internal padding
- clear section icon
- section title
- short explanatory subtitle
- consistent spacing
- modern Fluent-style controls

The design should be desktop-first but responsive. Use two or three columns where appropriate and collapse gracefully on narrow screens.

Do not cram every field into one long vertical form.

## Section 1 — Employee details

Subtitle: **Your organisational details**

Show:
- Name
- MyID
- Position
- Manager
- Program
- Function

Arrange these as two rows of three fields where screen width allows.

Employee information that is supplied automatically should appear visually quieter than fields the applicant needs to select or enter.

## Section 2 — Professionalisation details

Subtitle: **Tell us about the professional development activity**

Show:
- Professionalisation Name
- Professional Body
- Cost
- Duration of Professionalisation
- Cost Centre
- Funding Model Alignment
- FunctionalAreaAlignmentNew

Use sensible field widths. Professionalisation Name and Professional Body should have more horizontal space than Cost or Duration.

Format Cost as a currency-style input if the SharePoint field type permits it without changing the underlying SharePoint column.

## Section 3 — Justification

Subtitle: **Help us understand the value and need for this professionalisation**

Show:
- Funding Model Align Justify
- Professionalisation in Dev Plan
- Benefit 2U & NGA

Use large multi-line text areas for the two justification fields.

Display `Professionalisation in Dev Plan` as a clear Yes/No choice.

## Supporting documents

Keep the SharePoint **Attachments** field available if it exists on the current form.

Present it cleanly as a supporting-documents area associated with the application. Do not replace it with a separate storage mechanism.

## Section 4 — Application status & approvals

Subtitle: **Workflow information — read only**

This section must be visually different from the data-entry sections and must not look editable.

Show useful workflow information including:
- StatusApprovals
- EmployeeApproveDate
- ManagerApproveDate
- FunctionalLeader
- FunctionalLeaderApproveDate
- BudgetHolder
- BudgetHolderApproveDate

Use a soft neutral or pale warm background for this card.

Display `StatusApprovals` as a coloured status pill where possible.

Approval dates and workflow information must be read-only.

## Hide technical workflow fields

Do not show technical/helper fields to the applicant unless they are required for the visible business experience.

Hide fields such as:
- ProgramBudgetHolder
- ProgramBudgetHolderEmail
- FunctionBudgetHolder
- FunctionBudgetHolderEmail
- ManagerEmail
- FunctionalLeaderEmail
- BudgetHolderFrom
- BudgetHolderEmail
- CCBudgetHolder
- CCBudgetHolderEmail
- Created
- Created By
- Modified
- Modified By

Keep them available to formulas/workflow where required; simply remove them from the visible applicant interface.

## Form actions

Preserve the existing SharePoint form submission behaviour.

Create a clean action area at the bottom with:
- **Save as draft**
- **Submit application**

Do not break the existing SharePointIntegration `OnSave`, `OnCancel`, New/Edit/View mode switching, form submission, or closing behaviour.

If adding separate Save as draft / Submit application behaviour would require changing the data model or workflow logic, do not invent that logic. Instead, create the visual buttons and clearly identify what additional formula or workflow logic would be required.

## Important implementation constraints

Use only controls and properties actually supported by the current Power Apps environment.

Prefer modern controls and Fluent 2 styling.

Do not change SharePoint internal field names.

Do not create duplicate controls bound to different data sources.

Maintain validation for required SharePoint fields.

Maintain accessibility, visible focus states, and adequate colour contrast.

Preserve the ability to create, edit and view items directly from the SharePoint list.

Before making major structural changes, keep the existing SharePoint-integrated form behaviour intact and redesign its presentation around the existing data source.

The visual target is a modern Microsoft 365 application with **rounded white cards, soft shadows, generous spacing, clean typography, clear section hierarchy, modern controls, status pills and a visually distinct read-only approval area**.
