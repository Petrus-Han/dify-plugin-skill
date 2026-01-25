# Credentials and Auth

This document explains how to model, validate, and use credentials in Dify plugins.

## Where credentials live

Credentials are defined in provider YAML files:

- Tool: `provider/{provider}.yaml` (field: `credentials_for_provider`)
- Model: `provider/{provider}.yaml` (field: `provider_credential_schema` or `model_credential_schema`)
- Datasource: `provider/{provider}.yaml` (field: `credentials_schema`)
- Trigger: `provider/{provider}.yaml` (field: `credentials_schema` or `oauth_schema` in subscription constructor)
- Extension: `group/{group}.yaml` (field: `settings`)

Use [yaml-schemas.md](./yaml-schemas.md) for common field patterns.

## Credential types

Common types you will use:

- `secret-input` - API keys, tokens, passwords
- `text-input` - host, region, app id
- `select` - fixed choices (region, environment)
- `boolean` - toggles
- `model-selector` / `app-selector` / `array[tools]` - advanced selectors

## Validation rules

Validate credentials in the provider class for your plugin type:

- Tool: `ToolProvider._validate_credentials`
- Model: `ModelProvider.validate_provider_credentials` and/or `validate_model_credentials`
- Datasource: `DatasourceProvider._validate_credentials`
- Trigger: `TriggerSubscriptionConstructor._validate_credentials` (or `_validate_api_key` in examples)

Principles:

1. Validate early and fail fast.
2. Use the SDK error types (see below) so Dify marks the status correctly.
3. Prefer a lightweight API call for validation.

## Error types to raise

Use error types provided by the SDK so the UI and logs show the right failure:

- Tool: `ToolProviderCredentialValidationError`
- Model: `CredentialsValidateFailedError`
- Datasource: `DatasourceProviderCredentialValidationError`
- Trigger: `TriggerProviderCredentialValidationError`

Avoid returning text errors in normal output; raise exceptions for real failures.

## OAuth validation flow (重点)

The official OAuth flow for tool plugins is documented in `dify-docs/en/develop-plugin/dev-guides-and-walkthroughs/tool-oauth.mdx`.
The core requirement is to implement three OAuth methods on your `ToolProvider` so Dify can complete the OAuth flow and refresh tokens.

### 1. Define OAuth schema in provider YAML

Use `oauth_schema` to declare client credentials and token fields:

```yaml
oauth_schema:
  client_schema:
    - name: "client_id"
      type: "secret-input"
      required: true
      url: "https://developers.google.com/identity/protocols/oauth2"
    - name: "client_secret"
      type: "secret-input"
      required: true
  credentials_schema:
    - name: "access_token"
      type: "secret-input"
    - name: "refresh_token"
      type: "secret-input"
    - name: "expires_at"
      type: "secret-input"
```

### 2. Implement OAuth methods in ToolProvider (official pattern)

Add the imports:

```python
from dify_plugin.entities.oauth import ToolOAuthCredentials
from dify_plugin.errors.tool import ToolProviderCredentialValidationError, ToolProviderOAuthError
```

Then implement the three methods below (trimmed from the official doc, keep the flow intact):

```python
def _oauth_get_authorization_url(
    self, redirect_uri: str, system_credentials: Mapping[str, Any]
) -> str:
    state = secrets.token_urlsafe(16)
    params = {
        "client_id": system_credentials["client_id"],
        "redirect_uri": redirect_uri,
        "scope": "read:user read:data",
        "response_type": "code",
        "access_type": "offline",
        "prompt": "consent",
        "state": state,
    }
    return f"{self._AUTH_URL}?{urllib.parse.urlencode(params)}"


def _oauth_get_credentials(
    self,
    redirect_uri: str,
    system_credentials: Mapping[str, Any],
    request: Request,
) -> ToolOAuthCredentials:
    code = request.args.get("code")
    if not code:
        raise ToolProviderOAuthError("Authorization code not provided")

    error = request.args.get("error")
    if error:
        error_description = request.args.get("error_description", "")
        raise ToolProviderOAuthError(f"OAuth authorization failed: {error} - {error_description}")

    data = {
        "client_id": system_credentials["client_id"],
        "client_secret": system_credentials["client_secret"],
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": redirect_uri,
    }

    response = requests.post(self._TOKEN_URL, data=data, timeout=10)
    response.raise_for_status()
    token_data = response.json()

    if "error" in token_data:
        error_desc = token_data.get("error_description", token_data["error"])
        raise ToolProviderOAuthError(f"Token exchange failed: {error_desc}")

    access_token = token_data.get("access_token")
    if not access_token:
        raise ToolProviderOAuthError("No access token received from provider")

    credentials = {
        "access_token": access_token,
        "token_type": token_data.get("token_type", "Bearer"),
    }

    refresh_token = token_data.get("refresh_token")
    if refresh_token:
        credentials["refresh_token"] = refresh_token

    expires_in = token_data.get("expires_in", 3600)
    expires_at = int(time.time()) + expires_in

    return ToolOAuthCredentials(credentials=credentials, expires_at=expires_at)


def _oauth_refresh_credentials(
    self,
    redirect_uri: str,
    system_credentials: Mapping[str, Any],
    credentials: Mapping[str, Any],
) -> ToolOAuthCredentials:
    refresh_token = credentials.get("refresh_token")
    if not refresh_token:
        raise ToolProviderOAuthError("No refresh token available")

    data = {
        "client_id": system_credentials["client_id"],
        "client_secret": system_credentials["client_secret"],
        "refresh_token": refresh_token,
        "grant_type": "refresh_token",
    }

    response = requests.post(self._TOKEN_URL, data=data, timeout=10)
    response.raise_for_status()
    token_data = response.json()

    if "error" in token_data:
        error_desc = token_data.get("error_description", token_data["error"])
        raise ToolProviderOAuthError(f"Token refresh failed: {error_desc}")

    access_token = token_data.get("access_token")
    if not access_token:
        raise ToolProviderOAuthError("No access token received from provider")

    new_credentials = {
        "access_token": access_token,
        "token_type": token_data.get("token_type", "Bearer"),
        "refresh_token": refresh_token,
    }

    new_refresh_token = token_data.get("refresh_token")
    if new_refresh_token:
        new_credentials["refresh_token"] = new_refresh_token

    expires_in = token_data.get("expires_in", 3600)
    expires_at = int(time.time()) + expires_in

    return ToolOAuthCredentials(credentials=new_credentials, expires_at=expires_at)
```


Reference: [dify-docs](../references/dify-docs.md) for OAuth and publishing guidance.

## Example: Tool provider credential schema

```yaml
credentials_for_provider:
  api_key:
    type: secret-input
    required: true
    label:
      en_US: API Key
    help:
      en_US: Get your API key from the provider dashboard
    url: https://example.com/api-keys
```

## Example: Tool credential validation

```python
from dify_plugin.errors.tool import ToolProviderCredentialValidationError

class MyProvider(ToolProvider):
    def _validate_credentials(self, credentials: dict) -> None:
        api_key = credentials.get("api_key")
        if not api_key:
            raise ToolProviderCredentialValidationError("API key is required")

        response = httpx.get(
            "https://api.example.com/me",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=10,
        )
        if response.status_code == 401:
            raise ToolProviderCredentialValidationError("Invalid API key")
        response.raise_for_status()
```

## Debugging tips

- When validation fails in the UI, inspect plugin logs for the error type.
- Confirm the YAML field names match what your code expects.
- Keep a sandbox and production environment selector when providers have both.
