#!/bin/bash
# Protocol Completion Reminder Hook
# Event: PostToolUse (matcher: tool_name = Read, input.file_path contains "protocol-")
# После чтения протокола напоминает: выполни ВСЕ шаги включая верификацию.
# Read-only: только возвращает JSON.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Срабатываем только на чтение протоколов
if [ "$TOOL" = "Read" ] && echo "$FILE_PATH" | grep -q "protocol-"; then
  PROTOCOL_NAME=$(basename "$FILE_PATH" .md)
  cat <<EOF
{"additionalContext": "\ud83d\udcdd \u041f\u0420\u041e\u0422\u041e\u041a\u041e\u041b \u0417\u0410\u0413\u0420\u0423\u0416\u0415\u041d: $PROTOCOL_NAME. \u041e\u0411\u042f\u0417\u0410\u0422\u0415\u041b\u042c\u041d\u041e: (1) \u0412\u044b\u043f\u043e\u043b\u043d\u0438 \u0412\u0421\u0415 \u0448\u0430\u0433\u0438 \u0430\u043b\u0433\u043e\u0440\u0438\u0442\u043c\u0430. (2) \u041f\u043e\u0441\u043b\u0435 \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u0438\u044f \u0437\u0430\u043f\u0443\u0441\u0442\u0438 /verify \u0434\u043b\u044f \u0432\u0435\u0440\u0438\u0444\u0438\u043a\u0430\u0446\u0438\u0438 \u043f\u043e \u0447\u0435\u043a\u043b\u0438\u0441\u0442\u0443 (Haiku R23). \u041d\u0415 \u043f\u0440\u043e\u043f\u0443\u0441\u043a\u0430\u0439 \u0432\u0435\u0440\u0438\u0444\u0438\u043a\u0430\u0446\u0438\u044e."}
EOF
else
  echo '{}'
fi
exit 0
