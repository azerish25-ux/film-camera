# BMC remote-control protocol evidence

The Swift files in `FilmCamera/BMCProtocol` were generated from protobuf
descriptors embedded in the supplied APK. Four come from
`bmd.cam_app_control.v5`, and one comes from `bmd.cam_app_media_sync.v1`.
The descriptor set is stored in `Reference/BMCProtocol/bmc-v5.pb`. The APK's
generated Java descriptor strings were decoded as bytes and parsed as four
`FileDescriptorProto` messages: `common.proto`, `camera_control.proto`,
`settings.proto`, and `main_messages.proto`.
The descriptor set's SHA-256 is
`542dd63a8f9da034d5fa4755eac62eadfa48ae4eebb745a9c4351141a1e1b5a3`.
The separate `bmc-media-sync-v1.pb` descriptor set comes from the APK's
`bmd.cam_app_media_sync.v1` package; its SHA-256 is
`5f6a91d78088b6de2157be6168dce99b4bfe7995b12a4183dcecd9ad11144a5c`.

GitHub Actions run 40449488793 generated the files with Apple's
`protoc-gen-swift` 1.29.0 and compiled them against the matching runtime. A
subsequent run 40449831084 passed a start-recording message round-trip against a
separately descriptor-encoded binary fixture. These types describe the wire format; they
do not provide discovery, transport, authentication, remote control, or
interoperability by themselves. Field semantics and session behavior still
need to be traced and tested against a peer.
Run 40451550437 generated and compiled the media-sync types, and run
40451904803 passed a clip-chunk request wire fixture. The Android receiver
checks the expected offset and CRC32 before accepting chunks. The Swift
`BMCMediaReceiver` validates the clip ID, offset, size and checksum before
appending to a caller-opened file; run 40453798227 passed its temporary-file
and resume checks. `BMCMediaTransfer` forms range, stop and explicit retry
requests and routes matching chunks; `BMCMediaCatalog` forms list requests and
returns unrelated messages to the caller. Run 40455159590 passed fake-session,
wire-fixture, catalog and file-routing tests with a stubbed authentication
digest. A receive-loop coordinator, automatic retry scheduling, a media browser,
and real-peer interoperability remain unfinished.

`BMCControlMessages` builds the recovered controller envelopes for starting and
stopping recording. Run 40450331698 verified both encoded fixtures with the
generated Swift types. It is not connected to a session or camera UI, and does
not yet handle responses, message ID allocation, timeouts, or peer behavior.

`BMCWebSocketChannel` and `BMCSignalingAuthenticator` provide a WebSocket
adapter and the client authorization exchange, with a 15-second timeout. A
fake-peer Actions test (run 40452983221) passed ordered authorization, timeout,
unexpected-message, unauthorized-send and authorized SDP/binary cases; it substituted a fixed
digest and did not test a real WebSocket peer. The existing CryptoKit challenge
implementation is separate. The channel exposes binary frames, and the session
gates media and ICE/SDP sends on authorization. A fake-session test connects
the media request builder to that sender, but no live receive-loop coordinator
is present. Discovery, app UI, WebRTC, and camera control over the data channel
are still unfinished.

Runs 40455617389 and 40456651058 passed an iOS simulator URLSession text/binary
exchange with a local mock WebSocket server, the latter using the app's
local-network plist configuration. They did not test a BMC peer or
local-network permission on a physical device. The loopback workflow keeps
that transport check reproducible without contacting an external service.
Run 40457003174 additionally passed a local mock pairing exchange using the
real challenge calculation, followed by an authorized media-range request,
CRC-checked chunk and temporary-file write. This is not a BMC-peer test.

With protoc and the matching SwiftProtobuf 1.29.0 plugin installed, regenerate
the sources from the repository root with:

```sh
protoc --descriptor_set_in=Reference/BMCProtocol/bmc-v5.pb \
  --swift_out=FilmCamera/BMCProtocol \
  common.proto camera_control.proto settings.proto main_messages.proto
protoc --descriptor_set_in=Reference/BMCProtocol/bmc-media-sync-v1.pb \
  --swift_out=FilmCamera/BMCProtocol media_sync.proto
```
