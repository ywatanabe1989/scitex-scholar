---
description: Per-backend setup requirements, environment variables, and availability conditions for all nine notification backends in scitex-notification.
---

# Backends

## Backend Registry

All backends live in `scitex_notification._backends`. Backend names used in `alert(backend=...)`:

| Backend | Class | Transport | Internet | Notes |
|---------|-------|-----------|----------|-------|
| `audio` | `AudioBackend` | TTS speakers | No | Requires `scitex-audio` package |
| `emacs` | `EmacsBackend` | `emacsclient` | No | Requires Emacs server running |
| `desktop` | `DesktopBackend` | `notify-send` / PowerShell | No | Linux/WSL desktop notifications |
| `matplotlib` | `MatplotlibBackend` | Visual popup window | No | Requires `matplotlib` |
| `playwright` | `PlaywrightBackend` | Browser popup | No | Requires `playwright` |
| `email` | `EmailBackend` | SMTP (smtplib) | Yes | Gmail or custom SMTP |
| `webhook` | `WebhookBackend` | HTTP POST | Yes | Slack, Discord, custom URL |
| `telegram` | `TelegramBackend` | Telegram Bot API | Yes | No SDK dependency (urllib only) |
| `twilio` | `TwilioBackend` | Twilio REST API | Yes | Phone calls and SMS; no SDK dependency |

Fallback chain (auto-selected when `backend=None`): `audio -> emacs -> matplotlib -> playwright -> email`

Telegram and twilio are **explicit-only** — not included in the fallback chain.

## audio

Requires `scitex-audio` package (`pip install scitex-audio`).

```python
from scitex_notification._backends._audio import AudioBackend

b = AudioBackend(backend="gtts", speed=1.5, rate=180)
# backend: TTS engine ("gtts", "espeak", ...)
# speed: playback speed multiplier
# rate: words-per-minute for espeak
```

`is_available()`: returns `True` if `scitex_audio` is importable and at least one TTS backend works.

## desktop

Uses `notify-send` on Linux, PowerShell `New-BurntToastNotification` on WSL.

No packages required. `is_available()` checks for `notify-send` or WSL environment.

## emacs

Uses `emacsclient --eval '(message ...)'`. No Python packages required.

`is_available()`: checks if `emacsclient` binary is on PATH and Emacs server is running.

## matplotlib

```python
from scitex_notification._backends._matplotlib import MatplotlibBackend
```

Requires `matplotlib`. Shows a blocking window that auto-closes after `timeout` seconds.

`SCITEX_NOTIFICATION_TIMEOUT_MATPLOTLIB` (default: `5.0`)

## playwright

```python
from scitex_notification._backends._playwright import PlaywrightBackend
```

Requires `playwright` (`pip install playwright && playwright install chromium`). Shows a browser popup.

`SCITEX_NOTIFICATION_TIMEOUT_PLAYWRIGHT` (default: `5.0`)

## email

Uses `smtplib` from Python stdlib — no extra packages.

Environment variables (checked in order, first non-empty wins):

| Variable | Purpose |
|----------|---------|
| `SCITEX_NOTIFICATION_EMAIL_FROM` | Sender address |
| `SCITEX_NOTIFICATION_EMAIL_TO` | Recipient address |
| `SCITEX_NOTIFICATION_EMAIL_PASSWORD` | SMTP password |
| `SCITEX_NOTIFICATION_EMAIL_SMTP_HOST` | SMTP host (default: `smtp.gmail.com`) |
| `SCITEX_NOTIFICATION_EMAIL_SMTP_PORT` | SMTP port (default: `587`) |

Backward-compatible fallbacks: `SCITEX_NOTIFY_EMAIL_*`, `SCITEX_SCHOLAR_EMAIL_*`, `SCITEX_EMAIL_*`.

`is_available()`: returns `True` only if both FROM address and PASSWORD are set.

```python
from scitex_notification._backends._email import EmailBackend

b = EmailBackend(recipient="user@example.com", sender="agent@example.com")
```

## webhook

Uses `urllib.request` — no extra packages.

```python
from scitex_notification._backends._webhook import WebhookBackend

b = WebhookBackend(url="https://hooks.slack.com/services/...")
```

Or via env: `SCITEX_NOTIFICATION_WEBHOOK_URL` (fallbacks: `SCITEX_NOTIFY_WEBHOOK_URL`, `SCITEX_UI_WEBHOOK_URL`).

Payload format supports both Slack (`text`) and Discord (`content`) simultaneously.

`is_available()`: returns `True` if URL is set.

## telegram

No SDK dependency — uses `urllib.request` only.

| Variable | Purpose |
|----------|---------|
| `SCITEX_NOTIFICATION_TELEGRAM_TOKEN` | Bot token from `@BotFather` |
| `SCITEX_NOTIFICATION_TELEGRAM_CHAT_ID` | Target chat ID |

Supports rich messages via `**kwargs`:

```python
stxn.alert(
    "Analysis done",
    backend="telegram",
    image_path="/tmp/plot.png",        # attach image
    # voice_path="/tmp/audio.ogg",     # attach voice note
    # document_path="/tmp/report.pdf", # attach document
)
```

Text messages are truncated at 4096 chars (Telegram limit).

`is_available()`: returns `True` if both `bot_token` and `chat_id` are set.

## twilio

No SDK dependency — uses `urllib.request` with Basic Auth.

| Variable | Purpose |
|----------|---------|
| `SCITEX_NOTIFICATION_TWILIO_SID` | Twilio Account SID |
| `SCITEX_NOTIFICATION_TWILIO_TOKEN` | Twilio Auth Token |
| `SCITEX_NOTIFICATION_TWILIO_FROM` | Twilio phone number (e.g., `+15550001111`) |
| `SCITEX_NOTIFICATION_TWILIO_TO` | Destination phone number |
| `SCITEX_NOTIFICATION_TWILIO_FLOW` | Studio Flow SID (optional, e.g., `FWxxx`) |

Backward-compatible fallbacks: `SCITEX_NOTIFY_TWILIO_*`.

`is_available()`: returns `True` only if all four required vars are set.

- `repeat` kwarg: call N times, 30s apart. Default from `$SCITEX_NOTIFICATION_PHONE_CALL_N_REPEAT` (default: `1`). Set to `1` if iOS Emergency Bypass is configured; `2` triggers iOS "Repeated Calls" bypass (2+ calls within 3 min).
- `flow_sid` kwarg: triggers Twilio Studio Flow instead of direct TwiML
- TwiML uses voice `"alice"`, language `"en-US"`, repeats message twice with 2s pause

```python
from scitex_notification._backends._twilio import TwilioBackend, send_sms

# Direct SMS (not via alert())
import asyncio
result = asyncio.run(send_sms("Hello", to_number="+81900000000"))
print(result.success, result.details)
```

## BaseNotifyBackend

```python
class BaseNotifyBackend(ABC):
    name: str = "base"

    @abstractmethod
    async def send(
        self,
        message: str,
        title: Optional[str] = None,
        level: NotifyLevel = NotifyLevel.INFO,
        **kwargs,
    ) -> NotifyResult: ...

    @abstractmethod
    def is_available(self) -> bool: ...
```

## NotifyResult

```python
@dataclass
class NotifyResult:
    success: bool
    backend: str
    message: str
    timestamp: str           # ISO 8601
    error: Optional[str] = None
    details: Optional[dict] = None
```

## NotifyLevel

```python
class NotifyLevel(Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"
```
