# Host-manage the Personal Assistant Agent on eta

`eta` will run the Personal Assistant Agent as a host-managed macOS service rather than as a Docker Compose Service Stack. This intentionally follows the same exception pattern as OMLX: native macOS integration matters more than container uniformity, because the assistant needs Things local app automation while still presenting Telegram as its primary interaction surface.
