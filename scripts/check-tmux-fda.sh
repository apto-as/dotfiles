#!/opt/homebrew/bin/bash
# tmux の Full Disk Access が、今の tmux の実体に効いているかを見る。
#
# なぜ要るか。2026-09-16 に、長生きしている tmux server の中だけ ~/Downloads が
# 権限拒否になる不具合が出た。原因は、その server を起こした WezTerm が既に死んでいて、
# TCC が責任プロセスを解決できなくなっていたこと。剛さまが tmux 自体に
# Full Disk Access を与えて直したが、登録は版つきの実体パスで入っている。
#   /opt/homebrew/Cellar/tmux/3.6a/bin/tmux
# brew upgrade tmux で Cellar のパスが変われば、登録は黙って効かなくなる。
# 黙って、というのが厄介で、症状は「なぜか Downloads が読めない」としてしか出ない。
#
# 使い方: brew upgrade tmux の後に、人が叩く。常駐や cron には載せない。
#   走り手に Full Disk Access が無いと常に赤に見えるため（自己言及の罠）。

DB="/Library/Application Support/com.apple.TCC/TCC.db"
real="$(readlink -f "$(command -v tmux)" 2>/dev/null)"
gr="$(sqlite3 "$DB" \
  "SELECT client FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND client LIKE '%/tmux' AND auth_value=2;" 2>/dev/null)"

fail=0
[ -z "$real" ] && { echo "異常 tmux が見つかりません"; exit 2; }

if [ -z "$gr" ]; then
  echo "異常 tmux が Full Disk Access に登録されていません"
  fail=1
elif [ "$gr" != "$real" ]; then
  echo "異常 登録のパスと今の実体が食い違っています"
  fail=1
fi

# 実際に効いているかも見る。登録の照合だけでは、効いているとは言えないため。
if ! ls "$HOME/Downloads" >/dev/null 2>&1; then
  echo "異常 ~/Downloads が読めません。tmux の中から走らせているなら、これが症状です"
  fail=1
fi

[ "$fail" = 0 ] && echo "異常なし"
echo
echo "  今の実体   ${real:-不明}"
echo "  登録のパス ${gr:-未登録}"
echo "  Downloads  $(ls "$HOME/Downloads" >/dev/null 2>&1 && echo 読める || echo 読めない)"
echo "  直し方     システム設定 プライバシーとセキュリティ フルディスクアクセス に"
echo "             上の実体パスを追加し直す。古い版のパスは外してよい"
exit "$fail"
