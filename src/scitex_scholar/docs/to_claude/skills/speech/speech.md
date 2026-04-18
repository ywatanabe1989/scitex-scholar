## Speak Feedback Rules

### Backgrounds
I have vulnerable eyes so auditory feedback is highly valuable to me.

### Requests
Work on tasks autonomously.
Provide audio feedback via the MCP tool `scitex - audio_speak` or `scitex - audio_speak_relay` (`scitex-notification`)
Use `notification_call` for make a phone call
Display the feedback in readable format of text as well as audio feedback.


### Rules

#### Be concise
Transcription must be short, concise, and information-dense. No extra words, no long sentences, no storytelling.

#### No Signature
Do not add signature unless explicitly requested.

#### TTS Backend
Use `luxtts` with `x1.5` speed, num_threads=8
~~Use `elevenlabs` with `x1.2` speed~~ -> When Elevenlabs available
~~Use `gtts` with `x1.5` speed~~

#### Repeat Speaking the same transcription
When asked to speak consecutively, keep repeating your feedback until user respond.
I may be working for other tasks or sleeping. 

#### Speak Counter and Escalation with Phone Call + SMS
0. PHONE_CALL_THRESHOLD is 7
1. Prepare "spoke counter"
2. Increment counter when all the condition below met.
   - 2.1 When no actual action conducted (like file edition and test run)
   - 2.2 When user did not respond other than `/speak` again
3. Reset "spoke counter" as 0
4. When speak counter reaches PHONE_CALL_THRESHOLD, the maximum threshold:
5. It will be highly likely I am sleeping intentionally to advance projects 24/7.
6. Make a phone call to me to wake me up UNTIL I will response to you.
7. Do never hesitate to make a phone call to me! This is our strategy.
8. Include progress report as message
9. Leave message with creating speech recording tools when possible.
10. **ALWAYS send SMS together with phone call** — user may not hear voice but will see SMS
11. My call number is +61-461-522-907
12. Phone: `scitex notification call` or MCP `notification_call`
13. SMS: MCP `notification_sms` (Twilio, to: +61-461-522-907)
14. SMS should include: what happened, what action is needed from user

#### Physical Action Escalation (NAS reboot, etc.)
When a situation requires physical user intervention (e.g., NAS hard reboot):
1. Attempt all remote fixes first (SSH, Docker restart, etc.)
2. If remote fix impossible → escalate immediately
3. Send **both** phone call AND SMS simultaneously
4. SMS content: "[SCITEX ALERT] {problem}. Action needed: {what user must do physically}"
5. Continue calling every 5 minutes until user responds
6. After user confirms action taken → verify system recovery

##### Proactive, Responsive Projects Lead
Do not say these words:
- "Standing by. Ready for your next task"
  - Find what you contribute to the project and move to action.
- "Please try XXX"
  - Consider whether you can do it by yourself.
  - When user input is NECESSARY, escalate it. (e.g., sudo privilege)
- "Problem found but this is not related to my changes. This is a pre-existing problem"
  - Keep your current work first
  - However, memorize the problem; order is depend on you but cover all problems in the end
  - Consider what you can do to improve projects you assigned and those around of them.

##### Autonomous Git Handling
- For git handling, I follow your recommendations.
- Do not ask me confirmation.
- Continue your work with git handling on your decisions
- Do not perform destructive actions without user confirmation. 
  - Ensure we can recover to any timepoint
  - To achieve this, frequent and logical chunks of commits needed

#### Visual Confirmation for GUI App Development
Do not decide "completed" until visual confirmation passed.
Use the /playwright-cli skill
- Check console logs (but do not trust them completely)
  - The behaviour on the browser is what we focus on
- Visit a page with browser
- Take screenshots
- Confirm what you want to claim is verified.

#### Auto Compact
When context reaches maximum, please /compact context automatically when you feel it's logically best time

### Formats for auditory feedback

#### Progress Report - Next
```
Progress - Next: I will do XXX now.
```

#### Progress Report - Completion
```
Progress - Completion: I have done XXX.
```

#### Progress Report - Bug
```
Progress - Bug: : I found XXX in the codebase. I'm proceeding with fixing this.
```

#### Progress Report - Completion
```
Progress - Completion: I have done XXX. Next, I will move on working XXX.
```

#### Question - Choices:
```
Question - Choices: 1. XXX. 2. YYY. I'm proceeding with the option 1, which I believe the best.
```

#### Question - Open:
```
Question - Open: Could you clarify XXX?
```

#### Telegram Message = User Response
When a Telegram message arrives from the user, it counts as a user response. Always reset the speak counter to 0. This is true regardless of the message content — even a simple emoji or short reply resets the counter.

Telegram incoming is unreliable (see orchestrator/delegation.md § Orochi MCP Conflict). Terminal input is the guaranteed reliable channel for user responses.
