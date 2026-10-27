import base64, hashlib, socket, struct

def read_exact(stream, count):
    value = bytearray()
    while len(value) < count:
        chunk = stream.read(count - len(value))
        if not chunk:
            raise EOFError("WebSocket closed")
        value.extend(chunk)
    return bytes(value)

def receive_frame(stream, conn):
    while True:
        first, second = read_exact(stream, 2)
        opcode = first & 15
        length = second & 127
        if length == 126:
            length = struct.unpack(">H", read_exact(stream, 2))[0]
        elif length == 127:
            length = struct.unpack(">Q", read_exact(stream, 8))[0]
        if length > 4096 or not second & 128:
            raise ValueError("Unexpected client frame")
        mask = read_exact(stream, 4)
        data = read_exact(stream, length)
        payload = bytes(value ^ mask[i % 4] for i, value in enumerate(data))
        if opcode == 9:
            conn.sendall(bytes([0x8a, len(payload)]) + payload)
            continue
        return opcode, payload

with socket.socket() as listener:
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 18765))
    listener.listen(1)
    listener.settimeout(1200)
    print("ready", flush=True)
    conn, _ = listener.accept()
    with conn, conn.makefile("rb") as stream:
        conn.settimeout(30)
        request = stream.readline()
        if not request.startswith(b"GET "):
            raise ValueError("Expected WebSocket request")
        headers = {}
        while True:
            line = stream.readline()
            if line in (b"\r\n", b"\n", b""):
                break
            key, value = line.decode("ascii").split(":", 1)
            headers[key.lower()] = value.strip()
        key = headers["sec-websocket-key"]
        accept = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode("ascii")).digest()).decode("ascii")
        conn.sendall(("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " + accept + "\r\n\r\n").encode("ascii"))
        assert receive_frame(stream, conn) == (1, b"hello")
        conn.sendall(b"\x81\x05world")
        assert receive_frame(stream, conn) == (2, b"\x01\x02\x03")
        conn.sendall(b"\x82\x03\x04\x05\x06")
        print("frames verified", flush=True)
