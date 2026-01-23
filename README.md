# Dify Plugin Development Skill

An agent skill for developing Dify plugins.

## Installation

### For Claude Code

```bash
# In Claude Code, run:
/plugin marketplace add Petrus-Han/dify-plugin-skill
/plugin install dify-plugin@dify-plugin-skills
```

### For Codex

```bash
$skill-installer install https://github.com/Petrus-Han/dify-plugin-skill for this repo
```

### For OpenCode

OpenCode skill is Claude-Code-compatible. Install this skill for Claude Code and it will be available for OpenCode.

## What's Included

- Development SOP
- Dify repositories references as context
- Plugin development guide for each plugin type
- Debugging and testing guide
- Best practices and common pitfalls

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

**Maintained by**: Dify

**Status**: Active Development

**Questions?** Open an issue or contribute via pull request!
