#!/usr/bin/env python3
"""端末の adb の口を探して「アドレス:口」を標準出力へ 1 行 返す。

探し方は 2 段です。
  1 台帳 ~/.android-lab/ledger.md に書かれたアドレスの口を総当たりする（速い）
  2 それで見つからなければ、端末が自分で名乗っている物を mDNS で拾う（アドレスが変わっても追いつく）

2 段目を足した理由。台帳のアドレスは 1 つしか持てないので、端末か Mac が別の網へ
移ると永遠に見つからなくなります。2026-09-17 に実際に起きました。Mac の側が家の帯から
別の帯へ移り、見張り役は台帳の古いアドレスを探し続けて「端末が家の網に見えない」と記録し続けました。
端末は無線デバッグが ON なら自分から名乗るので、そちらを見れば分かります。

mDNS を信じることの危うさと、その手当て。
  同じ網の誰かが偽の名乗りを出せば、この道具は偽物のアドレスを返します。見張り役は繋いだ相手に
  ロック解除の模様を打ち込むので、偽物に繋ぐと模様が渡ります。
  ですから ~/.android-lab/device-serial に端末の識別子を控えてあり、mDNS の名乗りが
  その識別子を含む物だけを採ります。控えが無い時は mDNS の道を使いません（黙って緩めない）。
  繋いだ後の最終確認は見張り役の側でも行います（getprop ro.serialno との照合）。

アドレスは画面にも記録にも出しません。見つからなければ何も出さず終了コード 1。
"""
import asyncio, os, re, struct, subprocess, sys

LEDGER = os.path.expanduser("~/.android-lab/ledger.md")
SERIAL_PIN = os.path.expanduser("~/.android-lab/device-serial")


def phone_ip():
    try:
        for line in open(LEDGER, encoding="utf-8"):
            if "Wi-Fi アドレス" in line:
                m = re.search(r"(\d{1,3}(?:\.\d{1,3}){3})", line)
                if m:
                    return m.group(1)
    except OSError:
        pass
    return None


def pinned_serial():
    try:
        s = open(SERIAL_PIN, encoding="utf-8").read().strip()
        return s or None
    except OSError:
        return None


def mdns_candidates():
    """adb が見ている mDNS の名乗りから (名乗り, アドレス, 口) を集める。"""
    try:
        out = subprocess.run(["adb", "mdns", "services"], capture_output=True,
                             text=True, timeout=10).stdout
    except Exception:
        return []
    got = []
    for line in out.splitlines():
        if "_adb-tls-connect._tcp" not in line:
            continue
        cols = line.split("\t")
        if len(cols) < 3:
            continue
        name = cols[0].strip()
        m = re.match(r"^(\d{1,3}(?:\.\d{1,3}){3}):(\d+)$", cols[2].strip())
        if m:
            got.append((name, m.group(1), int(m.group(2))))
    return got


CNXN = 0x4E584E43
PAYLOAD = b"host::\x00"
HDR = struct.pack("<6I", CNXN, 0x01000001, 1024 * 1024, len(PAYLOAD),
                  sum(PAYLOAD) & 0xFFFFFFFF, CNXN ^ 0xFFFFFFFF)
ADB_REPLIES = {b"STLS", b"CNXN", b"AUTH"}


async def is_adb(host, port):
    try:
        r, w = await asyncio.wait_for(asyncio.open_connection(host, port), 1.5)
        w.write(HDR + PAYLOAD)
        await w.drain()
        head = await asyncio.wait_for(r.read(4), 2.0)
        w.close()
        return head in ADB_REPLIES
    except Exception:
        return False


async def open_ports(host, lo, hi):
    sem = asyncio.Semaphore(800)
    found = []

    async def probe(p):
        async with sem:
            try:
                _, w = await asyncio.wait_for(asyncio.open_connection(host, p), 0.8)
                found.append(p)
                w.close()
            except Exception:
                pass

    await asyncio.gather(*(probe(p) for p in range(lo, hi + 1)))
    return sorted(found)


async def host_alive(host):
    """総当たりの前に、その相手が生きているかを 1 回だけ見る。"""
    proc = await asyncio.create_subprocess_exec(
        "ping", "-c", "1", "-W", "700", host,
        stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL)
    try:
        return await asyncio.wait_for(proc.wait(), 2.0) == 0
    except Exception:
        try:
            proc.kill()
        except Exception:
            pass
        return False


async def by_ledger():
    host = phone_ip()
    if not host:
        return None
    if not await host_alive(host):
        print("台帳のアドレスは応答しません。総当たりは飛ばします", file=sys.stderr)
        return None
    for p in await open_ports(host, 30000, 60999):
        if await is_adb(host, p):
            return f"{host}:{p}"
    return None


async def by_mdns():
    pin = pinned_serial()
    if not pin:
        print("mDNS の道は使いません（~/.android-lab/device-serial に識別子の控えが在りません）",
              file=sys.stderr)
        return None
    cands = mdns_candidates()
    if not cands:
        return None
    matched = [c for c in cands if pin in c[0]]
    if not matched:
        print(f"mDNS に {len(cands)} 件の名乗りが在りましたが、控えの識別子と合う物は在りません",
              file=sys.stderr)
        return None
    for _, host, port in matched:
        if await is_adb(host, port):
            return f"{host}:{port}"
    return None


async def main():
    # mDNS を先に見ます。2026-09-18 に計ったところ、台帳のアドレスが死んでいる時に
    # 31000 口を総当たりして諦めるまで 31 秒 かかっていました。mDNS は 1 秒ほどで、
    # しかも名乗りの識別子を照合するので、台帳のアドレスより素性が確かです。
    # 台帳は mDNS が使えない時（別の網に居る、mDNS が通らない）の備えとして残します。
    got = await by_mdns()
    if got:
        print(got)
        return 0
    got = await by_ledger()
    if got:
        print(got)
        return 0
    print("mDNS にも台帳のアドレスにも adb の口が在りません", file=sys.stderr)
    return 1


sys.exit(asyncio.run(main()))
