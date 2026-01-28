#!/usr/bin/env python3
"""
Install Dify plugins via API.

Workflow mirrors the Dify web UI:
1. Upload package
2. Check if plugin already installed
3. Uninstall old version if exists
4. Install new version

Usage:
    python scripts/install_plugin.py dist/*.difypkg
"""

import argparse
import base64
import json
import sys
from pathlib import Path

import httpx

CREDENTIAL_FILE = ".credential"


def load_credentials() -> dict:
    """Load credentials from .credential file."""
    cred_path = Path(__file__).parent.parent / CREDENTIAL_FILE
    if not cred_path.exists():
        raise Exception(f"Credential file not found: {cred_path}")

    with open(cred_path) as f:
        return json.load(f)


def login(host: str, email: str, password: str) -> tuple[dict, str]:
    """Login to Dify and get cookies."""
    url = f"{host.rstrip('/')}/console/api/login"
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

    cookies = dict(response.cookies)
    csrf_token = cookies.get("csrf_token") or cookies.get("__Host-csrf_token")

    if not csrf_token:
        raise Exception(f"No csrf_token in cookies. Cookies: {list(cookies.keys())}")

    return cookies, csrf_token


def upload_plugin(host: str, cookies: dict, csrf_token: str, pkg_path: Path) -> dict:
    """Upload plugin package to Dify."""
    url = f"{host.rstrip('/')}/console/api/workspaces/current/plugin/upload/pkg"

    with open(pkg_path, "rb") as f:
        files = {"pkg": (pkg_path.name, f, "application/octet-stream")}
        response = httpx.post(
            url,
            cookies=cookies,
            headers={"X-CSRF-Token": csrf_token},
            files=files,
            timeout=60,
        )

    if response.status_code != 200:
        raise Exception(f"Upload failed: {response.status_code} - {response.text}")

    return response.json()


def list_installed_plugins(host: str, cookies: dict, csrf_token: str, plugin_ids: list[str]) -> dict:
    """Check which plugins are already installed."""
    url = f"{host.rstrip('/')}/console/api/workspaces/current/plugin/list/installations/ids"

    response = httpx.post(
        url,
        cookies=cookies,
        headers={
            "X-CSRF-Token": csrf_token,
            "Content-Type": "application/json",
        },
        json={"plugin_ids": plugin_ids},
        timeout=30,
    )

    if response.status_code != 200:
        raise Exception(f"List installations failed: {response.status_code} - {response.text}")

    return response.json()


def uninstall_plugin(host: str, cookies: dict, csrf_token: str, installation_id: str) -> dict:
    """Uninstall an installed plugin."""
    url = f"{host.rstrip('/')}/console/api/workspaces/current/plugin/uninstall"

    response = httpx.post(
        url,
        cookies=cookies,
        headers={
            "X-CSRF-Token": csrf_token,
            "Content-Type": "application/json",
        },
        json={"plugin_installation_id": installation_id},
        timeout=60,
    )

    if response.status_code != 200:
        raise Exception(f"Uninstall failed: {response.status_code} - {response.text}")

    return response.json()


def install_plugin(host: str, cookies: dict, csrf_token: str, plugin_unique_identifier: str) -> dict:
    """Install uploaded plugin."""
    url = f"{host.rstrip('/')}/console/api/workspaces/current/plugin/install/pkg"

    response = httpx.post(
        url,
        cookies=cookies,
        headers={
            "X-CSRF-Token": csrf_token,
            "Content-Type": "application/json",
        },
        json={"plugin_unique_identifiers": [plugin_unique_identifier]},
        timeout=60,
    )

    if response.status_code != 200:
        raise Exception(f"Install failed: {response.status_code} - {response.text}")

    return response.json()


def extract_plugin_name(unique_identifier: str) -> str:
    """Extract plugin name from unique identifier.

    Example: petrus/mercury_tools:0.2.6@hash -> petrus/mercury_tools
    """
    return unique_identifier.split(":")[0]


def main():
    parser = argparse.ArgumentParser(description="Install Dify plugins via API")
    parser.add_argument("packages", nargs="+", type=Path, help="Plugin packages to install")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    args = parser.parse_args()

    try:
        # Load credentials
        creds = load_credentials()
        host = creds["host"]
        email = creds["email"]
        password = creds["password"]

        # Login
        print(f"Logging in to {host}...", file=sys.stderr)
        cookies, csrf_token = login(host, email, password)
        print("Login successful.", file=sys.stderr)

        # Install each package
        for pkg_path in args.packages:
            if not pkg_path.exists():
                print(f"Package not found: {pkg_path}", file=sys.stderr)
                continue

            print(f"\nInstalling {pkg_path.name}...", file=sys.stderr)

            # Step 1: Upload
            print("  Uploading...", file=sys.stderr)
            upload_result = upload_plugin(host, cookies, csrf_token, pkg_path)
            plugin_id = upload_result.get("unique_identifier") or upload_result.get("plugin_unique_identifier")

            if args.verbose:
                print(f"  Upload response: {json.dumps(upload_result, indent=2)}", file=sys.stderr)

            if not plugin_id:
                print(f"  Upload response: {json.dumps(upload_result, indent=2)}", file=sys.stderr)
                raise Exception("No unique_identifier in upload response")

            print(f"  Uploaded: {plugin_id}", file=sys.stderr)

            # Step 2: Check if already installed
            plugin_name = extract_plugin_name(plugin_id)
            print(f"  Checking installations for {plugin_name}...", file=sys.stderr)

            installations = list_installed_plugins(host, cookies, csrf_token, [plugin_name])

            if args.verbose:
                print(f"  Installations response: {json.dumps(installations, indent=2)}", file=sys.stderr)

            installed_list = installations.get("plugins") or installations.get("installations") or installations.get("data") or []

            # Step 3: Uninstall old version if exists
            for installed in installed_list:
                installation_id = installed.get("id") or installed.get("installation_id")
                if installation_id:
                    print(f"  Uninstalling old version (id: {installation_id})...", file=sys.stderr)
                    uninstall_result = uninstall_plugin(host, cookies, csrf_token, installation_id)
                    if args.verbose:
                        print(f"  Uninstall response: {json.dumps(uninstall_result, indent=2)}", file=sys.stderr)
                    print("  Old version uninstalled.", file=sys.stderr)

            # Step 4: Install new version
            print("  Installing new version...", file=sys.stderr)
            install_result = install_plugin(host, cookies, csrf_token, plugin_id)

            if args.verbose:
                print(f"  Install response: {json.dumps(install_result, indent=2)}", file=sys.stderr)

            print("  ✅ Installed successfully", file=sys.stderr)

        print("\n✅ All plugins installed!", file=sys.stderr)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
