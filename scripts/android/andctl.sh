#!/bin/bash
# Galaxy Z Fold7 操作の往復ループ（Metis の実測に基づく）
# ★座標は必ず uidump の bounds から取る。wm size(1080x2520) は嘘。実座標は 2520x1080 / rotation=1
SP="$(cd "$(dirname "$0")" && pwd)"

shot() {  # $1=出力png  ★screencap は先頭に 347B の警告文を混ぜるので PNG シグネチャ以降だけ残す
  adb exec-out screencap -p 2>/dev/null | python3 -c "
import sys
d=sys.stdin.buffer.read(); i=d.find(b'\x89PNG')
sys.exit('no PNG in output') if i<0 else open(sys.argv[1],'wb').write(d[i:])" "$1"
}

uidump() {  # ★exec-out 版は末尾に 33B のゴミが付くので </hierarchy> で打ち切る
  adb exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c "
import sys
d=sys.stdin.buffer.read().decode('utf-8','replace'); i=d.rfind('</hierarchy>')
print(d[:i+12] if i>=0 else '', end='')"
}

state() { adb shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 ResumedActivity; }
awake() { adb shell dumpsys power 2>/dev/null | tr -d '\r' | grep -m1 'mWakefulness='; }

find_node() {  # $1=xml  $2=検索語 → タップ座標を出す
  python3 - "$1" "$2" <<'PY'
import re,sys
d=open(sys.argv[1],encoding='utf-8').read(); q=sys.argv[2]
m=re.search(r'rotation="(\d)"',d)
print("rotation=", m.group(1) if m else "?")
hit=0
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    if q in s:
        b=re.search(r'bounds="\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]"',s)
        if not b: continue
        x1,y1,x2,y2=map(int,b.groups()); hit+=1
        clk='clickable="true"' in s
        txt=re.search(r'text="([^"]*)"',s); desc=re.search(r'content-desc="([^"]*)"',s)
        rid=re.search(r'resource-id="([^"]*)"',s)
        print(f'  tap {(x1+x2)//2} {(y1+y2)//2}  clickable={clk}  text={txt.group(1) if txt else ""!r}  desc={desc.group(1) if desc else ""!r}  id={rid.group(1) if rid else ""}')
print(f"hits={hit}")
PY
}

case "$1" in
  shot)  shot "${2:-$SP/now.png}"; file "${2:-$SP/now.png}" ;;
  ui)    uidump > "${2:-$SP/now.xml}"; wc -c "${2:-$SP/now.xml}" ;;
  find)  uidump > "$SP/now.xml"; find_node "$SP/now.xml" "$2" ;;
  state) awake; state ;;
  look)  awake; state; shot "$SP/now.png"; uidump > "$SP/now.xml"; echo "-> $SP/now.png / now.xml" ;;
  *) echo "usage: $0 {shot|ui|find <語>|state|look}" ;;
esac
