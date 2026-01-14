# Extension Plugin Development

Extension plugins add custom HTTP endpoints to Dify.

## Structure

```
my-extension/
├── group/
│   └── group.yaml        # Endpoint group config
├── endpoints/
│   ├── endpoint.yaml     # Endpoint definition
│   └── endpoint.py       # Endpoint handler
├── manifest.yaml
├── main.py
└── requirements.txt
```

## manifest.yaml (Extension)

```yaml
plugins:
  endpoints:
    - group/group.yaml
```

## group.yaml

```yaml
name: my_group
label:
  en_US: My API Group

endpoints:
  - endpoints/webhook.yaml
  - endpoints/callback.yaml
```

## endpoint.yaml

```yaml
path: "/webhook"
method: "POST"
label:
  en_US: Webhook Endpoint
description:
  en_US: Receives webhook events

extra:
  python:
    source: endpoints/webhook.py
```

## Endpoint Implementation

```python
from werkzeug import Request, Response
from dify_plugin.interfaces.endpoint import Endpoint

class WebhookEndpoint(Endpoint):
    def _invoke(self, request: Request, values: dict, settings: dict) -> Response:
        # Access request data
        data = request.get_json(force=True)

        # Access endpoint settings (configured in Dify)
        api_key = settings.get("api_key")

        # Process and respond
        result = self._process(data)

        return Response(
            response=json.dumps(result),
            status=200,
            mimetype="application/json"
        )
```

## Use Cases

- OAuth callbacks
- Custom API endpoints
- Webhook receivers
- File upload handlers
