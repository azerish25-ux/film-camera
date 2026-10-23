"""Compatibility entry point for the exhaustive reference-matrix generator."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).parent/'android-reference/generate_cases.py'),run_name='__main__')
