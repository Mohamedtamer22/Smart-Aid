# WebSocket

The local STOMP endpoint is `ws://localhost:8080/ws`; for Android emulator it is `ws://10.0.2.2:8080/ws`. The Flutter transport attaches the access token to STOMP `CONNECT` headers, then subscribes to `/topic/incidents/{incidentId}`.

The backend emits an incident DTO after each permitted lifecycle transition. The incident reporter, an EMS/Admin coordinator, or the volunteer assigned through `emergency_responses` may subscribe to that incident. A client must reload REST state after reconnecting; WebSocket messages are notifications, not the durable source of truth. The simple local broker has no persistence or guaranteed delivery. It is suitable only for the native single-machine development phase.
