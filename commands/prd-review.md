---
description: Review a PRD and ask clarifying questions before development planning
version: 0.3-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# PRD Review

## Context

You are reviewing a Product Requirements Document (PRD) to understand the requirements and identify any gaps or ambiguities before creating a development plan with epics.

## PRD Location

First, check for PRD files in the `docs/` folder by listing `docs/*.md`. If no PRD is found, ask the user to provide the path to the PRD file.

## Instructions

1. **Read the PRD thoroughly** - Read the entire PRD file to understand the project requirements

2. **Analyze for completeness** - Check if the PRD covers:
   - Clear problem statement and goals
   - Target users/personas
   - Functional requirements (features)
   - Non-functional requirements (performance, security, scalability)
   - Technical constraints or preferences
   - Success metrics/acceptance criteria
   - Out of scope items
   - Dependencies or integrations

3. **Identify potential epics** - Based on the PRD, suggest how work could be organized into epics:
   - Look for natural feature groupings
   - Identify foundational work vs. feature work
   - Consider dependencies between features
   - Think about MVP vs. future phases

4. **Identify gaps and ambiguities** - Look for:
   - Vague or undefined terms
   - Missing edge cases
   - Unclear priorities
   - Conflicting requirements
   - Missing technical details needed for implementation
   - Unstated assumptions

5. **Ask clarifying questions** - Present your questions organized by category:
   - **Critical** - Must be answered before development can begin
   - **Important** - Should be clarified to avoid rework
   - **Nice to have** - Would improve clarity but not blocking

6. **Summarize understanding** - Provide a brief summary of:
   - What you understand the project to be
   - Key features/capabilities
   - Technical approach (if discernible)
   - Any assumptions you're making

## Output Format

Structure your response as:

### PRD Summary
[Your understanding of the project]

### Tech Stack (if specified)
- **Backend:** [technology or "Not specified"]
- **Frontend:** [technology or "Not specified"]
- **Database:** [technology or "Not specified"]

### Suggested Epic Breakdown

Based on the PRD, here's a suggested organization into epics:

| Epic | Name | Description | Priority |
|------|------|-------------|----------|
| 1 | [Name] | [Brief description] | High |
| 2 | [Name] | [Brief description] | High |
| 3 | [Name] | [Brief description] | Medium |

### Key Features by Epic

**Epic 1: [Name]**
- Feature 1
- Feature 2

**Epic 2: [Name]**
- Feature 3
- Feature 4

### Clarifying Questions

#### Critical (Must Answer)
1. [Question]
2. [Question]

#### Important (Should Answer)
1. [Question]
2. [Question]

#### Nice to Have
1. [Question]

### Assumptions
[List any assumptions you're making that should be validated]

### Risks & Concerns
- [Any technical risks or concerns identified]

---

After the user responds to your questions:
1. Incorporate their answers
2. Refine the epic breakdown if needed
3. Confirm your updated understanding
4. Proceed to `/create-plan` when ready
