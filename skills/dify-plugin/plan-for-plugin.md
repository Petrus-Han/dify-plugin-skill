# Before starting writing a plugin

- Clone all the reference repos and get basic knowledge of Dify plugins:
  - [dify](https://github.com/langgenius/dify)
  - [dify-plugin-daemon](https://github.com/langgenius/dify-plugin-daemon)
  - [dify-official-plugins](https://github.com/langgenius/dify-official-plugins)
  - [dify-plugin-sdks](https://github.com/langgenius/dify-plugin-sdks)
  - [dify-docs](https://github.com/langgenius/dify-docs)
- Determine plugin type in:
  - `model`
  - `tool`
  - `trigger`
  - `datasource`
  - `extension`
  - `agent-strategy`
- If integrating external API, pull their API documentation to local files as reference.
- If authentication is required, determine the credential type and how it's handled.
- Find similar plugin in `dify-official-plugins` as reference.
- Plan plugin architecture and behavior.
