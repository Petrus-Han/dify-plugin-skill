# Trigger Plugin Development

Trigger plugins receive external webhooks to start Dify workflows.

## Structure

```
my-trigger/
├── provider/
│   ├── provider.yaml     # Subscription config + credentials
│   └── provider.py       # Trigger + SubscriptionConstructor
├── events/
│   ├── event_name.yaml   # Event definition
│   └── event_name.py     # Event handler
├── manifest.yaml
├── main.py
└── requirements.txt
```

## manifest.yaml (Trigger)

```yaml
version: 0.1.0
type: plugin
author: your-name
name: my_trigger
# ...
plugins:
  triggers: # Note: triggers, not tools
    - provider/provider.yaml
```

## provider.yaml (Trigger)

```yaml
identity:
  author: your-name
  name: my_trigger
  label:
    en_US: My Trigger
  description:
    en_US: Receives webhook events
  icon: icon.svg

# User fills when creating subscription
subscription_schema:
  - name: webhook_secret
    type: secret-input
    required: false
    label:
      en_US: Webhook Secret

# Parameters for creating subscription
subscription_constructor:
  parameters:
    - name: events
      type: checkbox
      required: true
      multiple: true
      options:
        - value: event_a
          label:
            en_US: Event A
        - value: event_b
          label:
            en_US: Event B

  credentials_schema:
    access_token:
      type: secret-input
      required: true
      label:
        en_US: Access Token

events:
  - events/my_event.yaml

extra:
  python:
    source: provider/provider.py
```

## event.yaml

```yaml
identity:
  name: my_event
  author: your-name
  label:
    en_US: My Event

description:
  en_US: Triggers when event occurs

parameters:
  - name: filter_field
    type: string
    required: false
    label:
      en_US: Filter Field

output_schema:
  type: object
  properties:
    id:
      type: string
    data:
      type: object

extra:
  python:
    source: events/my_event.py
```

## Trigger Implementation

```python
import hmac
import hashlib
from werkzeug import Request, Response

from dify_plugin.entities.trigger import EventDispatch, Subscription
from dify_plugin.errors.trigger import TriggerDispatchError, TriggerValidationError
from dify_plugin.interfaces.trigger import Trigger

class MyTrigger(Trigger):
    def _dispatch_event(
        self,
        subscription: Subscription,
        request: Request
    ) -> EventDispatch:
        # Validate signature (optional)
        secret = subscription.properties.get("webhook_secret")
        if secret:
            self._validate_signature(request, secret)

        # Parse payload
        payload = request.get_json(force=True)

        # Determine event types
        event_types = self._resolve_events(payload)

        response = Response('{"status": "ok"}', status=200, mimetype="application/json")
        return EventDispatch(events=event_types, response=response)

    def _validate_signature(self, request: Request, secret: str) -> None:
        signature = request.headers.get("X-Signature")
        expected = hmac.new(secret.encode(), request.get_data(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(signature or "", expected):
            raise TriggerValidationError("Invalid signature")

    def _resolve_events(self, payload: dict) -> list[str]:
        return ["my_event"]
```

## SubscriptionConstructor Implementation

```python
from collections.abc import Mapping
from typing import Any
import time

from dify_plugin.entities.provider_config import CredentialType
from dify_plugin.entities.trigger import Subscription, UnsubscribeResult
from dify_plugin.errors.trigger import SubscriptionError, TriggerProviderCredentialValidationError
from dify_plugin.interfaces.trigger import TriggerSubscriptionConstructor

class MySubscriptionConstructor(TriggerSubscriptionConstructor):
    def _validate_api_key(self, credentials: Mapping[str, Any]) -> None:
        token = credentials.get("access_token")
        if not token:
            raise TriggerProviderCredentialValidationError("Token required")
        # Validate with API call

    def _create_subscription(
        self,
        endpoint: str,                    # Dify's webhook URL
        parameters: Mapping[str, Any],    # User's subscription params
        credentials: Mapping[str, Any],
        credential_type: CredentialType,
    ) -> Subscription:
        # Create webhook on external service
        # ...
        return Subscription(
            endpoint=endpoint,
            parameters=parameters,
            properties={
                "external_id": "webhook-id",
                "webhook_secret": "generated-secret",
            },
        )

    def _delete_subscription(
        self,
        subscription: Subscription,
        credentials: Mapping[str, Any],
        credential_type: CredentialType
    ) -> UnsubscribeResult:
        # Delete webhook from external service
        return UnsubscribeResult(success=True, message="Deleted")
```

## Event Implementation

```python
from collections.abc import Mapping
from typing import Any
from werkzeug import Request

from dify_plugin.entities.trigger import Variables
from dify_plugin.errors.trigger import EventIgnoreError
from dify_plugin.interfaces.trigger import Event

class MyEvent(Event):
    def _on_event(
        self,
        request: Request,
        parameters: Mapping[str, Any],   # Event filter params
        payload: Mapping[str, Any]
    ) -> Variables:
        # Apply filters
        filter_value = parameters.get("filter_field")
        if filter_value and payload.get("field") != filter_value:
            raise EventIgnoreError()  # Skip this event

        # Return variables for workflow
        return Variables(variables={**payload})
```
