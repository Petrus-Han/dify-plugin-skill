# Using the Dify Plugin Development Skill

This guide explains how to use the Dify Plugin Development Skill with Claude Code.

## Installation

### Option 1: Manual Copy (Recommended)

1. **Clone this repository**
   ```bash
   git clone https://github.com/langgenius/dify-plugin-skill.git
   cd dify-plugin-skill
   ```

2. **Copy to Claude Code skills directory**
   ```bash
   # Create skills directory if it doesn't exist
   mkdir -p ~/.claude/skills

   # Copy the skill
   cp -r . ~/.claude/skills/dify-plugin
   ```

3. **Verify installation**
   ```bash
   ls ~/.claude/skills/dify-plugin/
   # Should show: SKILL.md, references/, README.md, etc.
   ```

### Option 2: Symbolic Link

```bash
# Clone the repo
git clone https://github.com/langgenius/dify-plugin-skill.git

# Create symbolic link
ln -s $(pwd)/dify-plugin-skill ~/.claude/skills/dify-plugin

# Pull updates anytime
cd dify-plugin-skill && git pull
```

## Using the Skill

### Basic Usage

Simply ask Claude Code to use the skill when developing Dify plugins:

```
Using the dify-plugin skill, help me create a Stripe payments plugin
```

Claude Code will automatically:
1. Load the skill
2. Follow the 8-phase workflow
3. Apply best practices
4. Avoid common pitfalls

### Specific Workflow Phases

You can ask Claude Code to help with specific phases:

```
Using the dify-plugin skill, help me with Phase 3: Planning for my Twilio SMS plugin
```

```
Using the dify-plugin skill, review my provider implementation for OAuth2 correctness
```

### Debugging Assistance

Reference the debugging guide:

```
I'm getting "permission denied, you need to enable llm access" error.
Use the dify-plugin skill debugging guide to help fix this.
```

## Common Use Cases

### 1. Starting a New Plugin

```
I want to integrate the Airtable API with Dify.
Using the dify-plugin skill, guide me through creating this plugin from scratch.
```

**What Claude will do**:
- Phase 0: Research Airtable API
- Phase 1: Analyze requirements
- Phase 2: Define scope (list of tools)
- Phase 3: Create implementation plan
- Ask for your approval before proceeding

### 2. Fixing an Existing Plugin

```
My plugin is giving 401 errors in production but works in sandbox.
Using the dify-plugin skill, help me debug this.
```

**What Claude will do**:
- Check debugging guide for 401 errors
- Review environment selection logic
- Suggest credential validation fixes
- Help test the solution

### 3. Adding OAuth2 to a Plugin

```
I have a plugin using API keys, but want to switch to OAuth2.
Using the dify-plugin skill, help me implement OAuth2.
```

**What Claude will do**:
- Reference OAuth2 patterns from the skill
- Guide through provider implementation
- Add token refresh logic
- Update credential schema

### 4. Code Review

```
Can you review my tool implementation using dify-plugin best practices?
```

**What Claude will check**:
- No unnecessary LLM calls
- Correct exception types
- Environment selection
- Error handling
- Return value format

### 5. Testing Guidance

```
Using the dify-plugin skill, help me write local tests for my tools.
```

**What Claude will provide**:
- Mock runtime setup
- Test structure templates
- Diagnostic script examples
- Testing checklist

## Advanced Usage

### Custom Workflow

Skip phases you've already completed:

```
I've already done Phase 0-2 for my SendGrid plugin.
Using the dify-plugin skill, start from Phase 3: Planning.
```

### Specific Sections

Reference specific sections directly:

```
Show me examples from the dify-plugin skill's "Common Pitfalls" section
that relate to exception handling.
```

### Update Existing Plugin

```
I have an existing plugin that needs to support multiple environments.
Using the dify-plugin skill best practices, help me add this feature.
```

## Tips for Best Results

### 1. Be Specific About Your API

```
✅ Good:
"I'm integrating Mailchimp Marketing API v3.0 which uses OAuth2 with
read/write scopes. Help me create a Dify plugin using the dify-plugin skill."

❌ Too Vague:
"Help me make a Mailchimp plugin."
```

### 2. Mention Your Current Phase

```
✅ Good:
"I'm at Phase 4 (Development) for my Notion plugin. I need help implementing
the provider OAuth flow. Use the dify-plugin skill."

❌ Less Helpful:
"My Notion plugin needs OAuth."
```

### 3. Share Error Messages

```
✅ Good:
"I'm getting this error: 'AttributeError: module httpx has no attribute RequestException'
Check the dify-plugin skill debugging guide for a solution."

❌ Less Helpful:
"My plugin has an error."
```

### 4. Reference Real Examples

```
✅ Good:
"I want to create a plugin similar to the Mercury Tools example in the
dify-plugin skill, but for Plaid API."

❌ Less Clear:
"I need a banking API plugin."
```

## Workflow Example

Here's a complete example of using the skill to build a plugin:

### Step 1: Initial Request

```
I need to integrate the Twilio API with Dify to send SMS messages.
Using the dify-plugin skill, help me create this plugin.
```

### Step 2: Claude's Response

Claude will:
1. Load the skill
2. Start with Phase 0 (Pre-Planning)
3. Research Twilio API basics
4. Ask clarifying questions:
   - "What specific Twilio features do you need?"
   - "Do you have Twilio credentials ready?"
   - "Which environment should we start with?"

### Step 3: Planning Phase

```
I need these features:
- Send SMS
- Check SMS status
- List messages

I have Twilio sandbox credentials. Let's start with sandbox.
```

Claude will:
1. Create Phase 2 scope definition
2. List 3 tools: send_sms, get_sms_status, list_messages
3. Use TodoWrite to create task list
4. Present plan for your approval

### Step 4: Development

After you approve, Claude will:
1. Create directory structure
2. Implement provider with credential validation
3. Implement each tool in order
4. Follow code review checklist
5. Ask you to test each phase

### Step 5: Testing

```
Great! Now help me test the plugin locally.
```

Claude will:
1. Create diagnostic script
2. Set up mock runtime
3. Guide you through credential testing
4. Help package the plugin

## Troubleshooting

### Skill Not Loading

If Claude Code doesn't seem to be using the skill:

1. **Check installation**
   ```bash
   ls ~/.claude/skills/dify-plugin/SKILL.md
   # Should exist
   ```

2. **Restart Claude Code**
   - Close and reopen Claude Code application
   - Skills are loaded at startup

3. **Explicitly reference it**
   ```
   Using the dify-plugin skill from ~/.claude/skills/dify-plugin,
   help me create a plugin.
   ```

### Skill Out of Date

Update the skill:

```bash
cd ~/.claude/skills/dify-plugin
git pull origin main
```

Or if using symlink, just pull in the original repo.

### Getting Old Information

If Claude Code is giving outdated advice:

```
Use the LATEST version of the dify-plugin skill (check Phase 4 code review
checklist) to review my exception handling.
```

## Keeping the Skill Updated

### Watch for Updates

```bash
# In the skill repository
git remote -v
# Should show: origin https://github.com/langgenius/dify-plugin-skill.git

# Check for updates
git fetch origin
git log HEAD..origin/main

# Update if there are new commits
git pull origin main
```

### Subscribe to Releases

- Watch the GitHub repository
- Enable notifications for new releases
- Review CHANGELOG.md for important updates

## Feedback and Issues

Found a problem or have a suggestion?

1. **Check existing issues**: [GitHub Issues](https://github.com/langgenius/dify-plugin-skill/issues)
2. **Open a new issue**: Include:
   - What you were trying to do
   - What went wrong
   - Your Claude Code version
   - Steps to reproduce

## Next Steps

- Read [README.md](README.md) for overview
- Review [SKILL.md](SKILL.md) for complete workflow
- Check [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
- Explore [references/](references/) for specific plugin types

---

**Questions?** Open an issue or check the [FAQ](https://github.com/langgenius/dify-plugin-skill/wiki/FAQ) (coming soon).
