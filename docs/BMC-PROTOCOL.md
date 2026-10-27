# BMC remote-control protocol evidence

The four Swift files in `FilmCamera/BMCProtocol` were generated from the
`bmd.cam_app_control.v5` protobuf descriptors embedded in the supplied APK.
The descriptor set is stored in `Reference/BMCProtocol/bmc-v5.pb`. The APK's
generated Java descriptor strings were decoded as bytes and parsed as four
`FileDescriptorProto` messages: `common.proto`, `camera_control.proto`,
`settings.proto`, and `main_messages.proto`.
The descriptor set's SHA-256 is
`542dd63a8f9da034d5fa4755eac62eadfa48ae4eebb745a9c4351141a1e1b5a3`.

GitHub Actions run 40449488793 generated the files with Apple's
`protoc-gen-swift` 1.29.0 and compiled them against the matching runtime. A
subsequent run 40449831084 passed a start-recording message round-trip against a
separately descriptor-encoded binary fixture. These types describe the wire format; they
do not provide discovery, transport, authentication, remote control, or
interoperability by themselves. Field semantics and session behavior still
need to be traced and tested against a peer.

`BMCControlMessages` builds the recovered controller envelopes for starting and
stopping recording. Run 40450331698 verified both encoded fixtures with the
generated Swift types. It is not connected to a session or camera UI, and does
not yet handle responses, message ID allocation, timeouts, or peer behavior.

With protoc and the matching SwiftProtobuf 1.29.0 plugin installed, regenerate
the sources from the repository root with:

```sh
protoc --descriptor_set_in=Reference/BMCProtocol/bmc-v5.pb \
  --swift_out=FilmCamera/BMCProtocol \
  common.proto camera_control.proto settings.proto main_messages.proto
```
