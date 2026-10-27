import base64, hashlib, json, socket, struct

def read_exact(stream, count):
    value = bytearray()
    while len(value) < count:
        chunk = stream.read(count - len(value))
        if not chunk:
            raise EOFError("WebSocket closed")
        value.extend(chunk)
    return bytes(value)

def send_frame(conn, opcode, payload):
    length = len(payload)
    header = bytes([0x80 | opcode])
    if length < 126:
        header += bytes([length])
    elif length <= 65535:
        header += bytes([126]) + struct.pack(">H", length)
    else:
        header += bytes([127]) + struct.pack(">Q", length)
    conn.sendall(header + payload)

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
            send_frame(conn, 10, payload)
            continue
        return opcode, payload

def send_json(conn, value):
    send_frame(conn, 1, json.dumps(value, separators=(",", ":")).encode())

with socket.socket() as listener:
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 18766))
    listener.listen(1)
    listener.settimeout(1200)
    print("ready", flush=True)
    conn, _ = listener.accept()
    with conn, conn.makefile("rb") as stream:
        conn.settimeout(30)
        if not stream.readline().startswith(b"GET "):
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
        opcode, payload = receive_frame(stream, conn)
        hello = json.loads(payload)
        assert opcode == 1 and hello["type"] == "hello_request" and hello["data"]["nonce"] == "01" * 32
        challenge = bytes(range(64))
        info = {"uuid":"00000000-0000-0000-0000-000000000001","model_name":"phone","device_name":"Camera","slate_name":"A","proto_major":5,"proto_minor":0}
        send_json(conn, {"type":"hello_response","data":{"nonce":challenge.hex(),"info":info,"status":"ready"}})
        opcode, payload = receive_frame(stream, conn)
        request = json.loads(payload)
        inner = hashlib.sha256(b"test" + bytes.fromhex("0e7b97a67bd5d0ed")).digest()
        digest = hashlib.sha256(challenge + inner + bytes.fromhex("55813b6755c037b1")).hexdigest()
        assert opcode == 1 and request["type"] == "conn_request" and request["data"]["password"] == digest
        send_json(conn, {"type":"conn_response","data":{"status":"authorized"}})
        opcode, payload = receive_frame(stream, conn)
        assert opcode == 2 and payload == bytes.fromhex("0a0722050a01411804")
        send_frame(conn, 2, bytes.fromhex("0a11320f0a01411a044441544120d7bd98db09"))
        print("handshake and media frames verified", flush=True)
