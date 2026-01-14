# Changelog

All notable changes to the Dify Plugin Development Skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-14

### Added
- **8-Phase Development Workflow**
  - Phase 0: Pre-Planning (plugin type identification, API research)
  - Phase 1: Requirements Analysis (needs, authentication, data flow)
  - Phase 2: Scope Definition (tool listing, priorities, dependencies)
  - Phase 3: Planning & Approval (task lists, file documentation)
  - Phase 4: Development (skeleton, provider, tools, code review)
  - Phase 5: Credential Testing (environment setup, validation)
  - Phase 6: End-to-End Testing (local, package, upload, integration)
  - Phase 7: Documentation & Release (docs, versioning, quality)
  - Phase 8: Maintenance & Iteration (monitoring, features, fixes)

- **Common Pitfalls Section**
  - 6 "Don't" patterns with code examples
  - 6 "Do" best practices with code examples
  - Based on real development experience

- **Debugging Guide**
  - Common errors with causes and solutions
  - "permission denied" LLM access error
  - httpx.RequestException AttributeError
  - 401/404 API errors
  - Empty data issues

- **Best Practices**
  - Naming conventions
  - Version management (Semver)
  - Security guidelines
  - Performance optimization
  - Code quality standards

- **Real-World Examples**
  - Mercury Tools Plugin (OAuth2, environment selection)
  - QuickBooks Payments Plugin (tokenization, payments)
  - Mercury Trigger Plugin (webhooks, verification)

- **Reference Documentation**
  - Tool plugin guide
  - Trigger plugin guide
  - Extension plugin guide
  - Model plugin guide
  - YAML schemas reference
  - Debugging and deployment guide

### Changed
- Reorganized SKILL.md structure to prioritize workflow
- Moved Plugin Types section after Development Workflow
- Enhanced Quick Start section with clearer steps

### Documentation
- Comprehensive README.md with overview and quick start
- MIT License
- This CHANGELOG.md
- .gitignore for clean repository

### Based On
- Real plugin development experience:
  - Mercury Banking integration (Tools + Trigger)
  - QuickBooks Payments API integration
  - OAuth2 implementation patterns
  - Error handling and debugging strategies

---

## Future Plans

### [1.1.0] - Planned
- [ ] Add examples directory with complete plugin samples
- [ ] Add testing framework templates
- [ ] Add CI/CD pipeline examples
- [ ] Expand debugging guide with more scenarios

### [1.2.0] - Planned
- [ ] Add Model plugin workflow specifics
- [ ] Add Extension plugin workflow details
- [ ] Add Agent Strategy plugin examples
- [ ] Add multi-plugin coordination patterns

### [2.0.0] - Future
- [ ] Support for Dify 2.x plugin architecture
- [ ] Advanced patterns (state management, caching)
- [ ] Performance optimization techniques
- [ ] Plugin marketplace preparation guide

---

## Contributing

See [README.md](README.md#contributing) for contribution guidelines.

## Resources

- [Dify Official Plugins](https://github.com/langgenius/dify-official-plugins)
- [Dify Documentation](https://docs.dify.ai/)
- [Claude Code Skills](https://docs.anthropic.com/claude/docs/claude-code-skills)
