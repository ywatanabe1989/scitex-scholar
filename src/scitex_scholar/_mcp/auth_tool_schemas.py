#!/usr/bin/env python3
"""Authentication + OpenURL tool schemas (institutional SSO)."""

from __future__ import annotations

import mcp.types as types

__all__ = ["get_auth_tool_schemas"]


def get_auth_tool_schemas() -> list[types.Tool]:
    return [
        types.Tool(
            name="resolve_openurls",
            description=(
                "Turn DOIs into institution-proxied publisher URLs via an OpenURL resolver — "
                "the step that lets your university proxy decide the right paywalled-access "
                "route. Resumable across batches. Use when the user asks to 'get the "
                "institutional link for this paper', 'resolve OpenURLs', 'find the proxy URL', "
                "or is chaining this into a custom download workflow before calling "
                "`download_pdf`."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "dois": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "DOIs to resolve OpenURLs for",
                    },
                    "resolver_url": {
                        "type": "string",
                        "description": "OpenURL resolver URL (uses default if not specified)",
                    },
                    "resume": {
                        "type": "boolean",
                        "description": "Resume from previous progress",
                        "default": True,
                    },
                },
                "required": ["dois"],
            },
        ),
        types.Tool(
            name="authenticate",
            description=(
                "Launch institutional SSO login (OpenAthens / Shibboleth / EZproxy) so "
                "subsequent `download_pdf` calls can pull paywalled papers through the "
                "university's subscriptions. Opens a browser, stores the session, reuses it "
                "for hours. Use when the user asks to 'log in to the library', 'authenticate "
                "via OpenAthens', 'start institutional SSO', 'connect my university access', "
                "or before any paywalled download. Call first with `confirm=False` to see "
                "requirements, then `confirm=True` to open the browser. Requires env vars "
                "like `SCITEX_SCHOLAR_OPENATHENS_EMAIL`."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "method": {
                        "type": "string",
                        "description": "Authentication method",
                        "enum": ["openathens", "shibboleth", "ezproxy"],
                    },
                    "institution": {
                        "type": "string",
                        "description": "Institution identifier (e.g., 'unimelb')",
                    },
                    "force": {
                        "type": "boolean",
                        "description": "Force re-authentication even if session exists",
                        "default": False,
                    },
                    "confirm": {
                        "type": "boolean",
                        "description": (
                            "Set to True to proceed with login after reviewing requirements. "
                            "Default False returns requirements check without starting login."
                        ),
                        "default": False,
                    },
                },
                "required": ["method"],
            },
        ),
        types.Tool(
            name="check_auth_status",
            description=(
                "Inspect whether a valid institutional SSO session is cached — no browser, "
                "no login attempt. Use when the user asks 'am I logged in?', 'is my "
                "OpenAthens session still valid?', 'check auth', or before triggering a "
                "download to decide whether `authenticate` is needed. Pass "
                "`verify_live=True` to ping the remote for a definitive answer (slower)."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "method": {
                        "type": "string",
                        "description": "Authentication method to check",
                        "enum": ["openathens", "shibboleth", "ezproxy"],
                        "default": "openathens",
                    },
                    "verify_live": {
                        "type": "boolean",
                        "description": "Verify session with remote server (slower but more accurate)",
                        "default": False,
                    },
                },
            },
        ),
        types.Tool(
            name="logout",
            description=(
                "End the institutional SSO session and wipe cached cookies/state. Use when "
                "the user asks to 'log out', 'clear my OpenAthens session', 'switch "
                "institution / account', or is debugging auth issues and wants a clean slate "
                "before re-`authenticate`."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "method": {
                        "type": "string",
                        "description": "Authentication method to logout from",
                        "enum": ["openathens", "shibboleth", "ezproxy"],
                        "default": "openathens",
                    },
                    "clear_cache": {
                        "type": "boolean",
                        "description": "Also clear cached session files",
                        "default": True,
                    },
                },
            },
        ),
    ]


# EOF
