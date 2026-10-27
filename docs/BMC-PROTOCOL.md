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
checks the expected offset and CRC32 before accepting chunks; the Swift
checksum building block does not yet implement transfer, retry, or storage.

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
gates media and ICE/SDP sends on authorization, but no media-sync routing is
connected. Discovery, app UI, WebRTC, and camera control over the data channel
are still unfinished.

With protoc and the matching SwiftProtobuf 1.29.0 plugin installed, regenerate
the sources from the repository root with:

```sh
protoc --descriptor_set_in=Reference/BMCProtocol/bmc-v5.pb \
  --swift_out=FilmCamera/BMCProtocol \
  common.proto camera_control.proto settings.proto main_messages.proto
protoc --descriptor_set_in=Reference/BMCProtocol/bmc-media-sync-v1.pb \
  --swift_out=FilmCamera/BMCProtocol media_sync.proto
```
