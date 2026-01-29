#!/bin/bash
# 完全静默执行脚本，只输出最终状态

STEP_NAME="$1"
shift

# 创建临时日志文件
TEMP_LOG=$(mktemp)

# 执行命令并捕获所有输出
"$@" > "$TEMP_LOG" 2>&1
EXIT_CODE=$?

# 只在失败时显示日志
if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ $STEP_NAME failed"
    echo "::group::Error Details"
    cat "$TEMP_LOG"
    echo "::endgroup::"
else
    echo "✅ $STEP_NAME completed"
fi

# 清理临时文件
rm -f "$TEMP_LOG"

exit $EXIT_CODE
