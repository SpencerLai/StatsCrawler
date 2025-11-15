# Chat Prompt 02: Coding Standards Setup

## Date
November 15, 2025

## User Request
> create a folder to store all the coding styles. The code will be using Typescript, with variables style in camel cases, tab as the separators within the code

## Actions Taken

### 1. Created Coding Standards Documentation Folder
Created `/coding-standards/` directory with comprehensive documentation:

#### Documentation Files
- **STYLE_GUIDE.md** - Complete style guide including:
  - Language specifications (TypeScript)
  - Naming conventions
    - Variables: camelCase
    - Constants: UPPER_CASE
    - Functions: camelCase
    - Components: PascalCase
    - Types/Interfaces: PascalCase
  - Indentation rules (tabs, not spaces)
  - Formatting guidelines
  - Best practices
  - Code examples (good vs bad)
  - File organization structure

- **README.md** - Quick reference guide
  - Links to style guide
  - Configuration file references
  - Quick reference summary

### 2. Configuration Files Created

#### ESLint Configuration (.eslintrc.json)
- Extends Next.js core web vitals
- TypeScript ESLint plugin integration
- Naming convention enforcement:
  - camelcase rule for variables
  - TypeScript naming conventions
  - PascalCase for types
- Tab indentation enforcement
- Disabled no-tabs rule

#### Prettier Configuration (.prettierrc)
- useTabs: true
- tabWidth: 1
- singleQuote: true
- semi: false (optional semicolons)
- trailingComma: es5
- printWidth: 100
- arrowParens: always

#### EditorConfig (.editorconfig)
- Root configuration
- Tab indentation for all files
- UTF-8 charset
- LF line endings
- Insert final newline
- Trim trailing whitespace
- Special rules for YAML (spaces)

#### VS Code Settings (.vscode/settings.json)
- insertSpaces: false (use tabs)
- tabSize: 1
- detectIndentation: false
- formatOnSave: true
- Default formatter: Prettier
- ESLint auto-fix on save
- Single quotes for TypeScript/JavaScript
- Enforce LF line endings

### 3. Updated Dependencies

Added to package.json:
- **prettier** (^3.3.2) - Code formatter
- **@typescript-eslint/eslint-plugin** (^6.21.0) - TypeScript linting rules
- **@typescript-eslint/parser** (^6.21.0) - TypeScript parser for ESLint

### 4. Reformatted Existing Code

Converted all existing files from spaces to tabs:
- app/layout.tsx
- app/page.tsx
- next.config.js
- tsconfig.json

### 5. Updated Documentation

Updated README.md to include:
- Reference to coding-standards folder
- Style conventions summary
- Configuration file list

## Coding Standards Summary

### Language
- TypeScript for all code files

### Naming Conventions
- **Variables**: camelCase (e.g., `userName`, `itemCount`)
- **Constants**: UPPER_CASE (e.g., `MAX_ITEMS`, `API_BASE_URL`)
- **Functions**: camelCase (e.g., `fetchUserData`)
- **Components**: PascalCase (e.g., `UserProfile`)
- **Types/Interfaces**: PascalCase (e.g., `UserData`, `ResponseType`)

### Indentation
- **Use tabs, not spaces**
- Tab width: 1
- Applies to all TypeScript, JavaScript, JSX, TSX files

### Formatting
- **Quotes**: Single quotes for strings
- **Semicolons**: Optional (not enforced)
- **Line Length**: Maximum 100 characters
- **Trailing Commas**: ES5-compatible contexts

## Tools for Enforcement
1. **ESLint** - Linting and naming conventions
2. **Prettier** - Code formatting
3. **EditorConfig** - Editor settings consistency
4. **VS Code Settings** - IDE-specific configuration

## Recommended VS Code Extensions
- ESLint
- Prettier - Code formatter
- EditorConfig for VS Code

## Outcome
Comprehensive coding standards established with automated enforcement through linting and formatting tools. All existing code reformatted to comply with standards.

