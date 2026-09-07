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
