#!/usr/bin/env python3
"""
Get Dify plugin debugging credentials.

Usage:
    python get_debug_key.py --host https://your-dify.com --email user@example.com --password yourpassword

This script will:
1. Login to Dify console API
2. Fetch the plugin debugging key
3. Output the key for use in .env file
"""

import argparse
import base64
import sys

import httpx


def login(host: str, email: str, password: str) -> tuple[str, dict, str]:
    """Login to Dify and get access token from cookies."""
    url = f"{host.rstrip('/')}/console/api/login"

    # Password needs to be base64 encoded
    encoded_password = base64.b64encode(password.encode()).decode()

    response = httpx.post(
        url,
        json={
            "email": email,
            "password": encoded_password,
            "remember_me": True,
        },
        timeout=30,
    )

    if response.status_code != 200:
        raise Exception(f"Login failed: {response.status_code} - {response.text}")

    # Access token is in cookies, not response body
    # Cookie names may have __Host- prefix for secure cookies
    cookies = dict(response.cookies)
    access_token = cookies.get("access_token") or cookies.get("__Host-access_token")
    csrf_token = cookies.get("csrf_token") or cookies.get("__Host-csrf_token")

    if not access_token:
        raise Exception(f"No access_token in cookies. Cookies: {list(cookies.keys())}")

    return access_token, cookies, csrf_token


def get_debugging_key(host: str, cookies: dict, csrf_token: str) -> str:
    """Get plugin debugging key from Dify."""
    url = f"{host.rstrip('/')}/console/api/workspaces/current/plugin/debugging-key"

    response = httpx.get(
        url,
        cookies=cookies,
        headers={
            "X-CSRF-Token": csrf_token,
        },
        timeout=30,
    )

    if response.status_code != 200:
        raise Exception(f"Failed to get debugging key: {response.status_code} - {response.text}")

    data = response.json()
    if "key" not in data:
        raise Exception(f"Unexpected response: {data}")

    return data["key"]


def main():
    parser = argparse.ArgumentParser(
        description="Get Dify plugin debugging credentials"
    )
    parser.add_argument(
        "--host",
        required=True,
        help="Dify host URL (e.g., https://your-dify.com)",
    )
    parser.add_argument(
        "--email",
        required=True,
        help="Dify account email",
    )
    parser.add_argument(
        "--password",
        required=True,
        help="Dify account password",
    )
    parser.add_argument(
        "--output-env",
        action="store_true",
        help="Output as .env format",
    )

    args = parser.parse_args()

    try:
        # Step 1: Login
        print(f"Logging in to {args.host}...", file=sys.stderr)
        access_token, cookies, csrf_token = login(args.host, args.email, args.password)
        print("Login successful.", file=sys.stderr)

        # Step 2: Get debugging key
        print("Fetching debugging key...", file=sys.stderr)
        debug_key = get_debugging_key(args.host, cookies, csrf_token)

        # Output
        if args.output_env:
            print(f"INSTALL_METHOD=remote")
            print(f"REMOTE_INSTALL_HOST={args.host}")
            print(f"REMOTE_INSTALL_PORT=5003")
            print(f"REMOTE_INSTALL_KEY={debug_key}")
        else:
            print(f"\nDebugging Key: {debug_key}")
            print(f"\nAdd to your plugin's .env file:")
            print(f"  INSTALL_METHOD=remote")
            print(f"  REMOTE_INSTALL_HOST={args.host}")
            print(f"  REMOTE_INSTALL_PORT=5003")
            print(f"  REMOTE_INSTALL_KEY={debug_key}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
