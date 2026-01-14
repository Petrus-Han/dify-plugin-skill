# Model Plugin Development

Model plugins add new AI model providers (LLM, Embedding, TTS, etc.).

## Structure

```
my-model/
├── provider/
│   ├── provider.yaml     # Provider config
│   └── provider.py       # Provider implementation
├── models/
│   └── llm/
│       ├── model.yaml    # Model definition
│       └── model.py      # Model implementation
├── manifest.yaml
├── main.py
└── requirements.txt
```

## manifest.yaml (Model)

```yaml
plugins:
  models:
    - provider/provider.yaml
```

## provider.yaml (Model)

```yaml
provider: my_provider
label:
  en_US: My Provider
icon_small:
  en_US: icon_small.svg
icon_large:
  en_US: icon_large.svg
supported_model_types:
  - llm
  - text-embedding

credentials_for_provider:
  api_key:
    type: secret-input
    required: true
    label:
      en_US: API Key

models:
  - models/llm/model.yaml
```

## LLM Implementation

```python
from collections.abc import Generator
from dify_plugin import OAICompatLargeLanguageModel
from dify_plugin.entities.model.llm import LLMResult, LLMResultChunk
from dify_plugin.entities.model.message import PromptMessage

class MyLLM(OAICompatLargeLanguageModel):
    def _invoke(
        self,
        model: str,
        credentials: dict,
        prompt_messages: list[PromptMessage],
        model_parameters: dict,
        tools: list | None = None,
        stop: list[str] | None = None,
        stream: bool = True,
        user: str | None = None,
    ) -> Generator[LLMResultChunk] | LLMResult:
        # Implement model invocation
        pass
```

## Model Types

| Type        | Class                | Use                |
| ----------- | -------------------- | ------------------ |
| LLM         | `LargeLanguageModel` | Text generation    |
| Embedding   | `TextEmbeddingModel` | Text embeddings    |
| TTS         | `TTSModel`           | Text-to-speech     |
| Speech2Text | `Speech2TextModel`   | Speech recognition |
| Moderation  | `ModerationModel`    | Content moderation |
| Rerank      | `RerankModel`        | Document reranking |
