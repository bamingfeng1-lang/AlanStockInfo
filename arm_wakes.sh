#!/bin/zsh
# 为行情简报定时任务提前唤醒 MacBook。
# 需以 root 运行（pmset schedule 需要 root 权限）。
# 每次运行会：清掉旧的计划唤醒 → 为今天起未来 10 个工作日，
# 在 08:59:30 / 11:59:30 / 15:29:30（各比任务提前 30 秒）排入唤醒。
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
DIR=/Users/alanba/market-brief
LOG="$DIR/logs/wake.log"

{
  echo "===== arm $(date '+%F %T') ====="
  # 仅清除由 pmset schedule 添加的计划事件（不影响系统自身的 alarm 唤醒）
  /usr/bin/pmset schedule cancelall
  for d in 0 1 2 3 4 5 6 7 8 9; do
    DOW=$(date -v+${d}d '+%u')            # 1..7 (周一..周日)
    [ "$DOW" -gt 5 ] && continue           # 跳过周末
    MDY=$(date -v+${d}d '+%m/%d/%Y')
    for T in 08:59:30 11:59:30 15:29:30; do
      /usr/bin/pmset schedule wake "$MDY $T" 2>&1
    done
  done
  echo "--- 当前计划唤醒 ---"
  /usr/bin/pmset -g sched
} >> "$LOG" 2>&1
