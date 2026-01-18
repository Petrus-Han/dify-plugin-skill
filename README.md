# Dify Plugin Development Skill

A comprehensive guide and workflow for developing Dify plugins, designed to be used as a Claude Code Skill.

## Installation

### Option 1: Marketplace (Recommended)

```bash
# In Claude Code, run:
/plugin marketplace add Petrus-Han/dify-plugin-skill
/plugin install dify-plugin@dify-plugin-skills
```

### Option 2: Script Install

```bash
git clone https://github.com/Petrus-Han/dify-plugin-skill.git
cd dify-plugin-skill
./install.sh            # Global install
./install.sh --local    # Project install
```

## Overview

This skill provides a structured, phase-by-phase approach to building reliable Dify plugins, from initial planning to deployment and maintenance. It includes best practices, common pitfalls, debugging strategies, and real-world examples.

## What's Included

### Core Documentation

- **[SKILL.md](skills/dify-plugin/SKILL.md)** - The main skill file containing:
  - 8-phase development workflow
  - Common pitfalls and solutions
  - Debugging guide
  - Best practices
  - Real-world examples
  - Quick start templates

### Reference Documentation

- **[references/tool-plugin.md](skills/dify-plugin/references/tool-plugin.md)** - Tool plugin development guide
- **[references/trigger-plugin.md](skills/dify-plugin/references/trigger-plugin.md)** - Trigger plugin development guide
- **[references/extension-plugin.md](skills/dify-plugin/references/extension-plugin.md)** - Extension plugin development guide
- **[references/model-plugin.md](skills/dify-plugin/references/model-plugin.md)** - Model plugin development guide
- **[references/yaml-schemas.md](skills/dify-plugin/references/yaml-schemas.md)** - YAML configuration schemas
- **[references/debugging.md](skills/dify-plugin/references/debugging.md)** - Debugging and deployment guide

## Development Workflow

### Phase 0: Pre-Planning 🔍
- Identify plugin type (Tool/Trigger/Model/Extension)
- Research target API documentation
- Check official examples in `dify-official-plugins`

### Phase 1: Requirements Analysis ✅
- Define user needs and integration goals
- Identify authentication method (API Key/OAuth2)
- Confirm data flow direction

### Phase 2: Scope Definition 📋
- List all tools (3-7 recommended for MVP)
- Set priorities (MVP vs extensions)
- Map tool dependencies
- Note API limitations

### Phase 3: Planning & Approval 📝
- Create task list with `TodoWrite`
- Document key files to create
- Identify technical risks
- Get user confirmation

### Phase 4: Development 🔨
- Build plugin skeleton
- Implement provider (OAuth/validation)
- Implement tools in dependency order
- Code review (check for LLM calls, exception types, etc.)

### Phase 5: Credential Testing 🔑
- Setup test environment (Sandbox preferred)
- Collect and validate credentials
- Write diagnostic scripts
- Test provider validation

### Phase 6: End-to-End Testing 🧪
- Local testing with mock runtime
- Package testing (`dify plugin package`)
- Upload and configure in Dify
- Test all tools individually and in workflows

### Phase 7: Documentation & Release 📚
- Write README and API docs
- Follow semantic versioning
- Quality checklist
- Final packaging

### Phase 8: Maintenance & Iteration 🔄
- Monitor user feedback
- Add features (increment minor version)
- Fix bugs (increment patch version)

## Common Pitfalls

### ❌ Don't:
1. Use LLM calls in tools for simple data formatting
2. Use `httpx.RequestException` (doesn't exist)
3. Hardcode API URLs without environment selection
4. Mix different APIs in one plugin
5. Use invalid tags (e.g., "banking", "payments")
6. Request unnecessary permissions (e.g., model permission when not using LLM)

### ✅ Do:
1. Return structured JSON data directly
2. Use `httpx.HTTPError` for exception handling
3. Support multiple environments (Sandbox/Production)
4. Separate concerns (one plugin per API service)
5. Use official tags (finance, utilities, productivity)
6. Test thoroughly before release

## Quick Start

1. **Install Prerequisites**
   ```bash
   brew tap langgenius/dify && brew install dify
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Initialize Plugin**
   ```bash
   dify plugin init --quick --name my-plugin --category tool --language python
   cd my-plugin
   uv init --no-readme
   uv add dify_plugin
   ```

3. **Follow the Workflow**
   - Start at Phase 0: Research the API you're integrating
   - Use the skill as a checklist for each phase
   - Reference examples in this guide

## Real-World Examples

This skill is based on real plugin development experience:

- **Mercury Tools Plugin** - OAuth2, environment selection, no LLM calls
- **QuickBooks Payments Plugin** - Tokenization, payment processing
- **Mercury Trigger Plugin** - Webhook handling, signature verification

## Best Practices

### Naming Conventions
```
Plugin Directory:    my_service_plugin/
Plugin Name:         my_service
Provider Files:      provider/my_service.{yaml,py}
Tool Files:          tools/{action}_{resource}.{yaml,py}
```

### Version Management
```yaml
0.1.0  # Initial release
0.2.0  # New feature (backward compatible)
0.2.1  # Bug fix
1.0.0  # Breaking change
```

### Security
- Never commit API keys or tokens
- Use OAuth2 when available
- Implement token refresh logic
- Validate all user inputs
- Use HTTPS for all API calls

## Using This Skill with Claude Code

After installation (see Installation section above), simply ask Claude to help you build a Dify plugin:

- "Help me create a Stripe payments plugin for Dify"
- "Build a Dify trigger plugin for GitHub webhooks"
- "Create a Dify model plugin for my custom LLM API"

Claude will automatically use the skill to guide you through:
- Phase-by-phase development
- Automatic error detection and prevention
- Best practice recommendations
- Testing strategies

## Debugging Common Errors

### "permission denied, you need to enable llm access"
**Cause**: Tool uses `self.session.model.summary.invoke()` without model permission.
**Fix**: Remove LLM calls, return JSON directly.

### "AttributeError: module 'httpx' has no attribute 'RequestException'"
**Cause**: Wrong exception type.
**Fix**: Use `httpx.HTTPError` instead.

### "401 Unauthorized" in production
**Cause**: Using sandbox credentials in production.
**Fix**: Add environment selection to provider.

### "404 Not Found" on API calls
**Cause**: Wrong API base URL.
**Fix**: Verify URL construction and environment logic.

## Contributing

This skill is designed to evolve with the Dify plugin ecosystem. Contributions are welcome!

### How to Contribute

1. **Share Your Experience**
   - Add new pitfalls you've encountered
   - Document solutions to common problems
   - Share plugin examples

2. **Improve Documentation**
   - Clarify confusing sections
   - Add more code examples
   - Update for new Dify versions

3. **Add Examples**
   - Contribute real-world plugin examples
   - Document complex integration patterns
   - Share testing strategies

### Workflow for Updates

1. Fork or branch from main
2. Make your changes
3. Test with a real plugin development scenario
4. Submit pull request with clear description
5. Include version bump in SKILL.md if applicable

## Resources

- [Dify Official Plugins](https://github.com/langgenius/dify-official-plugins)
- [Dify Plugin Documentation](https://docs.dify.ai/plugins)
- [Dify SDK (Python)](https://pypi.org/project/dify-plugin/)
- [Claude Code Skills Guide](https://docs.anthropic.com/claude/docs/claude-code-skills)

## License

MIT License - See LICENSE file for details

## Changelog

### Version 1.0.0 (2026-01-14)
- Initial release with 8-phase workflow
- Common pitfalls and debugging guide
- Best practices and real-world examples
- Based on Mercury and QuickBooks plugin development experience

---

**Maintained by**: [Your Name/Organization]

**Status**: Active Development

**Questions?** Open an issue or contribute via pull request!
