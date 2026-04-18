---
description: scitex-notification Python API — alert(), call(), sms() function signatures, return types, and available_backends().
---

# Python API

## alert()

```python
def alert(
    message: str,
    title: Optional[str] = None,
    backend: Optional[Union[str, list[str]]] = None,
    level: str = "info",
    fallback: bool = True,
    **kwargs,
) -> bool:
```

- Returns `True` if any backend succeeded, `False` if all failed
- `level`: `"info"` | `"warning"` | `"error"` | `"critical"`
- `backend=None`: uses `SCITEX_NOTIFICATION_DEFAULT_BACKEND` (default `"audio"`) with fallback chain
- `backend="email"`: uses only email (no fallback unless `fallback=True`)
- `backend=["audio", "email"]`: tries all listed backends

**Fallback order** (when `backend=None` and `fallback=True`):
1. `audio` — TTS via scitex-audio (fast, non-blocking)
2. `emacs` — `emacsclient` minibuffer message
3. `matplotlib` — visual popup window
4. `playwright` — browser popup
5. `email` — SMTP (slowest, most reliable)

```python
import scitex_notification as stxn

stxn.alert("Done!")                                     # auto-fallback
stxn.alert("Error", level="error", backend="email")    # explicit backend
stxn.alert("Critical", backend=["audio", "email"], fallback=False)
stxn.alert("Low-priority", backend="desktop", fallback=True)
```

## alert_async()

```python
async def alert_async(
    message: str,
    title: Optional[str] = None,
    backend: Optional[Union[str, list[str]]] = None,
    level: str = "info",
    fallback: bool = True,
    **kwargs,
) -> bool:
```

Same semantics as `alert()`, but async-native. Use inside `async def` contexts.

```python
await stxn.alert_async("Epoch complete", level="info")
```

## call()

```python
def call(
    message: str,
    title: Optional[str] = None,
    level: str = "info",
    to_number: Optional[str] = None,
    **kwargs,
) -> bool:
```

Convenience wrapper for `alert(backend="twilio", fallback=False)`. Makes a real phone call via Twilio REST API (no SDK required).

- `to_number`: overrides `SCITEX_NOTIFICATION_TWILIO_TO`
- `repeat` kwarg: repeat call N times, 30s apart. Default from `$SCITEX_NOTIFICATION_PHONE_CALL_N_REPEAT` (default: `1`). Set to `1` if iOS Emergency Bypass is configured; set to `2` to trigger iOS "Repeated Calls" bypass.
- `flow_sid` kwarg: use Twilio Studio Flow instead of direct TwiML

```python
stxn.call("Server is down!")
stxn.call("Wake up!", repeat=2)                   # calls twice, 30s apart
stxn.call("Alert!", to_number="+61400000000")     # override destination
```

## call_async()

```python
async def call_async(
    message: str,
    title: Optional[str] = None,
    level: str = "info",
    to_number: Optional[str] = None,
    **kwargs,
) -> bool:
```

## sms()

```python
def sms(
    message: str,
    title: Optional[str] = None,
    to_number: Optional[str] = None,
    **kwargs,
) -> bool:
```

Sends an SMS via Twilio REST API. `title` is prepended to message if provided.

```python
stxn.sms("Build finished!")
stxn.sms("Alert!", title="CI/CD", to_number="+61400000000")
```

## sms_async()

```python
async def sms_async(
    message: str,
    title: Optional[str] = None,
    to_number: Optional[str] = None,
    **kwargs,
) -> bool:
```

## available_backends()

```python
def available_backends() -> list[str]:
```

Returns list of currently working backends (checks `is_available()` on each).

```python
print(stxn.available_backends())
# ['audio', 'emacs', 'email']
```

## Module-level Constants

```python
stxn.DEFAULT_FALLBACK_ORDER
# ['audio', 'emacs', 'matplotlib', 'playwright', 'email']

stxn.__version__
# '0.1.6'
```

## __all__

```python
__all__ = [
    "alert",
    "alert_async",
    "available_backends",
    "call",
    "call_async",
    "sms",
    "sms_async",
    "__version__",
]
```
