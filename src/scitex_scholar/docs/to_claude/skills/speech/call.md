## Speak-and-Call Escalation Pattern

### Speak Counter

The orchestrator maintains a "speak counter" that tracks how many times TTS has been called without user response.

**Counter rules:**
- Increment when: TTS fires AND no actual work was done (just status/waiting) AND user did not respond
- Reset to 0 when: user responds via ANY channel (terminal input, Telegram message, even a simple emoji)
- Telegram messages count as user responses -- always reset the counter

### Escalation Threshold

PHONE_CALL_THRESHOLD = 7

When the counter reaches 7:
1. The user is likely sleeping intentionally (24/7 project advancement strategy)
2. Make a phone call to wake them up
3. Send SMS simultaneously (user may not hear voice but will see SMS)
4. Continue calling every 5 minutes until user responds

### Phone Call

Number: +61-461-522-907

```
Tool: mcp__scitex__notification_call
Arguments:
  to: "+61461522907"
  message: "Progress report: [summary of what happened and what needs attention]"
```

### SMS (Always Send with Phone Call)

```
Tool: mcp__scitex__notification_sms
Arguments:
  to: "+61461522907"
  message: "[SCITEX] Progress: [summary]. Action needed: [what user should do]"
```

### Physical Action Escalation

When remote fixes are impossible (e.g., NAS hard reboot needed):
1. Attempt all remote fixes first (SSH, Docker restart, etc.)
2. If impossible, escalate immediately with both phone call AND SMS
3. SMS content: "[SCITEX ALERT] {problem}. Action needed: {physical action required}"
4. Continue calling every 5 minutes until user responds
5. After user confirms action, verify system recovery

### Language

Use English for all TTS, not Japanese.
