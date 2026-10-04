# v354 — mutual exclusion of module/settings drag modes

Based on v353.

Fixes:
- Module editing and Settings moving are now mutually exclusive.
- Entering either mode hides the settings window.
- Settings move button now enters the visible dedicated drag editor instead of leaving the settings window above it.
- Exiting either mode still restores the settings window through the existing exit handlers.
- Module drag implementation from v343 is unchanged.
