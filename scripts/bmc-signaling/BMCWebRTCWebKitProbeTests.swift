import Foundation
import WebKit
import XCTest
@testable import FilmCamera

@MainActor private final class WebRTCProbeHandler: NSObject, WKScriptMessageHandler {
    let finished: XCTestExpectation
    var result: String?
    init(finished: XCTestExpectation) { self.finished = finished }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard result == nil else { return }
        result = message.body as? String
        finished.fulfill()
    }
}

@MainActor final class BMCWebRTCWebKitProbeTests: XCTestCase {
    func testLocalPeerDataChannel() async throws {
        let finished = expectation(description: "WebRTC data-channel response")
        let handler = WebRTCProbeHandler(finished: finished)
        let controller = WKUserContentController()
        controller.add(handler, name: "probe")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        let view = WKWebView(frame: .zero, configuration: configuration)
        defer { view.stopLoading(); controller.removeScriptMessageHandler(forName: "probe") }
        let html = """
        <!doctype html><meta charset="utf-8"><script>
        (async () => {
          let done = false;
          const finish = value => { if (!done) { done = true; window.webkit.messageHandlers.probe.postMessage(value); } };
          setTimeout(() => finish("timeout"), 15000);
          try {
            const a = new RTCPeerConnection({iceServers: []});
            const b = new RTCPeerConnection({iceServers: []});
            const toA = [], toB = [];
            const deliver = (target, pending, candidate) => {
              if (!candidate) return;
              if (target.remoteDescription) target.addIceCandidate(candidate).catch(e => finish("ice: " + e));
              else pending.push(candidate);
            };
            a.onicecandidate = event => deliver(b, toB, event.candidate);
            b.onicecandidate = event => deliver(a, toA, event.candidate);
            b.ondatachannel = event => {
              event.channel.onmessage = message => { if (message.data === "ping") event.channel.send("pong"); };
            };
            const channel = a.createDataChannel("probe");
            channel.onopen = () => channel.send("ping");
            channel.onmessage = event => { finish(event.data); a.close(); b.close(); };
            const offer = await a.createOffer();
            await a.setLocalDescription(offer);
            await b.setRemoteDescription(offer);
            for (const candidate of toB) await b.addIceCandidate(candidate);
            const answer = await b.createAnswer();
            await b.setLocalDescription(answer);
            await a.setRemoteDescription(answer);
            for (const candidate of toA) await a.addIceCandidate(candidate);
          } catch (error) { finish("error: " + error); }
        })();
        </script>
        """
        view.loadHTMLString(html, baseURL: URL(string: "https://localhost"))
        await fulfillment(of: [finished], timeout: 20)
        XCTAssertEqual(handler.result, "pong")
    }
}
