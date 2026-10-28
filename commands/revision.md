---
description: 逐条回复审稿意见并生成 response letter
---

Respond to the reviewer comments for:

$ARGUMENTS

Load `rebuttal-response` (add `nature-response` for Nature-family voice).
For every comment produce a row:

| # | Reviewer comment (quoted) | Response | Change made | Location |

Rules: never claim a change you did not make; never argue tone with tone;
concede what is true, push back with evidence where the reviewer is wrong;
mark unresolved items explicitly. Output a ready-to-send response letter plus
an internal action list.
