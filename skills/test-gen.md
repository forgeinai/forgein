---
description: Generates unit and integration tests for a function or file. Auto-detects the test framework and writes idiomatic tests covering happy path, edge cases, and error handling.
---

Generate tests for the target in `$ARGUMENTS` (a function name, file path, or class name).

**Steps:**

1. Read the target file. If a function/class name was given, locate it in the codebase:
   ```bash
   grep -r "def $ARGUMENTS\|class $ARGUMENTS" --include="*.py" -l 2>/dev/null | head -5
   ```

2. Detect the test framework:
   - Python: look for `pytest.ini`, `setup.cfg [tool:pytest]`, `pyproject.toml [tool.pytest]` → pytest. Fallback: unittest.
   - JavaScript/TypeScript: look for `jest.config.*`, `vitest.config.*`, `.mocharc.*`
   - Go: standard `testing` package
   - Rust: `#[cfg(test)]` inline

3. Read existing tests for the same module to match style (imports, fixtures, naming conventions).

4. Analyze the target function/class:
   - What are the inputs and their types/constraints?
   - What does it return or mutate?
   - What can go wrong (invalid input, network failure, empty list, None, etc.)?

5. Generate tests covering:
   - **Happy path**: standard correct input → expected output
   - **Edge cases**: empty, None/null, zero, max value, single element, unicode
   - **Error handling**: invalid input should raise the right exception with the right message
   - **Integration** (if applicable): interaction with real dependencies (DB, HTTP) using minimal fixtures

6. Write tests to the appropriate test file (e.g. `tests/test_<module>.py`). Ask before writing if the file already exists and has content.

7. Print: `Generated X tests in tests/test_<module>.py. Run with: <test command>`
