#!/bin/bash
# Pre-push hook: runs xcodebuild build+test before allowing git push.
# Blocks the push (exit 2) if tests fail.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Only intercept git push commands
if ! echo "$COMMAND" | grep -qE '^git push'; then
  exit 0
fi

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
SIMULATOR_ID="FF4633AE-B9F5-4A75-AE4D-80EE4A12C4F8"

# Run tests (build is implicit)
if xcodebuild \
  -project "$PROJECT_DIR/MorseTrainer.xcodeproj" \
  -scheme MorseTrainer \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  test -quiet > /dev/null 2>&1; then
  exit 0
else
  echo "Pre-push check: tests failed. Push blocked." >&2
  exit 2
fi
