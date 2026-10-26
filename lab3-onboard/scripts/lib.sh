# Shared helpers for the onboarding scripts. Source this file; do not run it.
#
# Every logged step is one row in the log: epoch seconds, step name, command.
# The scorecard program in ../capstone reads the same file.

ONBOARD_LOG="${ONBOARD_LOG:-onboarding-log.csv}"

log_row() {
  # log_row STEP COMMAND
  if [ ! -f "$ONBOARD_LOG" ]; then
    echo "epoch,step,command" > "$ONBOARD_LOG"
    echo "$(date +%s),start," >> "$ONBOARD_LOG"
  fi
  echo "$(date +%s),$1,\"$2\"" >> "$ONBOARD_LOG"
}
