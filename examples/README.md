# Plugin Examples

This directory will contain complete, working examples of Dify plugins demonstrating the patterns and practices described in the skill.

## Planned Examples

### 1. Simple API Integration (Coming Soon)
- **Plugin**: Weather API Tool Plugin
- **Features**: Basic API calls, error handling, environment selection
- **Complexity**: Beginner
- **Demonstrates**: Phase 0-7 of the workflow

### 2. OAuth2 Integration (Coming Soon)
- **Plugin**: GitHub Tools Plugin (simplified)
- **Features**: OAuth2 flow, token refresh, multiple tools
- **Complexity**: Intermediate
- **Demonstrates**: OAuth implementation, credential management

### 3. Webhook Trigger (Coming Soon)
- **Plugin**: Webhook Receiver Trigger Plugin
- **Features**: Signature verification, event filtering
- **Complexity**: Intermediate
- **Demonstrates**: Trigger plugin development, security best practices

### 4. Payment Processing (Coming Soon)
- **Plugin**: Payment Gateway Tool Plugin
- **Features**: Tokenization, charge processing, refunds
- **Complexity**: Advanced
- **Demonstrates**: Multi-step workflows, dependency management

## Example Structure

Each example will include:

```
example-plugin/
├── README.md              # Example-specific documentation
├── _assets/
│   └── icon.svg
├── provider/
│   ├── provider.yaml
│   └── provider.py
├── tools/
│   ├── tool_name.yaml
│   └── tool_name.py
├── manifest.yaml
├── main.py
├── requirements.txt
├── .gitignore
├── tests/                 # Test examples
│   └── test_local.py
└── docs/
    └── API_NOTES.md       # API-specific notes
```

## Contributing Examples

Have a great plugin example to share?

1. Ensure it follows the workflow in SKILL.md
2. Include comprehensive documentation
3. Add local tests
4. See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines

## Real-World References

For real production examples, see:
- Mercury Tools Plugin - In the original project
- QuickBooks Payments Plugin - In the original project
- Mercury Trigger Plugin - In the original project

(Links will be added when examples are published)
