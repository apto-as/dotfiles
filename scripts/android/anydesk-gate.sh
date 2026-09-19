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
say(){ echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# ★二重起動を止める。2026-09-17 設置、2026-09-18 に作り直し。
# 二重になると hunt_wifi が独立に 2 本 回って探す間隔が実質 半分になり、
# adb connect と disconnect が互いを打ち消す。
#
# 最初は pgrep で同じ名前のプロセスを数えたが、二度 誤作動した（どちらも実測）。
#   1 緩い型 'bash .*anydesk-gate.sh' は、起こす側の shell にも当たった。
#     nohup bash .../anydesk-gate.sh & と打った親の command line に同じ名前が入るため。
#   2 型を締めても、pgrep をコマンド置換の中で走らせていたので、置換のために fork された
#     自分自身の子（同じ command line・違う pid）を「別の 1 本」と数えた。$$ では除けない。
# どちらも「自分を他人と見間違える」形だった。数える相手が自分だと分からない道具は使わない。
# 錠 file だけで判定する。作るのは atomic（noclobber）で、生死は kill -0 で見る。
GATE_LOCK="${ANYDESK_GATE_LOCK:-$HOME/.android-lab/gate.lock}"
if ! (set -o noclobber; echo $$ > "${GATE_LOCK}") 2>/dev/null; then
  _gate_old="$(cat "${GATE_LOCK}" 2>/dev/null)"
  # ★生きているかだけでなく、それが見張り役かを見る。2026-09-18 に気づいた穴。
  #   強制終了や異常終了で trap が走らないと、目印が古い pid のまま残る。OS は pid を
  #   使い回すので、無関係なプロセスがその番号を持つと kill -0 が通り、見張り役は
  #   永久に起動を拒み続ける。黙って。生死の軸と、本人かの軸は別。
  #   ここは 1 つの pid を確かめるだけなので、名前で数える時のような取り違えは起きない。
  if [ -n "${_gate_old}" ] && kill -0 "${_gate_old}" 2>/dev/null \
     && ps -o command= -p "${_gate_old}" 2>/dev/null | grep -q 'anydesk-gate\.sh'; then
    say "二重起動を止めました。目印を持っているのは pid ${_gate_old} です"
    exit 1
  fi
  say "前回の錠が残っていました（pid ${_gate_old:-不明} は既に居ません）。錠を取り直します"
  rm -f "${GATE_LOCK}"
  echo $$ > "${GATE_LOCK}"
fi
# ★合図で止められた時は、後始末をしてから必ず終わる。2026-09-18 に踏んだ穴。
#   前は EXIT INT TERM をまとめて 1 つの trap にしていたので、TERM を受けると
#   目印を消すだけで走り続けた。止めたつもりの側が生き残り、目印が空いた隙に
#   もう 1 本 起動して、二重を防ぐはずの仕掛けが 二重を作る側に回った。
#   後始末は EXIT だけに置き、合図は exit を呼んで EXIT を通す。
trap 'rm -f "${GATE_LOCK}"' EXIT
trap 'exit 143' TERM
trap 'exit 130' INT


# ★どの端末を掴むか。★無線を優先する（USB を抜いても続くように）
SERIAL=""
pick_serial(){
  local w u
  w="$(command adb devices 2>/dev/null | tr -d '\r' | awk '/^[0-9.]+:[0-9]+[[:space:]]+device$/{print $1; exit}')"
  u="$(command adb devices 2>/dev/null | tr -d '\r' | awk '/[[:space:]]device$/{print $1}' | grep -v ':' | head -1)"
  local new="${w:-$u}"
  if [ "$new" != "$SERIAL" ]; then
    # ★採る相手が変わった時だけ同定を照合する。2026-09-18 に気づいた穴。
    #   同定の照合を hunt_wifi にだけ置いていたので、adb に既に繋がっている相手を
    #   ここで拾う道は素通りだった。手で adb connect した相手も、他人が繋いだ相手も同じ。
    #   新しく足した道だけ守って、元から在った道を守っていなかった。
    if [ -n "$new" ]; then
      _pk_pin="$(cat "$HOME/.android-lab/device-serial" 2>/dev/null | tr -d '\r\n')"
      if [ -n "${_pk_pin}" ]; then
        _pk_got="$(command adb -s "$new" shell getprop ro.serialno 2>/dev/null | tr -d '\r\n')"
        if [ "${_pk_got}" != "${_pk_pin}" ]; then
          say "✗ 掴もうとした端末が控えと違うので採りません（模様は打ち込んでいない）"
          command adb disconnect "$new" >/dev/null 2>&1
          SERIAL=""
          return 0
        fi
      fi
    fi
    SERIAL="$new"
    [ -n "$SERIAL" ] && say "掴む端末: $(printf '%s' "$SERIAL" | sed 's/:[0-9]*$/:<ポート>/')" || say "✗ 掴める端末が無い"
  fi
}
A(){ command adb ${SERIAL:+-s "$SERIAL"} "$@"; }
alive(){ [ -n "$SERIAL" ] && command adb devices 2>/dev/null | tr -d '\r' | grep -q "^$SERIAL[[:space:]]*device$"; }

# 無線の口は、無線デバッグを入れ直すたびに変わる。adb は古い口へ繋ぎ直そうとするだけで、
# 新しい口は探さない（2026-09-10 11:18 に口が消え、9/12 まで誰も繋ぎ直さなかった）。
# 掴める端末が無い間は、台帳のアドレスで adb の口を探して繋ぎに行く。
# 端末を起こし続けないよう、探す間隔は 1 分から倍々に延ばし 8 分で止める。繋がったら 1 分に戻す。
FIND_PORT="$(cd "$(dirname "$0")" && pwd)/find-adb-port.py"
HUNT_NEXT=0
HUNT_GAP=60
# 口が見つからない時は、端末が家の網に居るかも見て、状態が変わった時だけ 1 行残す。
# 2026-09-14 12:37 に切れた時、「持ち出し中」か「家に居て無線デバッグが OFF」かを記録から言えなかった。
# 判定は ping だけ（3 回のうち 1 回でも応答すれば「居る」）。寝ている端末は応答しないことがあるので、
# 「見えない」は「ping に応答しない」の意味で読む。アドレスは台帳から読み、記録には書かない。
NET_STATE=""
lan_addr(){
  if [ -n "${ANDROID_LAN_ADDR:-}" ]; then printf '%s' "$ANDROID_LAN_ADDR"; return; fi
  grep -E "端末の Wi-Fi アドレス" ~/.android-lab/ledger.md 2>/dev/null | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1
}
phone_on_lan(){   # 0 = 居る ／ 1 = 見えない ／ 2 = 台帳にアドレスが無い
  local ip; ip="$(lan_addr)"
  [ -n "$ip" ] || return 2
  ping -c 3 -W 1000 -t 5 "$ip" >/dev/null 2>&1 && return 0
  return 1
}
note_lan(){
  local st rc
  phone_on_lan; rc=$?
  case "$rc" in 0) st="home" ;; 2) st="noaddr" ;; *) st="away" ;; esac
  [ "$st" = "$NET_STATE" ] && return
  NET_STATE="$st"
  case "$st" in
    home)   say "端末は家の網に居るが、無線の口が無い（無線デバッグが OFF。端末で ON にすれば自動で繋ぎ直す）" ;;
    away)   say "端末が家の網に見えない（ping に応答なし。持ち出し中か、Wi-Fi が切れている）" ;;
    noaddr) say "✗ 台帳に端末のアドレスが無いので、網に居るかを判定できない" ;;
  esac
}
# 試験用の入口: 網に居るかを 1 回だけ判定して終わる（--test-lan）。ANDROID_LAN_ADDR で相手を差し替えられる
if [ "${1:-}" = "--test-lan" ]; then
  phone_on_lan; rc=$?
  case "$rc" in 0) echo "居る" ;; 2) echo "アドレス無し" ;; *) echo "見えない" ;; esac
  exit 0
fi
hunt_wifi(){
  local now target
  now=$(date +%s)
  [ "$now" -ge "$HUNT_NEXT" ] || return 1
  [ -f "$FIND_PORT" ] || return 1
  target="$(python3 "$FIND_PORT" 2>/dev/null)"
  if [ -n "$target" ]; then
    # 同じアドレスの古い口（offline）を先に外す。外さないと adb が古い口へ繋ぎ直し続ける
    command adb devices 2>/dev/null | tr -d '\r' \
      | awk -v h="${target%:*}:" 'index($1,h)==1 && $2!="device"{print $1}' \
      | while read -r old; do command adb disconnect "$old" >/dev/null 2>&1; done
    if command adb connect "$target" 2>/dev/null | grep -qE '^(connected|already connected)'; then
      # ★繋いだ相手が本当にあの端末かを確かめる。2026-09-17 に mDNS で探す道を足したので、
      #   同じ網の誰かが偽の名乗りを出すと、ここへ偽物のアドレスが来る余地ができた。
      #   見張り役は繋いだ相手にロック解除の模様を打ち込むので、偽物に繋ぐと模様が渡る。
      #   探す道具の側でも名乗りの識別子を照合しているが、こちらは繋いだ後の最終確認。
      GATE_PIN="$(cat "$HOME/.android-lab/device-serial" 2>/dev/null | tr -d '\r\n')"
      if [ -n "${GATE_PIN}" ]; then
        GATE_GOT="$(command adb -s "$target" shell getprop ro.serialno 2>/dev/null | tr -d '\r\n')"
        if [ "${GATE_GOT}" != "${GATE_PIN}" ]; then
          command adb disconnect "$target" >/dev/null 2>&1
          say "✗ 繋いだ相手が控えの端末と違ったので切り離した（模様は打ち込んでいない）"
          HUNT_NEXT=$((now + HUNT_GAP))
          [ "$HUNT_GAP" -lt 480 ] && HUNT_GAP=$((HUNT_GAP * 2))
          return 1
        fi
      fi
      say "無線の口を見つけて繋ぎ直した"
      HUNT_GAP=60; HUNT_NEXT=0; NET_STATE=""
      pick_serial
      return 0
    fi
    say "✗ 無線の口は見つかったが繋げなかった（端末側でこの Mac の許可が外れた可能性）"
  else
    note_lan
  fi
  HUNT_NEXT=$((now + HUNT_GAP))
  [ "$HUNT_GAP" -lt 480 ] && HUNT_GAP=$((HUNT_GAP * 2))
  return 1
}

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
  [ -z "$SERIAL" ] && hunt_wifi     #   （無線の口が変わっていたら探して繋ぐ）
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
  if [ -z "$SERIAL" ]; then hunt_wifi || sleep 3; continue; fi
  # ★ロック中に「着信が来ている」合図が出ていれば解除する
  if locked; then
    R="$(A shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 ResumedActivity)"
    # 合図は Android 側の画面共有の確認（無人アクセスだと承認ダイアログは出ず、いきなり systemui の
    # MediaProjectionPermissionActivity がロック画面の裏に出る。2026-09-07 実測）。
    # AnyDesk 本体が前に居るだけでは合図にしない。2026-09-12 02:13 に、前に残っていた AnyDesk の
    # 最初の画面（MainActivity）に反応して、着信が無いのにロックを外した。承認ダイアログを押す
    # AUTO_ACCEPT=1 の時だけ、AnyDesk 本体も合図に含める（承認ダイアログは AnyDesk の画面に出るため）。
    TRIGGER=""
    case "$R" in
      *ediaprojection*|*ediaProjection*) TRIGGER="画面共有の確認" ;;
      *anydesk*) [ "${AUTO_ACCEPT:-0}" = "1" ] && TRIGGER="AnyDesk" ;;
    esac
    if [ -n "$TRIGGER" ]; then
      say "ロック中に ${TRIGGER} が動いている ⇒ 解除を試みる"
      if unlock; then WAS_LOCKED=1; UNLOCKED_AT=$(date +%s); fi
    fi
    sleep 1.5; continue
  fi
  # 見張り役が外したロックは、画面共有が始まらないまま 90 秒 経ったらかけ直す。
  # 2026-09-12 02:13 に、やり直しが失敗した後、ロックが外れたまま端末が置かれていた。
  if [ "$WAS_LOCKED" = "1" ] && [ "$LAST" != "connected" ] && [ $(( $(date +%s) - ${UNLOCKED_AT:-0} )) -ge 90 ] && ! projecting; then
    A shell input -d 0 keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1
    A shell input -d 0 keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 3
    if locked; then say "✗ 解除したが 90 秒 画面共有が始まらなかった ⇒ ロックし直した"; else say "✗ 解除したまま接続が成り立たず、ロックもできなかった"; fi
    WAS_LOCKED=0
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
           # 何が LINE を押しのけたかを残す（同じ相手は 1 回だけ）。2026-09-12 02:40 に
           # 4 秒おきに 12 回 引き戻したが、何が前に出ていたかが記録に無く、原因を言えなかった。
           WHO="$(printf '%s' "$R" | grep -o '[A-Za-z0-9_.]*/[A-Za-z0-9_.$]*' | head -1)"
           if [ "$WHO" != "${LAST_DISPLACER:-}" ]; then
             say "LINE を前へ戻した（前に出ていた画面: ${WHO:-不明}）"; LAST_DISPLACER="$WHO"
           else
             say "LINE を前へ戻した（同上）"
           fi ;;
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
