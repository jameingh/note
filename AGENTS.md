# AGENTS.md - AI Assistant Guidelines

## Project Status
**Empty project directory** – no source code, configuration files, or tech stack defined yet. Use this guide to bootstrap with modern best practices.

---

## Build / Test / Lint Commands

### Recommended Setup (Select Based on Tech Stack)

**Node.js / TypeScript:**
```bash
# Initialize
npm init -y && npm install typescript eslint prettier --save-dev

# Build:    npm run build
# Test:     npm run test                    # All tests
# Test:     npm run test -- -t "name"       # Single test (Jest)
# Lint:     npm run lint
# Format:   npx prettier --write .
# Type-check: npx tsc --noEmit
```

**Python:**
```bash
# Initialize
pip install poetry && poetry new .

# Build:    poetry build
# Test:     poetry run pytest               # All tests
# Test:     poetry run pytest -k "name"     # Single test
# Lint:     poetry run ruff check .
# Format:   poetry run ruff format .
# Type-check: poetry run mypy src/
```

**Go:**
```bash
# Initialize
go mod init mall

# Build:    go build ./...
# Test:     go test ./...                   # All tests
# Test:     go test -run TestName ./...     # Single test
# Lint:     golangci-lint run
# Format:   go fmt ./...
```

---

## Code Style Guidelines

### General Principles
- **Clarity over cleverness** – readable code wins
- **Be consistent** – match existing patterns once established
- **Document why, not what** – comments explain intent

### TypeScript / JavaScript
```typescript
// Imports – Group by type, alphabetize within groups
import { z } from "zod";                    // Libraries
import { UserService } from "./services";   // Internal
import types from "./types";                // Relative

// Naming: Interfaces/Classes: PascalCase
//         Variables/functions: camelCase
//         Constants: UPPER_SNAKE_CASE
const MAX_RETRY_COUNT = 3;

// Types: Prefer interfaces over type aliases for objects
interface User {
  id: string;
  email: string;
}

// Error handling: Specific error types, never silent catches
try {
  await userService.create(data);
} catch (error) {
  if (error instanceof ValidationError) {
    throw new ApiError(400, error.message);
  }
  throw error; // Re-throw unexpected errors
}
```

### Python
```python
# Imports – Follow PEP 8 ordering
from typing import Optional              # Standard library
import requests                          # Third-party
from app.services import UserService     # Internal

# Naming: Classes: PascalCase
#         Functions/variables: snake_case
#         Constants: UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3

# Types: Use type hints everywhere
def create_user(name: str, email: Optional[str] = None) -> User:
    """Create a new user with validation."""
    if not name:
        raise ValueError("Name is required")
    return User(name=name, email=email)
```

### Go
```go
// Imports – Group by stdlib, external, internal
import (
    "context"                           // Standard library
    "github.com/gin-gonic/gin"          // External
    "mall/internal/service"             // Internal
)

// Naming: Exported: PascalCase (User, CreateUser)
//         Unexported: camelCase (user, createUser)
//         Constants: PascalCase with value
const MaxRetryCount = 3

// Error handling: Check errors, wrap with context
func (s *UserService) Create(ctx context.Context, data *UserInput) (*User, error) {
    if data.Name == "" {
        return nil, errors.New("name required")
    }
    user, err := s.repo.Create(ctx, data)
    if err != nil {
        return nil, fmt.Errorf("create user: %w", err)
    }
    return user, nil
}
```

---

## Existing Rules

- **No Cursor rules** – `.cursor/rules/` and `.cursorrules` do not exist
- **No Copilot rules** – `.github/copilot-instructions.md` does not exist
- **No linting/formatting configs** – ESLint, Prettier, etc. not configured

---

## Agent Workflow

1. **Check for existing patterns** – Once code exists, follow established conventions
2. **Run type-check before changes** – `tsc --noEmit`, `mypy`, or `go vet`
3. **Run tests after changes** – Verify no regressions introduced
4. **Never suppress type errors** – No `as any`, `@ts-ignore`, `# type: ignore`
5. **Commit only when asked** – Do not create commits without explicit request

---

## Verification Checklist

After implementation:
- [ ] No type errors in changed files
- [ ] All tests pass (or document pre-existing failures)
- [ ] Code matches project style
- [ ] No lint warnings introduced

---

*Created: March 27, 2026 | Status: Bootstrap guidelines for empty project*
