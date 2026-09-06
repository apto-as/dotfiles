#!/bin/bash
# 剛さまの iPhone からの AnyDesk 接続だけを自動承認する門番
# ★許可するのは この 1 台だけ。他の ID が来たら 承認せず 記録だけする
# ★許可する相手の AnyDesk アドレス。repo には書かない。
# ~/.android-lab/allow-id （chmod 600）から読む。無ければ ANYDESK_ALLOW_ID 環境変数。
ALLOW_ID="${ANYDESK_ALLOW_ID:-$(cat ~/.android-lab/allow-id 2>/dev/null)}"
if [ -z "$ALLOW_ID" ]; then
  echo "★許可する相手が未設定です。~/.android-lab/allow-id に AnyDesk アドレスを書いてください。" >&2
  exit 1
fi
SP="$(cd "$(dirname "$0")" && pwd)"
LOG="$SP/gatekeeper.log"
say(){ echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }

uidump(){ adb exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c "
import sys
d=sys.stdin.buffer.read().decode('utf-8','replace'); i=d.rfind('</hierarchy>')
print(d[:i+12] if i>=0 else '', end='')"; }

fg(){ adb shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 -o 'ActivityRecord{[^ ]* [^ ]* \([^ ]*\)' | awk '{print $3}'; }

say "門番 開始（許可 ID: 末尾 336 のみ）"
while true; do
  F=$(adb shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 'ResumedActivity')
  case "$F" in
    *anydesk*|*systemui*|*permissioncontroller*|*android/*)
      X=$(uidump)
      # ① 着信リクエスト
      if echo "$X" | grep -q 'dialog_accept_title_text'; then
        MSG=$(echo "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
m=re.search(r'resource-id=\"[^\"]*dialog_accept_msg\"[^>]*',d)
t=re.search(r'text=\"([^\"]*)\"',m.group(0)) if m else None
print(t.group(1) if t else '')")
        if [ -n "$MSG" ]; then
          if echo "$MSG" | grep -qF "$ALLOW_ID"; then
            B=$(echo "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    if 'button1' in s:
        b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',s)
        x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break")
            [ -n "$B" ] && adb shell input -d 0 tap $B && say "★承諾: 許可した ID からの接続"
          else
            say "✗ 拒否せず放置: 許可していない相手からの要求（承認していません）"
          fi
        fi
      fi
      # ② 画面共有の確認 → 次へ
      if echo "$X" | grep -q 'screen_share_dialog_title'; then
        B=$(echo "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    if 'button1' in s:
        b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',s)
        x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break")
        [ -n "$B" ] && adb shell input -d 0 tap $B && say "画面共有 → 次へ" && sleep 2
      fi
      # ③ 共有するアプリの選択 → LINE
      X2=$(uidump)
      if echo "$X2" | grep -q '共有するアプリを選択'; then
        B=$(echo "$X2" | python3 -c "
import re,sys
d=sys.stdin.read()
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    if 'content-desc=\"LINE\"' in s and 'clickable=\"true\"' in s:
        b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',s)
        x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break")
        if [ -n "$B" ]; then adb shell input -d 0 tap $B; say "共有対象に LINE を選択"; sleep 2
          adb shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1; say "LINE を前へ"
        fi
      fi
      ;;
  esac
  # ④ 繋がっている間、LINE が前から外れたら戻す
  if adb shell dumpsys activity services com.anydesk.anydeskandroid 2>/dev/null | tr -d '\r' | grep -q 'isForeground=true'; then
    R=$(adb shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 'ResumedActivity')
    case "$R" in
      *naver.line*|*anydesk*) ;;
      *) adb shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1; say "LINE を前へ戻した" ;;
    esac
  fi
  sleep 3
done
