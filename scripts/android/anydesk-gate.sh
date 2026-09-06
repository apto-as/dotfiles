#!/bin/bash
# AnyDesk の着信を、許可した 1 台だけ 自動承認する
# ★許可する相手は repo に書かない。~/.android-lab/allow-id（chmod 600）から読む
set -u
ALLOW_ID="${ANYDESK_ALLOW_ID:-$(cat ~/.android-lab/allow-id 2>/dev/null | tr -d '\n')}"
if [ -z "$ALLOW_ID" ]; then
  echo "★許可する相手が未設定です。~/.android-lab/allow-id に AnyDesk アドレスを書いてください。" >&2
  exit 1
fi
LOG="${ANYDESK_GATE_LOG:-$HOME/.android-lab/gate.log}"
mkdir -p "$(dirname "$LOG")"
say(){ echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

ui(){ adb exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c "
import sys
d=sys.stdin.buffer.read().decode('utf-8','replace'); i=d.rfind('</hierarchy>')
sys.stdout.write(d[:i+12] if i>=0 else '')"; }

# UI から resource-id を含むノードの中心座標を出す
center(){ python3 -c "
import re,sys
d=sys.stdin.read(); key=sys.argv[1]
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    if key in s:
        b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',s)
        if b:
            x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break" "$1"; }

say "見張り役 開始（許可: …${ALLOW_ID: -4} の 1 台のみ）"
LAST=""
while true; do
  X="$(ui)"
  if [ -n "$X" ]; then

    # ① 着信リクエスト — ★許可した相手のときだけ承諾する
    if printf '%s' "$X" | grep -q 'dialog_accept_title_text'; then
      MSG="$(printf '%s' "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
m=re.search(r'<node[^>]*dialog_accept_msg[^>]*>',d)
t=re.search(r'text=\"([^\"]*)\"',m.group(0)) if m else None
print(t.group(1) if t else '')")"
      if printf '%s' "$MSG" | grep -qF "$ALLOW_ID"; then
        B="$(printf '%s' "$X" | center 'resource-id="android:id/button1"')"
        [ -z "$B" ] && B="$(printf '%s' "$X" | center 'button1')"
        if [ -n "$B" ]; then adb shell input -d 0 tap $B; say "★承諾（許可した相手）"; sleep 2; fi
      else
        say "✗ 承認しません — 許可していない相手からの要求"
        sleep 5
      fi
      continue
    fi

    # ② 画面共有の確認 → 次へ
    if printf '%s' "$X" | grep -q 'screen_share_dialog_title'; then
      B="$(printf '%s' "$X" | center 'resource-id="android:id/button1"')"
      if [ -n "$B" ]; then adb shell input -d 0 tap $B; say "画面共有 → 次へ"; sleep 2; fi
      continue
    fi

    # ③ 共有するアプリの選択 → LINE
    if printf '%s' "$X" | grep -q '共有するアプリを選択'; then
      B="$(printf '%s' "$X" | center 'content-desc="LINE"')"
      if [ -n "$B" ]; then
        adb shell input -d 0 tap $B; say "共有対象に LINE を選択"; sleep 3
        adb shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1
        say "LINE を前へ"
      else
        # ★LINE が一覧に無い（force-stop 後など）⇒ 先に起動してからやり直す
        say "★LINE が一覧に無い ⇒ 先に起動してやり直す"
        adb shell input -d 0 keyevent KEYCODE_BACK; sleep 2
        adb shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1; sleep 5
        adb shell am start -n com.anydesk.anydeskandroid/.gui.activity.HubActivity >/dev/null 2>&1; sleep 3
        # 接続カードの操作アイコン列の 4 番目（画面キャプチャの再開）を、実測の枠から計算する
        Y="$(ui)"
        CB="$(printf '%s' "$Y" | python3 -c "
import re,sys
d=sys.stdin.read()
m=re.search(r'<node[^>]*disconnect_incoming_card_action_container[^>]*>',d)
if m:
    b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',m.group(0))
    if b:
        x1,y1,x2,y2=map(int,b.groups())
        print(x1+439,(y1+y2)//2)")"
        if [ -n "$CB" ]; then
          adb shell input -d 0 tap $CB; sleep 3
          if printf '%s' "$(ui)" | grep -q 'screen_share_dialog_title'; then
            say "★やり直し成功（共有の確認が再び出た）"
          else
            say "✗ やり直し失敗 — 画面キャプチャの再開ボタンに当たらなかった"
          fi
        else
          say "✗ やり直し失敗 — 接続カードが見つからない（接続が切れた可能性）"
        fi
      fi
      continue
    fi

    # ④ ★接続中のときだけ LINE を前へ戻す
    #    （旧版の欠陥: AnyDesk は接続していなくても常時 foreground なので、
    #      その条件だと接続していない間も LINE を引き戻し続けていた）
    if printf '%s' "$X" | grep -q 'disconnect_incoming_card'; then
      [ "$LAST" != "connected" ] && say "接続中を検出" && LAST="connected"
      R="$(adb shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 ResumedActivity)"
      case "$R" in
        *naver.line*|*anydesk*|*systemui*) ;;
        *) adb shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1
           say "LINE を前へ戻した" ;;
      esac
    else
      [ "$LAST" = "connected" ] && say "接続が切れた（待ち受けへ戻る）" && LAST=""
    fi
  fi
  sleep 1.5
done
