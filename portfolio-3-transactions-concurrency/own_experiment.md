# Own Experiment: Lock Timeout

## Question
What happens when a session waits for a row lock but is only willing to wait 2 seconds?

## Prediction (written BEFORE running it)
- What I expect Tab B to do: ...
- When I expect the error to appear (immediately, after 2 seconds, or never): ...
- What state I expect Tab B's transaction to be in afterwards: ...

## Setup
- Database: nexora_db
- Wallet used: Demo Alice (9000000001), reset to 500.00 before the run
- Setting tested: SET lock_timeout = '2s';

## Steps I ran
| Step | Tab | Command |
|---|---|---|
| 1 | A | BEGIN; then SELECT ... FOR UPDATE; |
| 2 | B | SET lock_timeout = '2s'; BEGIN; then the same SELECT ... FOR UPDATE; |
| 3 | B | ROLLBACK; then RESET lock_timeout; |
| 4 | A | ROLLBACK; |

## What I saw
- Exact error message: ...
- How long Tab B waited before the error: ...
- What Tab B's prompt looked like after the error: ...

## Comparison without lock_timeout (optional)
- What happened in Tab B: ...

## Was my prediction right?
...

## Why this matters
- What an application should do when it receives this error: ...
- How this differs from the deadlock in Experiment 4: ...
- When I would choose a lock timeout in a payments system: ...

## Evidence
- Screenshot: screenshots/11_own_lock_timeout.png
