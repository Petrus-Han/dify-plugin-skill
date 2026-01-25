# Dify Docs

Use this repository to find the official documentation for plugin usage, development, and publishing.

Repo: [langgenius/dify-docs](https://github.com/langgenius/dify-docs)

## Why it matters for this skill

- Source of truth for plugin specs, CLI usage, and publishing rules.
- Explains how plugins appear in the Dify UI (workspace, marketplace, permissions).
- Provides developer guides that align with SDK and daemon behavior.

## Key sections for plugins

The plugin docs live under the “Develop Plugin” navigation in `docs.json`.

- Getting started: `en/develop-plugin/getting-started/`
- Specs and types: `en/develop-plugin/features-and-specs/`
- Advanced topics (reverse invocation, bundle, custom model): `en/develop-plugin/features-and-specs/advanced-development/`
- Guides and walkthroughs: `en/develop-plugin/dev-guides-and-walkthroughs/`
- Publishing: `en/develop-plugin/publishing/`

## User-facing plugin behavior

- Workspace plugin UI: `en/use-dify/workspace/plugins.mdx`

This page explains installation paths (marketplace, GitHub, local upload), workspace scope, and permission controls.

## Reading order

1. `en/use-dify/workspace/plugins.mdx` - how plugins are managed in the product
2. `en/develop-plugin/getting-started/getting-started-dify-plugin.mdx` - plugin dev entry point
3. `en/develop-plugin/features-and-specs/plugin-types/` - required manifest fields and runtime rules
4. `en/develop-plugin/features-and-specs/advanced-development/reverse-invocation.mdx` - backward calls to Dify
5. `en/develop-plugin/publishing/` - marketplace release requirements

## Notes

- Docs are Mintlify MDX with `docs.json` as the navigation source.
- English (`en/`) is the source language; translations are auto-synced to `zh/` and `ja/`.
