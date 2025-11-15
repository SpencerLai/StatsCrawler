# StatsCrawler Coding Standards

## Overview

This document outlines the coding standards and style guidelines for the StatsCrawler project.

## Language

- **TypeScript** is the primary language for this project
- All new files should use `.ts` or `.tsx` extensions

## Naming Conventions

### Variables
- Use **camelCase** for variable names
- Examples:
  ```typescript
  const userName = 'John'
  let itemCount = 0
  const isActive = true
  ```

### Constants
- Use **UPPER_CASE** with underscores for constants
- Examples:
  ```typescript
  const MAX_ITEMS = 100
  const API_BASE_URL = 'https://api.example.com'
  ```

### Functions
- Use **camelCase** for regular functions
- Use **PascalCase** for React components
- Examples:
  ```typescript
  function fetchUserData() { }
  const UserProfile = () => { }
  ```

### Types and Interfaces
- Use **PascalCase** for types, interfaces, classes, and enums
- Examples:
  ```typescript
  interface UserData { }
  type ResponseType = { }
  class DataService { }
  ```

## Indentation

- Use **tabs** for indentation (not spaces)
- Tab width: 1
- This applies to all TypeScript, JavaScript, JSX, and TSX files

## Formatting

### Quotes
- Use **single quotes** for strings
- Example: `const message = 'Hello World'`

### Semicolons
- Semicolons are optional (configured to not require them)

### Line Length
- Maximum line length: 100 characters

### Trailing Commas
- Use trailing commas in ES5-compatible contexts (objects, arrays)

## File Organization

```
/app              - Next.js pages and layouts
/components       - Reusable React components
/lib              - Utility functions and helpers
/types            - TypeScript type definitions
/public           - Static assets
/coding-standards - Coding style documentation
```

## Tools and Configuration

### ESLint
- Configuration: `.eslintrc.json`
- Enforces TypeScript best practices and naming conventions
- Run: `npm run lint`

### Prettier
- Configuration: `.prettierrc`
- Enforces consistent code formatting
- Automatically formats on save (if configured in editor)

### EditorConfig
- Configuration: `.editorconfig`
- Ensures consistent editor settings across different IDEs

### VS Code
- Configuration: `.vscode/settings.json`
- Recommended settings for VS Code users

## Best Practices

1. **Type Safety**: Always define types explicitly when not obvious
2. **No Any**: Avoid using `any` type unless absolutely necessary
3. **Destructuring**: Use destructuring for cleaner code
4. **Arrow Functions**: Prefer arrow functions for callbacks
5. **Async/Await**: Use async/await instead of promise chains
6. **Error Handling**: Always handle errors appropriately

## Examples

### Good Examples

```typescript
// Variable naming - camelCase
const userData = await fetchUser()
let itemCount = 0

// Function naming - camelCase
function calculateTotal(items: Item[]): number {
	return items.reduce((sum, item) => sum + item.price, 0)
}

// Component naming - PascalCase
const UserCard = ({ userName, email }: UserCardProps) => {
	return (
		<div>
			<h2>{userName}</h2>
			<p>{email}</p>
		</div>
	)
}

// Type naming - PascalCase
interface UserCardProps {
	userName: string
	email: string
}
```

### Bad Examples

```typescript
// ❌ Wrong: snake_case variables
const user_name = 'John'

// ❌ Wrong: PascalCase for regular variables
const UserData = {}

// ❌ Wrong: spaces instead of tabs
function example() {
  return true  // spaces used here
}

// ❌ Wrong: double quotes
const message = "Hello"
```

## Enforcement

These standards are enforced through:
- ESLint (linting)
- Prettier (formatting)
- EditorConfig (editor settings)
- Code review process

Make sure to install the recommended VS Code extensions:
- ESLint
- Prettier - Code formatter
- EditorConfig for VS Code

