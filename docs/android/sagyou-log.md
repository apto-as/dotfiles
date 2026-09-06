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
