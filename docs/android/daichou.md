# 台帳 — Android 端末

**最終更新: 2026-09-06**

## 1. 何をしたいか / ★何をしないと決めたか

- **A** 端末を Trinitas の常駐点にする（Termux + sshd + Tailscale）— ★未着手
- **B** Mac から端末を掴んで開発に使う（adb / scrcpy）— ★道具は揃った
- **C** ★iPhone から Android の LINE を遠隔操作する — ★2026-09-06 成立

### やらないと決めたこと
- **端末を root 化しない / bootloader を unlock しない**（2026-09-06 決定）
  理由: Knox の e-fuse は不可逆。Secure Folder / Samsung Pay / Health を永久に失う。本計画のどの目的にも不要。
- **Termux 本体を入れ替えない**（2026-09-06 決定）— 下記 §5 参照

## 2. 箱の台帳

### Mac
- 今の名前 `（機の名前は伏せました）` ／ ★過去の名前 `（機の名前は伏せました）`
- ★不変の同定: `~/.android/adbkey` の識別子が `（adbkey の識別子は伏せました。~/.android-lab/ledger.md を参照）`
  （ホスト名が変わっても鍵の中の名前は 2026-04-27 のまま。★これが同一の箱である証拠）
- adb 1.0.41 / 37.0.0-14910828（2026-04-27 導入）／ scrcpy 3.3.4

### 端末
- Samsung **SM-F966Q**（Galaxy Z Fold7）／ Android 16（SDK 36）／ arm64-v8a
- ビルド `BP4A.251205.006` ／ セキュリティ更新 2026-06-05
- 外画面 1080x2520 / density 420 ／ 記憶域 936G 中 906G 空き
- serial 下 4 桁 `59B1F`（全桁は非公開台帳）
- Tailscale 名 `z-fold7`（アドレスは非公開台帳）

### 承認の対応表
| Mac の鍵 | 指紋 下 4 桁 | 許可した端末 | 許可した日 | 全桁の在り処 |
|---|---|---|---|---|
| `~/.android/adbkey` | `78:95` | SM-F966Q | 2026-04-27（再確認 2026-09-06） | `~/.android-lab/ledger.md` |

## 3. 入れた物

| 何を | 版 | 出所 | 署名(dumpsys 値) | いつ | どちらの箱 |
|---|---|---|---|---|---|
| android-platform-tools | 37.0.0 | brew cask | — | 2026-04-27 17:32 | Mac |
| scrcpy | (現 3.3.4) | brew | — | 2026-04-27 17:32 | Mac |
| Termius | 7.9.0 | Play | — | 2026-04-25 | 端末 |
| Termux | googleplay.2026.06.21 | ★Google Play | `61fa5427` | 2026-07-14 | 端末 |
| ~~Termux:API~~ | 0.53.0 | GitHub版 sideload | `db86cf3c` | 2026-04-27 → ★2026-09-06 削除 | 端末 |
| ~~Termux:Boot~~ | 0.8.1 | GitHub版 sideload | `db86cf3c` | 2026-04-27 → ★2026-09-06 削除 | 端末 |
| Tailscale | 1.98.2 | Play | — | 2026-04-27 | 端末 |
| LINE | 26.14.0 | Play | — | ★2026-09-04（Android 専用の別アカウント） | 端末 |
| AnyDesk | 8.5.0 | Play | — | 2026-09-05 | 端末 |
| AnyDesk control AD1 | 1.7.4 | Play | — | 2026-09-06 | 端末 |

### 手元に残っている APK（`~/Downloads/trinitas-android/`）
```
termux.apk           81.9MB  ★破損（EOCD 無し・インストール不可）
termux-api.apk        3.9MB  F-Droid 鍵 07c3fcce
termux-boot.apk        26KB  F-Droid 鍵 07c3fcce
github-version/termux-arm64.apk 35.1MB  GitHub 鍵 db86cf3c
github-version/termux-api.apk    8.9MB  GitHub 鍵 db86cf3c   ← ★削除した 2 本の復元用
github-version/termux-boot.apk  743KB   GitHub 鍵 db86cf3c   ← 同上
```
★ 出所を揃える理由: Termux は本体と拡張が同一署名でないと**インストールが弾かれる**（公式 README 逐語）。

## 4. ★端末側で変えた設定（Mac に痕跡が残らない箇所）

| 項目 | ★元の状態 | 今の状態 | 変えた日 | 戻し方 |
|---|---|---|---|---|
| 開発者オプション | 有効 | 有効 | 2026-04-27 | — |
| USB デバッグ | 有効 | 有効 | 2026-04-27 | — |
| 無線デバッグ | `adb_wifi_enabled=0` | 0（未変更） | — | — |
| 電池最適化の除外 | tailscale/termux ★無し | ★両方 追加 | 2026-09-06 | `dumpsys deviceidle whitelist -com.tailscale.ipn` |
| 自動回転 | `accelerometer_rotation=1` | ★0（縦固定） | 2026-09-06 | `settings put system accelerometer_rotation 1` |
| 画面の向き | `user_rotation=0` | 0 | — | — |
| 給電中の画面維持 | `stay_on_while_plugged_in=15` | ★15（一度 2 にして戻した） | 2026-09-06 | — |
| AnyDesk 双方向接続 | 「接続を常に許可する」 | 同左（未変更） | 2026-09-05 頃 | — |
| AnyDesk アクセシビリティ | 有効 | 有効（未変更） | 2026-09-06 00:14 | — |
| AnyDesk 2 要素認証 | 無効 | ★無効（剛さま裁定で後回し） | — | ★2026-10-06 に再裁定 |
| AnyDesk アクセス制限 | 無効 | 無効 | — | — |

## 5. ★なぜそう選んだか

| 日 | 決めたこと | 却下した案 | 理由 |
|---|---|---|---|
| 2026-09-06 | Termux 本体は触らない | 4/27 版へ戻して署名を揃える | ★Play 版本体に起動時実行が内蔵済（`TermuxBootReceiver` を実測）。Termux:API は Play に無い（issue #29 open）。★直す対象ではなく、不要になった 2 本の掃除だった |
| 2026-09-06 | 拡張 2 本を削除 | 放置 | 3 つとも別 dataDir と実測 ⇒ 本体の `$HOME` に触れない。将来の署名衝突を除去。復元用 APK が手元に在り署名一致を実測済 |
| 2026-09-06 | LINE は AnyDesk で遠隔操作 | iPad / Mac をサブ端末に | ★剛さま: iPad も Mac も使えない。★LINE 公式表で iPhone はサブ端末になれない ⇒ 遠隔操作が唯一の道 |
| 2026-09-06 | 共有は「LINE だけ」 | 画面全体を共有 | 画面全体だと SMS のワンタイムコード・Wallet・Termius が映る（Hestia 監査） |
| 2026-09-06 | 2 要素認証は後回し | 先に有効化 | ★Hestia は反対。★剛さま裁定で越えた。★期限 2026-10-06 に再裁定 |
| 2026-09-06 | 縦画面に固定 | 自動回転のまま | iPhone の縦横比とほぼ一致（2.33:1 対 2.17:1）。横だと黒帯だらけ |

## 6. 最後の既知良好状態

**2026-09-06 15:0x — iPhone から Android の LINE を読み書きできた（剛さまが実際に確認）。**
再現手順は `tejun.md`。

## 7. 次の一手

1. ★接続の自動承認（`anydesk-gate.sh`）の ①承諾 が未検証。次に切れた時に手を出さずに確かめる
2. ★`anydesk-gate.sh` の規則④に欠陥（下記 sagyou-log 参照）。修正が要る
3. A の系統（Termux で sshd → 画面消灯で生き残るかを測る）が未着手

## 8. 秘密の在り処

**`~/.android-lab/ledger.md`（この repo の外・chmod 600）** に:
AnyDesk の 9 桁アドレス（Android 側 / iPhone 側）／ adbkey 指紋の全桁 ／ serial 全桁 ／ Tailscale の 100.x
