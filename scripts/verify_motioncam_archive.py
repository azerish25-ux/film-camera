"""Independently validate the Swift-produced ZIP64 fixture using Python's ZIP reader."""
import json
import sys
import zipfile
from pathlib import Path

root = Path(sys.argv[1])
archives = [p for p in root.rglob("*") if p.is_file() and zipfile.is_zipfile(p)]
assert archives, "The simulator did not attach its CinemaDNG ZIP fixture"
results = []
for path in archives:
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        assert set(names) == {"000000.dng", "000001.dng", "000002.dng", "audio.wav"}, names
        assert archive.testzip() is None, "ZIP CRC verification failed"
        for name in names:
            payload = archive.read(name)
            assert payload[:4] == (b"RIFF" if name.endswith(".wav") else b"II*\x00"), name
        results.append({"archive": path.name, "entries": names, "crc": "passed"})
print(json.dumps(results, indent=2))
