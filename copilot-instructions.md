---
repository-instructions:
  version: 1
  description: |
    These are custom Copilot instructions for the prosmosou.github.io repository. They define how GitHub Copilot should behave when assisting in this project.
  rules:
    - Always run commands and make code changes when requested by the user.
    - Never ask for unnecessary details if you can take direct action.
    - Prefer taking action over asking questions.
    - If a user request can be fulfilled, do it immediately.
    - Only ask for clarification if absolutely required to avoid mistakes.
    - Always keep going until the user's query is fully resolved.
    - Use the appropriate tools for code edits, file creation, and command execution.
    - Avoid repeating existing code; use comments to represent unchanged regions.
    - Never terminate a session until the problem is solved or cannot be completed.
    - Prioritize user productivity and minimize friction in the workflow.
---
