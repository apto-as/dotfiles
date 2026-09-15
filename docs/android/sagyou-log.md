# Android 作業ログ 2026-09-06

## 操作 1: Tailscale / Termux を電池の除外リストへ
### 変えるもの: deviceidle whitelist（電池最適化の除外）
### 元の状態（実測）
```
whitelist に tailscale/termux: 無し（grep 0 件）
standby bucket  com.tailscale.ipn=45  com.termux=45  （45=RESTRICTED）
                com.anydesk.anydeskandroid=5  jp.naver.line.android=5
```
### 戻し方（先に書く）
```
adb shell dumpsys deviceidle whitelist -com.tailscale.ipn
adb shell dumpsys deviceidle whitelist -com.termux
```

## 操作 2: 不活性な Termux 拡張 2 本を削除
### 変えるもの: com.termux.api / com.termux.boot をアンインストール
### 元の状態（実測）
```
com.termux.api  0.53.0  uid 10357  dataDir=/data/user/0/com.termux.api   署名 db86cf3c
com.termux.boot 0.8.1   uid 10357  dataDir=/data/user/0/com.termux.boot  署名 db86cf3c
com.termux      Play版  uid 10352  dataDir=/data/user/0/com.termux       署名 61fa5427
★3 つとも別 dataDir ⇒ 削除は com.termux の $HOME に触れない（Artemis 指定の確認・実測済）
```
### 戻し方（先に書く・★署名一致を実測で検証済の現物が手元にある）
```
adb install ~/Downloads/trinitas-android/github-version/termux-api.apk
adb install ~/Downloads/trinitas-android/github-version/termux-boot.apk
（両方 証明書 SHA-256 b6da0148…ee5e1 ＝ dumpsys 値 db86cf3c。端末の現物と同一鍵）
```

## 操作 3: AnyDesk 設定の閲覧（読み取りのみ・変更 0）
★無人アクセス群の全項目を列挙した結果、★「無人アクセスのパスワード」項目は存在しない。
  仕組みは token（アクセスデータ）方式: 一度 対話的に承認 → 相手が保存 → 以後 承認なし。
  現在値: （AnyDesk の認証設定の現在値は伏せました。~/.android-lab/ledger.md を参照）
  双方向接続=「接続を常に許可する」

## 操作 4: 剛さまの iPhone からの接続を、私が代理承認（2026-09-06 14:3x）
  剛さま「出先で Android の承認を押せない。そっちで操作できない？」
  ① 着信リクエスト (★アドレスは ~/.android-lab/ledger.md) → ★承諾 を代理で押した
  ② 画面共有の確認 → ★「1 個のアプリを共有」を選び、対象に ★LINE を指定
     （★画面全体ではない。ワンタイムコード・Wallet・Termius を映さないため）
  ③ LINE を前面に出した（アプリ共有なので前面でないと映らない）
  ④ stay_on_while_plugged_in を usb に（★共有が画面消灯で切れないように）
     戻し方: adb shell svc power stayon false
  ★LINE の画面内容は読み取りに入ったが、記録にも報告にも一切残していない

## 操作 5: 画面を縦向きに固定（剛さまのご依頼・2026-09-06 14:5x）
### 元の状態（実測）
```
accelerometer_rotation = 1  （自動回転 ON）
user_rotation          = 0
実際の回転             = 1（横向き）
```
### 戻し方（先に書く）
```
adb shell settings put system accelerometer_rotation 1
adb shell settings put system user_rotation 0
```

## 操作 6: 見張り役を停止（2026-09-06 15:0x・剛さまが接続を閉じたため）
★見つけた欠陥: 規則④「LINE が前から外れたら戻す」の条件が
  『AnyDesk の常駐サービスが foreground』だったが、★AnyDesk は接続していなくても
  常時 foreground（常駐通知）である。⇒ ★接続していない間も LINE を前に引き戻し続ける。
  ⇒ 正しい条件は『接続中か』（画面に 接続済み のカードが在るか）で判定すること。★未修正。

## 操作 7: 見張り役に自動解除を追加（2026-09-07 朝・剛さまのご依頼）
### 変えたもの① スクリプト（解除 → 承認 → 切断後にロックし直す）
  パターンは repo に書かない。~/.android-lab/pattern（chmod 600）から読む
### 変えたもの② 端末の設定
```
screen_off_pocket   ★元 1 → 0
  理由: Samsung の「誤操作を防止」（窓の名 UnintentionalLcdOn）が
        ロック画面の手前に出て、スワイプでも払えず 解除を塞いでいた（実測）
  戻し方: adb shell settings put system screen_off_pocket 1
  ★代償: ポケットの中などでの誤操作が防止されなくなる
```
### 直後の実測
  解除の試験 ★3 回中 3 回 成功（07:56:11 / 07:56:36 / 07:56:52）
  ★ただし『ロック中に着信を検知して自動で解除する』経路は 未検証

## 操作 8: 操作できない原因を除去（2026-09-07 14:4x）
  症状: 無人アクセス（剛さまが設定）で繋がるが ★LINE を操作できない
  原因: 設定 → 権限 →「以前のセッションのプロファイルを有効にする」が ★true
        ⇒ 無人アクセスのプロファイル（キーボードとマウス ON）ではなく
          ★記憶された『見るだけ』のプロファイルが使われていた
  処置: ★同項目を false へ ＋「以前のセッションプロファイルをクリア」
  戻し方: AnyDesk → 設定 → 権限 → 同項目を再び ON にする
  直後の実測: 無人アクセスを許可する=true / キーボードとマウスを使う=true /
              以前のセッションのプロファイル=false

## 操作 9: 操作できない真因 — AD1 のアクセシビリティが落ちていた（2026-09-07 14:5x）
```
実測（設定値ではなく実体）
  Bound services:{}   Enabled services:{}
  enabled_accessibility_services = null / accessibility_enabled = 0
★いつ・なぜ落ちたかは 未特定
処置 settings put secure enabled_accessibility_services com.anydesk.adcontrol.ad1/...AccService
     settings put secure accessibility_enabled 1
直後 Bound services:{Service[label=AnyDesk Control Service AD1 … capabilities=33]}
戻し方 adb shell settings put secure enabled_accessibility_services null
```

## 無線デバッグ（2026-09-07 14:5x・剛さま裁定 C）
  接続先: 端末の Wi-Fi アドレス:ポート（ポートは接続ごとに変わる）
  ★ペアリングは不要だった — 既に main03 が「ペア設定済みのデバイス」に居た
    （（adbkey の識別子は伏せました。~/.android-lab/ledger.md を参照） ＝ 2026-04-27 の鍵の識別子）
  ★「このネットワークで常に許可する」を選んだ
  ★adb tcpip 5555 は使っていない（Hestia の反対どおり）

## 操作 10: 見張り役に「無線の口を探して繋ぎ直す」を追加（2026-09-12 00:20）
### 何が起きていたか（実測）
```
2026-09-10 11:18  gate.log「✗ 掴める端末が無い」。adb の記録では前の口が応答しなくなった
                  見張り役（9/07 起動）は動き続けたが、端末を 2 日間 掴めなかった
2026-09-12 00:0x  端末は同じ LAN に居た（台帳のアドレスで ping・ARP が応答）
                  開いている口は 2 つとも adb の応答を返さない（CNXN に接続を切る）
                  ⇒ 無線デバッグが OFF。再起動で OFF に戻る仕様
```
### 変えたもの（Mac 側だけ・端末は触っていない）
```
scripts/android/find-adb-port.py  新設。台帳のアドレスの 30000〜60999 を探し、adb の応答を返す口を 1 つ出す
scripts/android/anydesk-gate.sh   掴める端末が無い間、上の道具で口を探して adb connect する
                                  同じアドレスの古い口（offline）は先に外す
                                  間隔は 1 分から倍々に 8 分まで（端末を起こし続けないため）
```
### 戻し方
```
git -C ~/dotfiles checkout <この変更の前の commit> -- scripts/android/anydesk-gate.sh
pkill -f 'bash .*anydesk-gate.sh'; nohup ~/dotfiles/scripts/android/anydesk-gate.sh >/dev/null 2>&1 &
```
### 直後の実測
```
00:20:55  無線の口が見つからない（無線デバッグ OFF の間・両方の分岐のうち「無い」側）
01:56:13  無線の口を見つけて繋ぎ直した ／ 掴む端末 …（剛さまが ON にした直後・「在る」側）
          AnyDesk AD1 のアクセシビリティは束縛あり ／ AnyDesk 本体は起動中 ／ 端末はロック中（正常）
```

## 操作 11: 見張り役がロックを外したまま残す穴を 2 つ塞いだ（2026-09-12 02:21）
### 何が起きていたか（実測）
```
02:12  剛さまが iPhone から接続。解除 → 共有の確認 → ★LINE が一覧に無い（再起動の後で最近使ったアプリに無い）
       → やり直しで「戻る」を押し、共有の確認ごと閉じた → 接続が切れた
       ★接続まで行かなかったので「切断後のロック」が走らず、ロックが外れたまま残った（02:13 に手でロック）
02:13  手でロックした時、前に AnyDesk の最初の画面（MainActivity）が残っていた
       ★見張り役はそれを着信の合図と取り違え、着信が無いのにロックを外した（02:14〜02:19 外れたまま）
```
### 変えたもの（anydesk-gate.sh）
```
合図   既定では「画面共有の確認（MediaProjectionPermissionActivity）」だけでロックを外す
       AnyDesk 本体が前に居るだけでは外さない。AUTO_ACCEPT=1 の時だけ AnyDesk 本体も合図に含める
かけ直し 見張り役が外したロックは、画面共有が始まらないまま 90 秒 経ったらホームへ戻してかけ直す
```
### 戻し方
```
git -C ~/dotfiles log -- scripts/android/anydesk-gate.sh で前の版を探して戻し、見張り役を起こし直す
```
### 直後の実測
```
02:21  ロックしたまま AnyDesk の最初の画面を前に出した → 15 秒 たってもロックは外れない（直す前は外していた場面）
02:24:11 画面共有の確認を検出 → 02:24:23 解除 → 02:24:27 共有 → 次へ → 02:24:32 LINE を選択
       → 02:24:35 LINE を前へ → 02:24:38 接続中を検出 → 02:25:12 切断 → 02:25:15 ロック
★一回りが全部自動で通った。90 秒でかけ直す側は、今夜は発火する場面が無く、動いたことは未確認
★再起動の後の最初の接続は、LINE が最近使ったアプリに無いため失敗しうる。もう一度繋げば通る
```

## 操作 12: 無線デバッグが切れる原因を特定し、端末が自分で網を移らないようにした（2026-09-13 23:4x〜23:5x）
### 何が起きていたか（実測）
```
端末の稼働 11 日（再起動は起きていない）。前の版の「再起動で OFF に戻る」は、下の 4 回の原因ではなかった
9/10 11:18:49  親機側から切断（5620MHz）                    見張り役 11:18 に掴めなくなる
9/12 12:40:11  同じ網のまま 5GHz から 2.4GHz へ（電波 -76）    見張り役 12:40:26
9/12 22:47:41  親機側から切断（5620MHz）                    見張り役 22:47:46
9/13 23:39:27  別の網へ移った → 23:39:28 無線デバッグ OFF（端末の記録 AdbService で直接）
端末に保存された網は 6 つ、家で届くのは 3 つ。9/13 だけで 7 回 繋ぎ直していた
「常に許可」の記録（dumpsys adb の keystore）に在る親機は 1 台分だけ
見張り役は 9/12 23:0x に剛さまの指示で止めた物だった（壊れて止まったのではない）。9/13 23:45 に起こし直した
```
### 変えたもの（端末の設定画面から・剛さま裁定 2026-09-13 23:5x）
```
より最適な Wi-Fi ネットワークに切り替え   ON → OFF（sem_wifi_switch_to_better_wifi_enabled 1 → 0）
家で届く他の 2 つの網の自動再接続         ON → OFF（allowAutojoin true → false。網の名前はカード bee4398d）
変えていない物: モバイルデータに切り替え（ON のまま）／ 家の網 ／ 旅先の網 3 つ
```
adb の `cmd wifi` には、保存済みの網の自動接続を切る命令が無い（網を足し直す時の -d だけで、パスワードが要る）。だから画面から押した。
### 戻し方
```
設定 → 接続 → Wi-Fi → ⋮ → Intelligent Wi-Fi → より最適な Wi-Fi ネットワークに切り替え を ON
設定 → 接続 → Wi-Fi → ⋮ → 詳細設定 → ネットワークを管理 → 網を選ぶ → 自動再接続 を ON
```
### 直後の実測
```
画面のスイッチ 3 つとも checked=false（押す前は true）。押す前に、画面の題が狙った網の名前であることを確かめた
dumpsys wifi  該当 2 網 allowAutojoin=false ／ 他の 4 網は変わらず true
settings      sem_wifi_switch_to_better_wifi_enabled=0
端末は家の網に繋がったまま ／ adb_wifi_enabled=1 ／ 見張り役は端末を掴んだまま ／ 操作の後にロックし直した
```
### 残るもの
```
親機側から切られる分（5620MHz の 2 回）。5620MHz は気象レーダーと共用の帯で、親機が自分でチャンネルを移すことがある（親機の記録は見ていない）
手当てが効いたかは、次に切れるまでの日数でしか分からない。見張り役の記録の「✗ 掴める端末が無い」を数える
```

## 操作 13: 9/14 12:37 から無線が切れている（観測だけ・2026-09-15 19:0x）
### 観測
```
9/13 23:45      見張り役を起こし直した
9/14 00:07・00:28・05:53  接続 3 回。3 回とも 接続中を検出 → 切断 → ロック まで通った
9/14 12:37:37   掴める端末が無い ／ 12:37:56 無線の口が見つからない。以後 繋ぎ直しなし
9/15 19:03      端末は家の網に居ない（ping 応答なし・ARP に無い・AnyDesk の口も閉。陽性対照の親機は応答）
```
### 言えること・言えないこと
```
言える    9/15 19:03 の時点で、端末は家の網の内側から見えない
言えない  持ち出し中か、家に居て Wi-Fi が切れているか ／ 9/13 の手当て（操作 12）が効かなかったか
```
### 次に測ること
端末が家に戻り、無線デバッグが ON になったら、adb shell dumpsys wifi の 9/14 12:37 前後の出来事を読み、操作 12 の 4 回と同じ形で分ける。
