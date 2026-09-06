# Android 端末を開発と遠隔操作に使う

**最終更新: 2026-09-06 / 状態: 生きている**

この 3 本が正典です。TMWS 記憶と kanban は索引に過ぎません。食い違ったらここが正しい。

| ファイル | 中身 |
|---|---|
| `daichou.md` | 箱の台帳・入れた物・端末側で変えた設定・なぜそう選んだか |
| `tejun.md` | ★剛さまが私（Clotho）抜きで再現できる手順 |
| `sagyou-log.md` | 操作の記録（変えた物／元の状態／戻し方／直後の実測） |
| `../../scripts/android/` | 道具（`andctl.sh` 画面操作 ／ `anydesk-gate.sh` 接続の自動承認 ／ `look.py`） |

## ★ なぜこの記録が在るか

2026-04-27 に始めた同じ作業が、**4 ヶ月で完全に失われた**。
TMWS 記憶 0 件・kanban 0 件・会話記録 0 件・shell 履歴 0 件。
復元できたのは **ディスクの痕跡だけ**（brew の時刻／鍵の生成時刻／APK の並び／端末の firstInstallTime）。

> ★ **消えた原因は記憶の減衰ではなく、落ちない場所に置かなかったこと。**
> 記憶は保持期間で落ちる。git は落ちない。**落ちない側に置く。**

## ★ 秘密は ここに書かない

AnyDesk の 9 桁アドレス／adbkey の指紋の全桁／端末の serial 全桁／Tailscale の 100.x アドレスは
**`~/.android-lab/ledger.md`（この repo の外・chmod 600）**。ここには「在り処」だけを書く。

## ★ この記録も失われた時の掘り起こし方

```
brew の formula ディレクトリの時刻       いつ道具を入れたか
~/.android/adbkey の生成時刻と識別子      ★起動した証拠（入れただけでは作られない）
~/Downloads の並び順                     何を入れようとしたか
端末: adb shell dumpsys package <pkg> | grep firstInstallTime
fish history                             ★無ければ「Claude Code の Bash から動かしていた」の証拠
```
★ 2026-09-06 に、この 5 つで 4 ヶ月前を再構成できた。
