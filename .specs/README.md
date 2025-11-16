# .specs Directory

This directory contains the complete project specifications, chat history, and planning documents for StatsCrawler.

## Contents

### Chat History
Documentation of all interactions and setup steps:

1. **01-initial-setup.md** - Initial Next.js project setup
   - Project initialization
   - Technology stack selection
   - Basic file structure creation
   - Configuration files setup

2. **02-coding-standards.md** - Coding standards and style guide setup
   - TypeScript conventions
   - CamelCase variable naming
   - Tab indentation configuration
   - ESLint, Prettier, EditorConfig setup

3. **03-project-requirements.md** - Project requirements definition
   - NHL game data crawling specifications
   - PostgreSQL database requirement
   - Chrome browser automation for gamecenter
   - Architecture and data flow design

4. **04-git-setup.md** - Git repository setup
   - Local git initialization
   - Initial commit with all project files
   - GitHub remote configuration
   - Instructions for creating GitHub repository

5. **05-database-schema-design.md** - Database schema design deep dive
   - Event-driven architecture
   - PostgreSQL schema for event logging
   - Crawler traceability system
   - Data lake streaming pipeline
   - Analytics-ready materialized views

### Planning Documents

- **PROJECT_PLAN.md** - Comprehensive project roadmap
  - Current status and completed tasks
  - Technology stack details
  - Project structure (current and planned)
  - Development phases
  - Future considerations
  - Questions to address

## Purpose

This directory serves as:

1. **Historical Record** - Complete documentation of all decisions and changes
2. **Reference Guide** - Quick lookup for why certain choices were made
3. **Onboarding Tool** - Help new team members understand the project evolution
4. **Planning Hub** - Central location for project roadmap and future plans

## How to Use

### For Team Members
- Review chat history files to understand past decisions
- Refer to PROJECT_PLAN.md for current status and next steps
- Update PROJECT_PLAN.md as the project evolves

### For New Contributors
1. Start with PROJECT_PLAN.md to understand the overall vision
2. Read chat history files chronologically (01, 02, etc.)
3. Review coding-standards/ directory for style guidelines

### Maintenance
- Add new chat history files as significant conversations occur
- Keep PROJECT_PLAN.md updated with progress and changes
- Document important decisions and rationale

## Naming Convention

Chat history files follow the pattern:
```
NN-descriptive-name.md
```

Where:
- **NN** = Sequential number (01, 02, 03, etc.)
- **descriptive-name** = Brief description of the topic
- **.md** = Markdown format for easy reading

## Related Directories

- `/coding-standards/` - Detailed style guide and coding conventions
- `/` (root) - Configuration files (.eslintrc.json, .prettierrc, etc.)
- `/app/` - Application code following these specifications

---

**Purpose**: Project Specifications and Documentation
**Maintained By**: Development Team
**Last Updated**: November 15, 2025

