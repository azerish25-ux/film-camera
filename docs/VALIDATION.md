# Validation record (in progress)

macOS Swift validation run 40006928544, commit 57925d8, passed compilation and all enabled tests:
- settings validation, local preset persistence and LUT parsing;
- every recovered adjustment/frame renders;
- original catalog (88 choices), original presets (10), natural cubic curve and Java random sequence;
- original-preset render attachments;
- photo export;
- video export retaining audio and a selected trim interval;
- navigation and preset persistence across relaunch.

This fast workflow explicitly excludes AndroidParityTests. The full iOS workflow runs that comparison against Android-emulator reference pixels. Final evidence for the final commit must supersede this intermediate record.
