# Host-manage OMLX for local AI

`eta` will run OMLX as a host-managed Local Model Runtime rather than as a Docker Compose service stack. This intentionally deviates from the normal Home Server service pattern because native macOS execution is expected to provide better Apple Silicon acceleration and runtime compatibility, while containerized services such as Open WebUI and Paperless-AI can consume OMLX through a standard API boundary.
