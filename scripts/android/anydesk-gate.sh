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

# ★どの端末を掴むか。★無線を優先する（USB を抜いても続くように）
SERIAL=""
pick_serial(){
  local w u
  w="$(command adb devices 2>/dev/null | tr -d '\r' | awk '/^[0-9.]+:[0-9]+[[:space:]]+device$/{print $1; exit}')"
  u="$(command adb devices 2>/dev/null | tr -d '\r' | awk '/[[:space:]]device$/{print $1}' | grep -v ':' | head -1)"
  local new="${w:-$u}"
  if [ "$new" != "$SERIAL" ]; then
    SERIAL="$new"
    [ -n "$SERIAL" ] && say "掴む端末: $(printf '%s' "$SERIAL" | sed 's/:[0-9]*$/:<ポート>/')" || say "✗ 掴める端末が無い"
  fi
}
A(){ command adb ${SERIAL:+-s "$SERIAL"} "$@"; }
alive(){ [ -n "$SERIAL" ] && command adb devices 2>/dev/null | tr -d '\r' | grep -q "^$SERIAL[[:space:]]*device$"; }

# ★ロック解除 — パターンは repo に書かない。~/.android-lab/pattern（chmod 600）から読む
PATTERN_FILE="${ANDROID_PATTERN_FILE:-$HOME/.android-lab/pattern}"
locked(){ A shell dumpsys window 2>/dev/null | tr -d '\r' | grep -q 'mDreamingLockscreen=true'; }
# ★AnyDesk の操作権限（AD1 のアクセシビリティ）が生きているか。落ちていたら戻す。
#   これが無いと AnyDesk は「見るだけ」になる（公式: Android は既定で遠隔入力を許さない）。
#   2026-09-07 に実際に落ちていて、剛さまが操作できなくなった。原因は未特定。
A11Y_SVC="com.anydesk.adcontrol.ad1/com.anydesk.adcontrol.AccService"
ensure_a11y(){
  A shell dumpsys accessibility 2>/dev/null | tr -d '\r' \
    | grep -q "Bound services:{Service\[label=AnyDesk" && return 0
  say "★AnyDesk の操作権限が落ちていた ⇒ 戻す"
  A shell settings put secure enabled_accessibility_services "$A11Y_SVC" >/dev/null 2>&1
  A shell settings put secure accessibility_enabled 1 >/dev/null 2>&1
  sleep 2
  if A shell dumpsys accessibility 2>/dev/null | tr -d '\r' | grep -q "Bound services:{Service\[label=AnyDesk"; then
    say "★操作権限を戻した（束縛を確認）"
  else
    say "✗ 操作権限を戻せなかった"
  fi
}

# ★接続中か ＝ 画面を投影しているか（画面に何が出ているかに依存しない）
projecting(){
  A shell dumpsys media_projection 2>/dev/null | tr -d '\r' \
    | awk '/Media Projection:/{f=1;next} f{print;exit}' | grep -q 'null' && return 1
  return 0
}
unlock(){
  [ -s "$PATTERN_FILE" ] || { say "✗ 解除できない — パターン未設定"; return 1; }
  A shell input -d 0 keyevent KEYCODE_WAKEUP >/dev/null 2>&1; sleep 2
  # ★Samsung の「誤操作を防止」が手前に出ていたら、まず それを払う
  if ui | grep -q 'unintentional'; then
    say "誤操作防止の画面 ⇒ 先に払う"
    A shell input -d 0 swipe 540 1760 540 700 300 >/dev/null 2>&1; sleep 2
  fi
  A shell input -d 0 swipe 540 1900 540 800 250 >/dev/null 2>&1
  # ★格子は遷移中に取れないことがある ⇒ 見つかるまで数回 待つ
  local CMD UIX
  UIX=""
  for _i in 1 2 3 4 5 6; do
    sleep 1.2
    UIX="$(ui)"
    printf '%s' "$UIX" | grep -q 'lockPatternView' && break
    UIX=""
  done
  [ -n "$UIX" ] || { say "✗ 解除できない — 解除画面の格子が出ない（6 回 待った）"; return 1; }
  CMD="$(printf '%s' "$UIX" | python3 -c "
import re,sys,os
d=sys.stdin.read()
m=re.search(r'<node[^>]*lockPatternView[^>]*>',d)
if not m: sys.exit(0)
b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',m.group(0))
if not b: sys.exit(0)
x1,y1,x2,y2=map(int,b.groups())
cw=(x2-x1)/3; ch=(y2-y1)/3
seq=[int(t) for t in open(os.environ['PF']).read().split()]
P=lambda n: (int(x1+cw*(((n-1)%3)+0.5)), int(y1+ch*(((n-1)//3)+0.5)))
pts=[P(n) for n in seq]
c=[f'input motionevent DOWN {pts[0][0]} {pts[0][1]}']
for a,z in zip(pts,pts[1:]):
    c.append(f'input motionevent MOVE {(a[0]+z[0])//2} {(a[1]+z[1])//2}')
    c.append(f'input motionevent MOVE {z[0]} {z[1]}')
c.append(f'input motionevent UP {pts[-1][0]} {pts[-1][1]}')
print('; '.join(c))")"
  [ -n "$CMD" ] || { say "✗ 解除できない — 解除画面の格子が見つからない"; return 1; }
  A shell "$CMD" >/dev/null 2>&1; sleep 3
  if locked; then say "✗ 解除 失敗（パターンが合わない可能性）"; return 1; fi
  say "★ロックを解除した"; return 0
}
export PF="$PATTERN_FILE"

ui(){ A exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c "
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

# ★試験用の入口: 解除だけを 1 回 試して終わる（--test-unlock）
if [ "${1:-}" = "--test-unlock" ]; then
  pick_serial                       # ★先に端末を選ぶ。選ぶ前に測ると
  if [ -z "$SERIAL" ]; then         #   adb が「どっちの端末?」で失敗し、
    say "✗ 掴める端末が無い"        #   ★見えないことを「ロックされていない」と読んでしまう
    exit 1
  fi
  if locked; then unlock; RC=$?; else say "既に解除されています"; RC=0; fi
  exit $RC
fi

pick_serial
if [ "${AUTO_ACCEPT:-0}" = "1" ]; then
  say "見張り役 開始（★承認も押す ／ 許可: …${ALLOW_ID: -4} の 1 台のみ）"
else
  say "見張り役 開始（★承認は押さない ／ 画面共有の確認・LINE の選択・ロック解除・終了後のロック のみ）"
fi
LAST=""
WAS_LOCKED=0
while true; do
  alive || pick_serial
  if [ -z "$SERIAL" ]; then sleep 3; continue; fi
  # ★ロック中でも、AnyDesk が前に出ていれば「着信が来ている」合図とみなして解除する
  if locked; then
    R="$(A shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 ResumedActivity)"
    case "$R" in
      # ★AnyDesk 本体だけでなく、Android 側の画面共有の確認・アプリ選択も引き金にする
      #   （無人アクセスだと承認ダイアログは出ず、いきなり systemui の
      #     MediaProjectionPermissionActivity がロック画面の裏に出る。2026-09-07 実測）
      *anydesk*|*ediaprojection*|*ediaProjection*)
        say "ロック中に AnyDesk / 画面共有の確認が動いている ⇒ 解除を試みる"
        if unlock; then WAS_LOCKED=1; fi ;;
    esac
    sleep 1.5; continue
  fi
  X="$(ui)"
  if [ -n "$X" ]; then

    # ① 着信リクエスト
    #  ★既定では押しません。AnyDesk の無人アクセス（パスワード方式）を設定した後は、
    #    私が先に押すと ★パスワードを入れる前に対話セッションが始まってしまい、
    #    「以前のセッション」＝見るだけのプロファイルで繋がってしまう（2026-09-07 実測）。
    #  押させたい時だけ AUTO_ACCEPT=1 を付けて起動する。
    if [ "${AUTO_ACCEPT:-0}" = "1" ] && printf '%s' "$X" | grep -q 'dialog_accept_title_text'; then
      MSG="$(printf '%s' "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
m=re.search(r'<node[^>]*dialog_accept_msg[^>]*>',d)
t=re.search(r'text=\"([^\"]*)\"',m.group(0)) if m else None
print(t.group(1) if t else '')")"
      if printf '%s' "$MSG" | grep -qF "$ALLOW_ID"; then
        # ★承諾の前に、権限プロファイルを「フルアクセス」にする
        #   （「以前のセッション」だと 見るだけ＝操作できない状態を引き継ぐ）
        PB="$(printf '%s' "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    m=re.search(r'text=\"([^\"]*)\"',s)
    if m and 'フルアクセス' in m.group(1):
        b=re.search(r'bounds=\"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]\"',s)
        if b:
            x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break")"
        if [ -n "$PB" ]; then
          A shell input -d 0 tap $PB; sleep 1; say "権限プロファイルを フルアクセス に"
          X="$(ui)"
        else
          PL="$(printf '%s' "$X" | python3 -c "
import re,sys
d=sys.stdin.read()
out=[]
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    if 'permission_profile' in s or 'dialog_accept_profiles' in s:
        m=re.search(r'text=\"([^\"]*)\"',s)
        if m and m.group(1): out.append(m.group(1))
print(' | '.join(out) if out else '(プロファイルの項目が 1 つも無い)')")"
          say "△ フルアクセスが見当たらない ⇒ 実際に在った項目: $PL"
        fi
        B="$(printf '%s' "$X" | center 'resource-id="android:id/button1"')"
        [ -z "$B" ] && B="$(printf '%s' "$X" | center 'button1')"
        if [ -n "$B" ]; then A shell input -d 0 tap $B; say "★承諾（許可した相手）"; sleep 2; fi
      else
        say "✗ 承認しません — 許可していない相手からの要求"
        sleep 5
      fi
      continue
    fi

    if [ "${AUTO_ACCEPT:-0}" != "1" ] && printf '%s' "$X" | grep -q 'dialog_accept_title_text'; then
      [ "$LAST" != "waiting" ] && say "承認ダイアログが出ています（★私は押しません。iPhone 側でパスワードを入れてください）" && LAST="waiting"
      sleep 1.5; continue
    fi

    # ② 画面共有の確認 → 次へ
    if printf '%s' "$X" | grep -q 'screen_share_dialog_title'; then
      B="$(printf '%s' "$X" | center 'resource-id="android:id/button1"')"
      if [ -n "$B" ]; then A shell input -d 0 tap $B; say "画面共有 → 次へ"; sleep 2; fi
      continue
    fi

    # ③ 共有するアプリの選択 → LINE
    if printf '%s' "$X" | grep -q '共有するアプリを選択'; then
      B="$(printf '%s' "$X" | center 'content-desc="LINE"')"
      if [ -n "$B" ]; then
        A shell input -d 0 tap $B; say "共有対象に LINE を選択"; sleep 3
        A shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1
        say "LINE を前へ"
      else
        # ★LINE が一覧に無い（force-stop 後など）⇒ 先に起動してからやり直す
        say "★LINE が一覧に無い ⇒ 先に起動してやり直す"
        A shell input -d 0 keyevent KEYCODE_BACK; sleep 2
        A shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1; sleep 5
        A shell am start -n com.anydesk.anydeskandroid/.gui.activity.HubActivity >/dev/null 2>&1; sleep 3
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
          A shell input -d 0 tap $CB; sleep 3
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

    # ④ ★接続中か ＝ 投影しているか で判定する
    #    （旧版の欠陥: 画面に AnyDesk のカードが見えるかで判定していたが、
    #      共有中は LINE を前に出すのでカードは見えず、★一度も検知できていなかった）
    if projecting; then
      if [ "$LAST" != "connected" ]; then
        say "★接続中を検出（投影あり）"; LAST="connected"
        ensure_a11y   # ★繋がった時に、操作権限が生きているか確かめる
      fi
      R="$(A shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 ResumedActivity)"
      case "$R" in
        *naver.line*|*anydesk*|*systemui*) ;;
        *) A shell am start -n jp.naver.line.android/.activity.SplashActivity >/dev/null 2>&1
           say "LINE を前へ戻した" ;;
      esac
    else
      if [ "$LAST" = "connected" ]; then
        say "接続が切れた（待ち受けへ戻る）"; LAST=""
        # ★接続が終わったら 必ずロックする（誰が解除したかに関わらず）
        A shell input -d 0 keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 3
        if locked; then say "★ロックした（接続終了）"; else say "✗ ロックできなかった"; fi
        WAS_LOCKED=0
      fi
    fi
  fi
  sleep 1.5
done
