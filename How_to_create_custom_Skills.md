# How to Create Custom Skills

Custom Skills let you enhance Claude with specialized knowledge and workflows specific to your organization or personal work style. This article explains how to create, structure, and test your own Skills.

## What Makes a Good Skill?

Skills can be as simple as a few lines of instructions or as complex as multi-file packages with executable code. The best Skills:

- ✅ Solve a specific, repeatable task
- ✅ Have clear instructions that Claude can follow
- ✅ Include examples when helpful
- ✅ Define when they should be used
- ✅ Are focused on one workflow rather than trying to do everything

---

## Creating a Skill.md File

Every Skill consists of a directory containing at minimum a `Skill.md` file, which is the core of the Skill. This file must start with a YAML frontmatter to hold name and description fields, which are required metadata. It can also contain additional metadata, instructions for Claude or reference files, executable scripts, or tools.

### Required Metadata Fields

#### `name`
A human-friendly name for your Skill (64 characters maximum)

**Example:**
```yaml
name: Brand Guidelines
```

#### `description`
A clear description of what the Skill does and when to use it.

**This is critical**—Claude uses this to determine when to invoke your Skill (200 characters maximum).

**Example:**
```yaml
description: Apply Acme Corp brand guidelines to presentations and documents, including official colors, fonts, and logo usage.
```

### Optional Metadata Fields

#### `dependencies`
Software packages required by your Skill.

**Example:**
```yaml
dependencies: python>=3.8, pandas>=1.5.0
```

> **Note:** The metadata in the Skill.md file serves as the first level of a progressive disclosure system, providing just enough information for Claude to know when the Skill should be used without having to load all of the content.

### Markdown Body

The Markdown body is the second level of detail after the metadata, so Claude will access this if needed after reading the metadata. Depending on your task, Claude can access the Skill.md file and use the Skill.

---

## Example Skill.md

### Brand Guidelines Skill

```yaml
## Metadata
name: Brand Guidelines
description: Apply Acme Corp brand guidelines to all presentations and documents

## Overview
This Skill provides Acme Corp's official brand guidelines for creating consistent, professional materials. When creating presentations, documents, or marketing materials, apply these standards to ensure all outputs match Acme's visual identity. Claude should reference these guidelines whenever creating external-facing materials or documents that represent Acme Corp.

## Brand Colors

Our official brand colors are:
- Primary: #FF6B35 (Coral)
- Secondary: #004E89 (Navy Blue)
- Accent: #F7B801 (Gold)
- Neutral: #2E2E2E (Charcoal)

## Typography

Headers: Montserrat Bold
Body text: Open Sans Regular
Size guidelines:
- H1: 32pt
- H2: 24pt
- Body: 11pt

## Logo Usage

Always use the full-color logo on light backgrounds. Use the white logo on dark backgrounds. Maintain minimum spacing of 0.5 inches around the logo.

## When to Apply

Apply these guidelines whenever creating:
- PowerPoint presentations
- Word documents for external sharing
- Marketing materials
- Reports for clients

## Resources

See the resources folder for logo files and font downloads.
```

---

## Adding Resources

If you have too much information to add to a single `Skill.md` file (e.g., sections that only apply to specific scenarios), you can add more content by adding files within your Skill directory.

**Example:** Add a `REFERENCE.md` file containing supplemental and reference information to your Skill directory. Referencing it in Skill.md will help Claude decide if it needs to access that resource when executing the Skill.

### Recommended Structure

```
my-skill/
├── Skill.md           # Core skill definition
├── REFERENCE.md       # Detailed reference material
├── EXAMPLES.md        # Usage examples
└── resources/         # Additional assets
    ├── logo.svg
    └── fonts/
```

---

## Adding Scripts

For more advanced Skills, attach executable code files to `Skill.md`, allowing Claude to run code.

### Supported Languages and Packages

Our document skills use the following programming languages and packages:

- **Python** (pandas, numpy, matplotlib)
- **JavaScript / Node.js**
- **Packages** to help with file editing
- **Visualization tools**

### Package Installation

> **Important:** Claude and Claude Code can install packages from standard repositories (Python PyPI, JavaScript npm) when loading Skills. It's not possible to install additional packages at runtime with API Skills—all dependencies must be pre-installed in the container.

---

## Packaging Your Skill

Once your Skill folder is complete:

1. Ensure the folder name matches your Skill's name
2. Create a ZIP file of the folder
3. The ZIP should contain the Skill folder as its root (not a subfolder)

### ✅ Correct Structure

```
my-skill.zip
  └── my-skill/
      ├── Skill.md
      └── resources/
```

### ❌ Incorrect Structure

```
my-skill.zip
  └── (files directly in ZIP root)
```

---

## Testing Your Skill

### Before Uploading

1. **Review your Skill.md for clarity**
2. **Check that the description accurately reflects when Claude should use the Skill**
3. **Verify all referenced files exist in the correct locations**
4. **Test with example prompts to ensure Claude invokes it appropriately**

### After Uploading to Claude

1. **Enable the Skill** in Settings > Capabilities
2. **Try several different prompts** that should trigger it
3. **Review Claude's thinking** to confirm it's loading the Skill
4. **Iterate on the description** if Claude isn't using it when expected

> **Note for Team and Enterprise plans:** To make a skill available to all users in your organization, see [Provisioning and managing Skills for your organization](https://support.claude.com).

---

## Best Practices

### 🎯 Keep It Focused

Create separate Skills for different workflows. Multiple focused Skills compose better than one large Skill.

### 📝 Write Clear Descriptions

Claude uses descriptions to decide when to invoke your Skill. Be specific about when it applies.

### 🚀 Start Simple

Begin with basic instructions in Markdown before adding complex scripts. You can always expand on the Skill later.

### 💡 Use Examples

Include example inputs and outputs in your Skill.md file to help Claude understand what success looks like.

### 🧪 Test Incrementally

Test after each significant change rather than building a complex Skill all at once.

### 🔗 Skills Can Build on Each Other

While Skills can't explicitly reference other Skills, Claude can use multiple Skills together automatically. This composability is one of the most powerful parts of the Skills feature.

### 📚 Review the Open Agent Skills Specification

Follow the guidelines at [agentskills.io](https://agentskills.io), so skills you create can work across platforms that adopt the standard.

### 📖 Further Reading

For a more in-depth guide to skill creation, refer to [Skill authoring best practices](https://docs.anthropic.com) in our Claude Docs.

---

## Security Considerations

### ⚠️ Important Security Guidelines

- ❌ **Don't hardcode sensitive information** (API keys, passwords)
- ⚠️ **Exercise caution when adding scripts** to your Skill.md file
- 🔍 **Review any Skills you download** before enabling them
- 🔐 **Use appropriate MCP connections** for external service access

---

# Specification

> The complete format specification for Agent Skills.

This document defines the Agent Skills format.

## Directory structure

A skill is a directory containing at minimum a `SKILL.md` file:

```
skill-name/
└── SKILL.md          # Required
```

<Tip>
  You can optionally include [additional directories](#optional-directories) such as `scripts/`, `references/`, and `assets/` to support your skill.
</Tip>

## SKILL.md format

The `SKILL.md` file must contain YAML frontmatter followed by Markdown content.

### Frontmatter (required)

```yaml  theme={null}
---
name: skill-name
description: A description of what this skill does and when to use it.
---
```

With optional fields:

```yaml  theme={null}
---
name: pdf-processing
description: Extract text and tables from PDF files, fill forms, merge documents.
license: Apache-2.0
metadata:
  author: example-org
  version: "1.0"
---
```

| Field           | Required | Constraints                                                  |
| --------------- | -------- | ------------------------------------------------------------ |
| `name`          | Yes      | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen. |
| `description`   | Yes      | Max 1024 characters. Non-empty. Describes what the skill does and when to use it. |
| `license`       | No       | License name or reference to a bundled license file.         |
| `compatibility` | No       | Max 500 characters. Indicates environment requirements (intended product, system packages, network access, etc.). |
| `metadata`      | No       | Arbitrary key-value mapping for additional metadata.         |
| `allowed-tools` | No       | Space-delimited list of pre-approved tools the skill may use. (Experimental) |

#### `name` field

The required `name` field:

* Must be 1-64 characters
* May only contain unicode lowercase alphanumeric characters and hyphens (`a-z` and `-`)
* Must not start or end with `-`
* Must not contain consecutive hyphens (`--`)
* Must match the parent directory name

Valid examples:

```yaml  theme={null}
name: pdf-processing
```

```yaml  theme={null}
name: data-analysis
```

```yaml  theme={null}
name: code-review
```

Invalid examples:

```yaml  theme={null}
name: PDF-Processing  # uppercase not allowed
```

```yaml  theme={null}
name: -pdf  # cannot start with hyphen
```

```yaml  theme={null}
name: pdf--processing  # consecutive hyphens not allowed
```

#### `description` field

The required `description` field:

* Must be 1-1024 characters
* Should describe both what the skill does and when to use it
* Should include specific keywords that help agents identify relevant tasks

Good example:

```yaml  theme={null}
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.
```

Poor example:

```yaml  theme={null}
description: Helps with PDFs.
```

#### `license` field

The optional `license` field:

* Specifies the license applied to the skill
* We recommend keeping it short (either the name of a license or the name of a bundled license file)

Example:

```yaml  theme={null}
license: Proprietary. LICENSE.txt has complete terms
```

#### `compatibility` field

The optional `compatibility` field:

* Must be 1-500 characters if provided
* Should only be included if your skill has specific environment requirements
* Can indicate intended product, required system packages, network access needs, etc.

Examples:

```yaml  theme={null}
compatibility: Designed for Claude Code (or similar products)
```

```yaml  theme={null}
compatibility: Requires git, docker, jq, and access to the internet
```

<Note>
  Most skills do not need the `compatibility` field.
</Note>

#### `metadata` field

The optional `metadata` field:

* A map from string keys to string values
* Clients can use this to store additional properties not defined by the Agent Skills spec
* We recommend making your key names reasonably unique to avoid accidental conflicts

Example:

```yaml  theme={null}
metadata:
  author: example-org
  version: "1.0"
```

#### `allowed-tools` field

The optional `allowed-tools` field:

* A space-delimited list of tools that are pre-approved to run
* Experimental. Support for this field may vary between agent implementations

Example:

```yaml  theme={null}
allowed-tools: Bash(git:*) Bash(jq:*) Read
```

### Body content

The Markdown body after the frontmatter contains the skill instructions. There are no format restrictions. Write whatever helps agents perform the task effectively.

Recommended sections:

* Step-by-step instructions
* Examples of inputs and outputs
* Common edge cases

Note that the agent will load this entire file once it's decided to activate a skill. Consider splitting longer `SKILL.md` content into referenced files.

## Optional directories

### scripts/

Contains executable code that agents can run. Scripts should:

* Be self-contained or clearly document dependencies
* Include helpful error messages
* Handle edge cases gracefully

Supported languages depend on the agent implementation. Common options include Python, Bash, and JavaScript.

### references/

Contains additional documentation that agents can read when needed:

* `REFERENCE.md` - Detailed technical reference
* `FORMS.md` - Form templates or structured data formats
* Domain-specific files (`finance.md`, `legal.md`, etc.)

Keep individual [reference files](#file-references) focused. Agents load these on demand, so smaller files mean less use of context.

### assets/

Contains static resources:

* Templates (document templates, configuration templates)
* Images (diagrams, examples)
* Data files (lookup tables, schemas)

## Progressive disclosure

Skills should be structured for efficient use of context:

1. **Metadata** (\~100 tokens): The `name` and `description` fields are loaded at startup for all skills
2. **Instructions** (\< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is activated
3. **Resources** (as needed): Files (e.g. those in `scripts/`, `references/`, or `assets/`) are loaded only when required

Keep your main `SKILL.md` under 500 lines. Move detailed reference material to separate files.

## File references

When referencing other files in your skill, use relative paths from the skill root:

```markdown  theme={null}
See [the reference guide](references/REFERENCE.md) for details.

Run the extraction script:
scripts/extract.py
```

Keep file references one level deep from `SKILL.md`. Avoid deeply nested reference chains.

## Validation

Use the [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) reference library to validate your skills:

```bash  theme={null}
skills-ref validate ./my-skill
```

This checks that your `SKILL.md` frontmatter is valid and follows all naming conventions.


---

> To find navigation and other pages in this documentation, fetch the llms.txt file at: https://agentskills.io/llms.txt

---

## 
