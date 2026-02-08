---
description: Generate a PRD from a project idea through guided questions
version: 0.3.1-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Generate PRD from Project Idea

## Context

You are helping the user create a structured Product Requirements Document (PRD) from a high-level project idea. You will conduct a brief interview to gather the information needed, then generate a complete PRD.

## Instructions

### 1. Get the Project Idea

If the user provided an idea inline (e.g., `/generate-prd build a recipe sharing app`), use that as the starting point. Otherwise, ask:

> What's your project idea? Give me a brief description of what you want to build.

### 2. Interview the User

Ask targeted questions to fill in the PRD structure. Ask 3-5 questions at a time, grouped by topic. Don't ask questions the user already answered.

**Round 1 - Scope & Users:**
- Who are the target users/personas? (e.g., developers, end consumers, internal team)
- What is the core problem this solves?
- What are the 2-3 must-have features for an MVP?
- What's explicitly out of scope for now?

**Round 2 - Technical & Constraints:**
- Any preferred tech stack or constraints? (language, framework, hosting)
- Are there external integrations or APIs needed?
- Any authentication/authorization requirements?
- What are the key non-functional requirements? (performance, scalability, security)

**Round 3 - Success & Delivery:**
- How will you measure success? (metrics, KPIs)
- What's the timeline or delivery milestone?
- Any dependencies on other teams or systems?
- Known risks or open questions?

Adapt the questions based on the project. Skip questions that don't apply (e.g., don't ask about database choices for a CLI tool). If the user gives short answers, that's fine -- fill in reasonable defaults and flag assumptions.

### 3. Generate the PRD

Write the PRD to `docs/prd.md`. If the file already exists, warn the user and ask before overwriting.

Use this format:

```markdown
# PRD: [Project Name]

> **Author:** [User]
> **Created:** [date]
> **Status:** Draft

## Problem Statement

[What problem does this solve? Why does it matter?]

## Goals

1. [Primary goal]
2. [Secondary goal]
3. [Tertiary goal]

## Non-Goals (Out of Scope)

- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Target Users / Personas

### Persona 1: [Name/Role]
- **Description:** [Who they are]
- **Needs:** [What they need from this product]
- **Pain points:** [Current frustrations]

### Persona 2: [Name/Role]
- **Description:** [Who they are]
- **Needs:** [What they need]
- **Pain points:** [Current frustrations]

## Functional Requirements

### FR-1: [Feature Area]
- [Requirement 1.1]
- [Requirement 1.2]

### FR-2: [Feature Area]
- [Requirement 2.1]
- [Requirement 2.2]

### FR-3: [Feature Area]
- [Requirement 3.1]

## Non-Functional Requirements

- **Performance:** [Response times, throughput]
- **Scalability:** [Expected load, growth]
- **Security:** [Auth, data protection]
- **Reliability:** [Uptime, error handling]
- **Accessibility:** [Standards, compliance]

## Tech Stack (Suggested)

- **Backend:** [technologies]
- **Frontend:** [technologies]
- **Database:** [technologies]
- **Infrastructure:** [hosting, CI/CD]

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| [Metric 1] | [Target value] | [Measurement method] |
| [Metric 2] | [Target value] | [Measurement method] |

## Dependencies

- [External dependency 1]
- [External dependency 2]

## Risks & Open Questions

| Risk/Question | Impact | Mitigation/Answer |
|---------------|--------|-------------------|
| [Risk 1] | [High/Medium/Low] | [Mitigation strategy] |
| [Open question 1] | [High/Medium/Low] | [TBD] |

## Timeline / Milestones

| Milestone | Target Date | Description |
|-----------|-------------|-------------|
| MVP | [date] | [What's included] |
| V1.0 | [date] | [What's included] |
```

### 4. Flag Assumptions

After generating, list any assumptions you made where the user didn't provide specifics. For example:

> **Assumptions made (please verify):**
> - Assumed web-based (not mobile native)
> - Assumed PostgreSQL for database
> - Assumed single-tenant for MVP

### 5. Next Steps

After creating the PRD, inform the user:

1. The PRD has been created at `docs/prd.md`
2. Review it and edit anything that needs adjustment
3. When ready, run `/prd-review` for a structured review and gap analysis
4. Then run `/create-plan` to generate a development plan with epics and tasks
