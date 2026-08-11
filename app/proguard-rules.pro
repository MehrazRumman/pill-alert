# App-specific R8 rules. AndroidX, Room, CameraX, ML Kit, and Compose publish
# their required consumer rules, so no broad keep rules are needed here.
# Keeping this file intentionally narrow preserves release shrinking and
# obfuscation while providing a stable place for future SDK-specific rules.
