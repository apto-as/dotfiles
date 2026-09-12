#!/usr/bin/env python3
"""端末の Wi-Fi アドレスで、adb の応答（STLS か CNXN）を返す口を探す。

見つかったら「アドレス:口」を標準出力へ 1 行（見張り役が adb connect に渡す。記録には書かない）。見つからなければ何も出さず終了コード 1。
アドレスは ~/.android-lab/ledger.md から読む（画面には出さない）。
"""
import asyncio, os, re, struct, sys

LEDGER = os.path.expanduser("~/.android-lab/ledger.md")


def phone_ip():
    for line in open(LEDGER, encoding="utf-8"):
        if "Wi-Fi アドレス" in line:
            m = re.search(r"(\d{1,3}(?:\.\d{1,3}){3})", line)
            if m:
                return m.group(1)
    return None


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


async def main():
    host = phone_ip()
    if not host:
        print("台帳に端末のアドレスが無い", file=sys.stderr)
        return 2
    ports = await open_ports(host, 30000, 60999)
    for p in ports:
        if await is_adb(host, p):
            print(f"{host}:{p}")
            return 0
    print(f"adb の口なし（開いている口 {len(ports)} 個はどれも adb ではない）", file=sys.stderr)
    return 1


sys.exit(asyncio.run(main()))
