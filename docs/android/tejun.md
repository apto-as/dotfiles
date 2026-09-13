# 手順 — iPhone から Android の LINE を使う

**2026-09-06 に実際に通した手順です。**（★私 抜きで剛さまだけで再現できるように書いています）

## 前提（3 つ・ここで止まったら先へ進まない）

1. Android の電源が入っていて、画面が点く
2. Android が **AnyDesk を起動したことがある**（常駐サービスが上がっている）
3. iPhone に AnyDesk（iOS 版）が入っている

## ★2026-09-07 以降の手順（いまはこれだけ）

```
1  iPhone の AnyDesk を開いて 接続する
   → ★あとは全部 自動で進みます（承認なし・ロック解除・共有・LINE を前へ）
   → ★閉じれば 自動で消灯してロックされます
★前提: main03 が起きていて、見張り役が動いていること
        ~/dotfiles/scripts/android/anydesk-gate.sh
        （★USB は不要。同じ Wi-Fi 上なら無線で届きます）
```

## 旧手順（見張り役が動いていない時・手で辿る場合）

```
1  iPhone の AnyDesk を開く
2  接続先の 9 桁アドレスを入れる（★在り処: ~/.android-lab/ledger.md）
3  接続する
   → ★Android 側に「着信接続リクエスト」が出る。誰かが「承諾」を押す必要がある
      ・手元に居る → 自分で押す
      ・出先       → ★下の「自動で承諾させる」へ
4  「AnyDesk と画面を共有しますか？」→「次へ」
5  「共有するアプリを選択」→ ★LINE
      ★LINE が一覧に出ない時は、先に Android で LINE を一度 開いておく（最近使ったアプリに載る）
6  Android で LINE を前に出す
      ★アプリ単位の共有なので、LINE が前から外れると iPhone の画面が真っ暗になる
```

**成功の形**: iPhone に LINE の画面が出て、指で触ると Android の LINE が動く。日本語も打てる。

**駄目な時に見る所**:
| 症状 | 見る所 |
|---|---|
| 接続できない | Android の AnyDesk が起動しているか。設定→セキュリティ→アクセス→双方向接続 が「常に許可」か |
| 繋がるが真っ暗 | ★LINE が前に出ているか（アプリ単位の共有のため） |
| 途中で切れる | LINE 以外のアプリへ移ると共有が止まる。画面が消えても止まる |
| 横長で見づらい | ★縦画面に固定する（下記） |
| 繋がるがロック画面から先へ進まない | 端末の 無線デバッグ が OFF。端末の Wi-Fi が切れたり網を移ったりすると Android が自動で OFF にする（再起動ではなかった。2026-09-13 に訂正）。端末で ON にすれば、見張り役が数分以内に自分で繋ぎ直す（2026-09-12〜） |

## ★ 自動で承諾させる（出先で押せない時）

Mac（main03）で、Android を USB で繋いだ状態で:

```bash
~/dotfiles/scripts/android/anydesk-gate.sh
```

- ★**許可する相手の 9 桁アドレスを、スクリプト冒頭の `ALLOW_ID` に書いておく必要があります**
- 許可した 1 台以外からの要求は **承諾しません**（記録だけ残します）
- 画面共有の確認、LINE の選択、LINE を前に戻すことも自動でやります
- **★既知の欠陥**: 接続していない間も LINE を前に引き戻し続けます（`sagyou-log.md` 参照）。
  ★使い終わったら止めてください: `pkill -f anydesk-gate.sh`

## ★ 縦画面に固定する / 戻す

```bash
# 縦に固定（iPhone で見やすくなる）
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0

# 元に戻す（自動回転）
adb shell settings put system accelerometer_rotation 1
```

## ★ 共有範囲を「画面全体」に変えたい時

手順 5 の前、「AnyDesk と画面を共有しますか？」の画面で、
**「1 個のアプリを共有」と書かれた所を押すと「画面全体を共有」が選べます。**

★ ただし画面全体にすると、**SMS のワンタイムコード・Samsung Wallet・Samsung Pass・Termius（SSH の鍵）が
すべて相手に映ります。** LINE だけで足りるなら、狭い方を選んでください。

## やめ方

```
接続を切る          iPhone の AnyDesk で切断、または Android の AnyDesk のカードの × を押す
保存された許可を消す  Android の AnyDesk → 設定 → セキュリティ → アクセス
                     → 「保存されたアクセスデータを削除する」
自動承諾を止める     pkill -f anydesk-gate.sh
```
