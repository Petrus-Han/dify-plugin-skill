# Contributing to Dify Plugin Development Skill

Thank you for your interest in contributing to this skill! This guide will help you make meaningful contributions.

## Table of Contents

- [How to Contribute](#how-to-contribute)
- [Types of Contributions](#types-of-contributions)
- [Contribution Workflow](#contribution-workflow)
- [Documentation Standards](#documentation-standards)
- [Code Examples Standards](#code-examples-standards)
- [Testing Your Changes](#testing-your-changes)
- [Commit Message Guidelines](#commit-message-guidelines)

## How to Contribute

We welcome contributions from everyone! Here are ways you can help:

1. **Report Issues**
   - Found an error in the documentation?
   - Discovered a missing best practice?
   - Have a suggestion for improvement?
   - Open an issue on GitHub

2. **Share Your Experience**
   - Add new pitfalls you've encountered
   - Document solutions to problems
   - Share plugin examples

3. **Improve Documentation**
   - Fix typos or unclear sections
   - Add more code examples
   - Update for new Dify versions
   - Translate to other languages

4. **Add Examples**
   - Contribute real-world plugin examples
   - Document complex integration patterns
   - Share testing strategies

## Types of Contributions

### 1. Bug Fixes
- Corrections to incorrect information
- Fixes for broken links
- Typo corrections

### 2. Enhancements
- New sections in the workflow
- Additional best practices
- Expanded debugging guide
- New code examples

### 3. Examples
- Complete plugin examples
- Integration patterns
- Testing templates
- CI/CD configurations

### 4. Translations
- Translate documentation to other languages
- Maintain translation accuracy

## Contribution Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/dify-plugin-skill.git
cd dify-plugin-skill

# Add upstream remote
git remote add upstream https://github.com/langgenius/dify-plugin-skill.git
```

### 2. Create a Branch

```bash
# Create a descriptive branch name
git checkout -b feature/add-model-plugin-examples
# or
git checkout -b fix/correct-oauth-flow
# or
git checkout -b docs/improve-debugging-guide
```

### 3. Make Your Changes

- Edit the relevant files
- Follow the [Documentation Standards](#documentation-standards)
- Test your changes (see [Testing](#testing-your-changes))

### 4. Commit Your Changes

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Add Model plugin development examples"
```

See [Commit Message Guidelines](#commit-message-guidelines) below.

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/add-model-plugin-examples

# Create a Pull Request on GitHub
# Include:
# - Clear description of changes
# - Motivation for the change
# - Testing done (if applicable)
# - Screenshots (if visual changes)
```

### 6. Respond to Feedback

- Address review comments promptly
- Make requested changes
- Push updates to the same branch

## Documentation Standards

### Structure

- Use clear, concise language
- Break down complex concepts into steps
- Provide code examples for technical content
- Use consistent formatting

### Markdown Style

```markdown
# Main Heading (H1) - One per document

## Section Heading (H2)

### Subsection Heading (H3)

**Bold** for emphasis
*Italic* for slight emphasis
`code` for inline code
```

### Code Blocks

Always specify the language:

````markdown
```python
# Python code example
def example():
    pass
```

```yaml
# YAML example
key: value
```

```bash
# Bash commands
dify plugin package ./my-plugin
```
````

### Links

- Use descriptive link text
- Prefer relative links for internal references
- Check that all links work

```markdown
[Dify Official Plugins](https://github.com/langgenius/dify-official-plugins)
[Tool Plugin Guide](references/tool-plugin.md)
```

## Code Examples Standards

### Good Example Structure

```markdown
### Example: Creating a Tool

**Problem**: Need to fetch data from an API

**Solution**:
```python
from dify_plugin import Tool
from typing import Any, Generator

class GetDataTool(Tool):
    def _invoke(self, tool_parameters: dict[str, Any]) -> Generator[ToolInvokeMessage, None, None]:
        # Implementation
        pass
```

**Key Points**:
- Always include type hints
- Handle errors gracefully
- Return JSON directly
```

### Include Both Good and Bad Examples

```markdown
### ❌ Bad Practice

```python
# Don't use LLM for simple formatting
yield self.create_text_message(
    self.session.model.summary.invoke(...)
)
```

### ✅ Good Practice

```python
# Return JSON directly
yield self.create_json_message(data)
```
```

## Testing Your Changes

### 1. Validate Markdown

```bash
# Check for broken links
# (Install markdown-link-check if needed)
markdown-link-check SKILL.md
markdown-link-check README.md
```

### 2. Test with Claude Code

If you're adding workflow steps or examples:

1. Copy the skill to Claude Code skills directory
   ```bash
   cp -r . ~/.claude/skills/dify-plugin-skill/
   ```

2. Ask Claude Code to create a test plugin using your updates
   ```
   Using the dify-plugin skill, create a test plugin for [API name]
   ```

3. Verify the workflow is followed correctly

### 3. Test Code Examples

If you've added code examples:

1. Create a test plugin environment
2. Run the code to ensure it works
3. Verify output matches expectations

## Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: New feature or enhancement
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Formatting changes (whitespace, etc.)
- `refactor`: Code restructuring without changing behavior
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Scope

- `workflow`: Changes to development workflow
- `pitfalls`: Updates to common pitfalls section
- `debugging`: Updates to debugging guide
- `examples`: New or updated examples
- `references`: Changes to reference documentation

### Examples

```bash
# Good commit messages
git commit -m "feat(workflow): Add Phase 5 credential testing checklist"
git commit -m "fix(debugging): Correct httpx exception handling example"
git commit -m "docs(examples): Add QuickBooks Payments plugin example"
git commit -m "feat(pitfalls): Add OAuth token refresh pitfall"

# Bad commit messages (avoid these)
git commit -m "update"
git commit -m "fix stuff"
git commit -m "docs"
```

### Subject Line

- Use imperative mood: "Add" not "Added" or "Adds"
- Don't capitalize the first letter
- No period at the end
- Keep under 50 characters

### Body (optional but recommended)

- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line

### Footer (if applicable)

```
Closes #123
Fixes #456
Related to #789
```

## Version Updates

When your contribution requires a version bump:

### Update CHANGELOG.md

Add your changes under the appropriate section:

```markdown
## [Unreleased]

### Added
- New feature you added

### Changed
- What you modified

### Fixed
- What you fixed
```

### Update SKILL.md Version (if major changes)

```yaml
---
version: 1.1.0  # Increment appropriately
---
```

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, major restructuring
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, typos, clarifications

## Review Process

### What Reviewers Look For

1. **Accuracy**: Is the information correct?
2. **Clarity**: Is it easy to understand?
3. **Completeness**: Are examples complete and working?
4. **Consistency**: Does it match existing style?
5. **Value**: Does it add value to users?

### Timeline

- Initial review: 1-3 days
- Follow-up reviews: 1-2 days
- Merge: After approval and CI passes

## Questions?

- Open an issue for questions
- Tag with "question" label
- We'll respond within 24-48 hours

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md (coming soon)
- Mentioned in release notes
- Credited in relevant documentation

Thank you for contributing! 🎉
