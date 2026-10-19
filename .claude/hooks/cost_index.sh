#!/bin/sh
# cost_index.pyを、入っているPythonで回す。Windowsのpython3は、入っていなくてもストアへの案内が置かれていることがある。
cd "$(git rev-parse --show-toplevel)" || exit 0
for py in python3 python; do
  if "$py" -c "" >/dev/null 2>&1; then
    exec "$py" -I .claude/hooks/cost_index.py "$@"
  fi
done
exit 0
