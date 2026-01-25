# Code Examples: Plugin Client Implementations

This document provides full-featured client implementations in various programming languages to help you integrate with Dify plugins running locally.

---

## Python (Standard I/O)

This implementation uses `subprocess` and provides a robust way to handle the request-response stream.

```python
import json
import subprocess
from typing import Dict, Any, Iterator

class PluginClient:
    def __init__(self, plugin_path: str):
        self.plugin_path = plugin_path
        self.proc = None
        self.invoke_counter = 0

    def __enter__(self):
        self.proc = subprocess.Popen(
            ["dify", "plugin", "run", self.plugin_path, "-m", "stdio", "-r", "json"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        self._skip_startup()
        return self

    def __exit__(self, *args):
        if self.proc:
            self.proc.terminate()
            self.proc.wait(timeout=5)

    def _skip_startup(self):
        # Skip info and plugin_ready messages
        self.proc.stdout.readline()  # info: loading plugin
        self.proc.stdout.readline()  # plugin_ready: plugin loaded

    def invoke(self, access_type: str, action: str, request: Dict) -> Iterator[Dict[str, Any]]:
        self.invoke_counter += 1
        invoke_id = f"req-{self.invoke_counter:05d}"

        payload = {
            "invoke_id": invoke_id,
            "type": access_type,
            "action": action,
            "request": request
        }

        self.proc.stdin.write(json.dumps(payload) + "\n")
        self.proc.stdin.flush()

        while True:
            line = self.proc.stdout.readline()
            if not line:
                break
            msg = json.loads(line)

            if msg.get("invoke_id") != invoke_id:
                continue

            msg_type = msg.get("type")

            if msg_type == "plugin_response":
                yield msg["response"]
            elif msg_type == "plugin_invoke_end":
                break
            elif msg_type == "error":
                raise RuntimeError(msg["response"]["error"])

# Usage
if __name__ == "__main__":
    with PluginClient("plugin.difypkg") as client:
        responses = list(client.invoke(
            "tool",
            "invoke_tool",
            {"tool_name": "calculator", "expression": "2+2"}
        ))
        print("Responses:", responses)
```

---

## Bash Script

A simple script using `jq` to parse JSON.

```bash
#!/bin/bash

PLUGIN_PATH="$1"
ACTION_TYPE="${2:-tool}"
ACTION_NAME="${3:-invoke_tool}"
REQUEST_JSON="${4:-{}}"

dify plugin run "$PLUGIN_PATH" -m stdio -r json | {
    # Skip startup messages
    read -r
    read -r

    # Send request
    REQUEST_ID="req-001"
    PAYLOAD=$(cat <<EOF
{
  "invoke_id": "$REQUEST_ID",
  "type": "$ACTION_TYPE",
  "action": "$ACTION_NAME",
  "request": $REQUEST_JSON
}
EOF
)
    echo "$PAYLOAD"

    # Read response
    while read -r line; do
        if echo "$line" | jq -e ".invoke_id == \"$REQUEST_ID\" and .type == \"plugin_response\"" >/dev/null 2>&1; then
            echo "$line" | jq '.response'
        elif echo "$line" | jq -e ".invoke_id == \"$REQUEST_ID\" and .type == \"plugin_invoke_end\"" >/dev/null 2>&1; then
            break
        fi
    done
}
```

---

## TCP Mode - Python Example

In TCP mode, the client connects to the plugin over a network socket.

```python
import json
import socket
from typing import Dict, Any, List

class TCPPluginClient:
    def __init__(self, host: str, port: int):
        self.host = host
        self.port = port
        self.socket = None
        self.invoke_counter = 0

    def connect(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))

    def disconnect(self):
        if self.socket:
            self.socket.close()

    def invoke(self, access_type: str, action: str, request: dict) -> List[Dict]:
        self.invoke_counter += 1
        invoke_id = f"req-{self.invoke_counter:05d}"

        payload = {
            "invoke_id": invoke_id,
            "type": access_type,
            "action": action,
            "request": request
        }

        # Send request
        self.socket.sendall((json.dumps(payload) + "\n").encode('utf-8'))

        responses = []
        buffer = ""
        while True:
            chunk = self.socket.recv(4096).decode('utf-8')
            if not chunk:
                break
            buffer += chunk
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                msg = json.loads(line)

                if msg.get("invoke_id") != invoke_id:
                    continue

                if msg["type"] == "plugin_response":
                    responses.append(msg["response"])
                elif msg["type"] == "plugin_invoke_end":
                    return responses
                elif msg["type"] == "error":
                    raise RuntimeError(msg["response"]["error"])
        return responses

# Usage
if __name__ == "__main__":
    client = TCPPluginClient("127.0.0.1", 12345)
    client.connect()
    try:
        results = client.invoke("tool", "invoke_tool", {"tool_name": "calc", "expression": "2+2"})
        print("Results:", results)
    finally:
        client.disconnect()
```