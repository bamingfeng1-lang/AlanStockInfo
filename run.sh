#!/bin/zsh
# 行情简报生成 + 发送
# 用法: run.sh morning | noon | afternoon
set -u

# cron 环境 PATH 极简，显式补全 node/claude/python 所在目录
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.npm-global/bin:$PATH"

DIR="$HOME/market-brief"
LOG="$DIR/logs/$(date +%Y-%m-%d)_$1.log"
CLAUDE="$HOME/.npm-global/bin/claude"
DATE="$(date '+%Y-%m-%d %A')"

exec >>"$LOG" 2>&1
echo "===== $(date '+%F %T') start slot=$1 ====="

case "$1" in
  morning)
    PROMPT_FILE="$DIR/prompt_morning.txt"
    SUBJECT="【行情简报·早盘前】$(date '+%m-%d')"
    PROMPT="$(sed "s/__DATE__/$DATE/g" "$PROMPT_FILE")"
    ;;
  noon)
    PROMPT_FILE="$DIR/prompt_intraday.txt"
    SUBJECT="【行情简报·午间】$(date '+%m-%d')"
    PROMPT="$(sed -e "s/__DATE__/$DATE/g" -e "s/__SLOT__/午间/g" "$PROMPT_FILE")"
    ;;
  afternoon)
    PROMPT_FILE="$DIR/prompt_intraday.txt"
    SUBJECT="【行情简报·收盘】$(date '+%m-%d')"
    PROMPT="$(sed -e "s/__DATE__/$DATE/g" -e "s/__SLOT__/下午收盘/g" "$PROMPT_FILE")"
    ;;
  *)
    echo "usage: run.sh morning|noon|afternoon"; exit 2 ;;
esac

# 调用 claude 无人值守生成简报（允许联网工具）
# caffeinate -i: 生成期间阻止空闲休眠，避免中途睡眠打断
OUT="$(caffeinate -i "$CLAUDE" -p "$PROMPT" \
        --allowedTools "WebSearch,WebFetch" \
        --permission-mode acceptEdits 2>>"$LOG")"

if [ -z "$OUT" ]; then
  echo "ERROR: claude 输出为空，跳过发送"; exit 1
fi

STATUS_LINE="$(printf '%s\n' "$OUT" | head -1)"
echo "status: $STATUS_LINE"

if printf '%s' "$STATUS_LINE" | grep -qi "SKIP"; then
  echo "非交易日/跳过，不发送邮件。"
  exit 0
fi

# 去掉首行 STATUS 行，其余为 HTML 正文
BODY="$(printf '%s\n' "$OUT" | tail -n +2)"

printf '%s' "$BODY" | python3 "$DIR/send_email.py" "$SUBJECT"
echo "===== $(date '+%F %T') done ====="
