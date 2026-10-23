#!/usr/bin/env python3
"""repack-boot.py - swap the kernel inside an Android boot image.

Why this instead of mkbootimg: the stock boot.img already carries the exact
header parameters this device's bootloader wants (header v3, page 4096,
cmdline, os_version, ramdisk). Reusing it byte-for-byte and replacing only the
kernel region means there is nothing to get wrong.

Usage:
    repack-boot.py --template boot.img --kernel Image.gz --out boot-new.img
    repack-boot.py --template boot.img --kernel Image.gz --out boot-new.img --dry-run

Notes:
  * Only header v3 (and v4) layouts are handled; v0-v2 carry an extra `id`
    field and a separate dtb, so they are refused unless --force is given.
  * The output is padded back to the template's size so it matches the
    partition. The AVB footer, if any, is zeroed: the content changed, so the
    hash is meaningless anyway, and the bootloader is unlocked.
  * Exit codes: 0 ok, 1 usage/format error, 2 result does not fit.
"""

import argparse
import hashlib
import struct
import sys

PAGE = 4096


def align(n, a=PAGE):
    return (n + a - 1) // a * a


def parse_header(d):
    if len(d) < 64 or d[:8] != b"ANDROID!":
        raise SystemExit("error: not an Android boot image (magic missing)")
    ksz, rsz, osz, hsz = struct.unpack_from("<IIII", d, 8)
    ver = struct.unpack_from("<I", d, 40)[0]
    return {"kernel_size": ksz, "ramdisk_size": rsz, "os_version": osz,
            "header_size": hsz, "header_version": ver}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--template", required=True, help="stock/current boot.img")
    ap.add_argument("--kernel", required=True, help="Image.gz to insert")
    ap.add_argument("--out", required=True)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--force", action="store_true", help="allow v0-v2 layouts")
    args = ap.parse_args()

    tpl = open(args.template, "rb").read()
    ker = open(args.kernel, "rb").read()
    h = parse_header(tpl)

    if h["header_version"] < 3 and not args.force:
        raise SystemExit(
            "error: header v%d carries an `id` field and a separate dtb; "
            "refusing without --force" % h["header_version"])

    if ker[:2] != b"\x1f\x8b":
        raise SystemExit("error: kernel is not gzip (BOARD_KERNEL_IMAGE_NAME is Image.gz)")

    koff = PAGE                                  # header is padded to one page
    roff = koff + align(h["kernel_size"])        # ramdisk start in the template
    tail = tpl[roff:]                            # ramdisk + padding + footer

    new = bytearray()
    new += tpl[:PAGE]                            # header, byte for byte
    new += ker
    new += b"\x00" * (align(len(ker)) - len(ker))
    new += tail

    struct.pack_into("<I", new, 8, len(ker))     # patch kernel_size

    # The AVB footer is a hash of the old content; zero it rather than ship a lie.
    avb_zeroed = False
    if len(new) >= 64 and new[-64:-60] == b"AVBf":
        new[-64:] = b"\x00" * 64
        avb_zeroed = True

    if len(new) > len(tpl):
        print("error: result is %d bytes, partition/template is %d - does not fit"
              % (len(new), len(tpl)), file=sys.stderr)
        return 2
    new += b"\x00" * (len(tpl) - len(new))       # pad back to partition size

    # Re-parse to prove the output is self-consistent.
    check = parse_header(bytes(new))
    assert check["kernel_size"] == len(ker)
    assert bytes(new[PAGE:PAGE + 4]) == ker[:4]

    print("template : %s (%d bytes, header v%d, page %d)"
          % (args.template, len(tpl), h["header_version"], PAGE))
    print("kernel   : %s (%d bytes, was %d)" % (args.kernel, len(ker), h["kernel_size"]))
    print("ramdisk  : kept from template (%d bytes, offset %d)"
          % (h["ramdisk_size"], roff))
    print("avb      : %s" % ("footer zeroed (content changed)" if avb_zeroed else "no footer"))
    print("output   : %s (%d bytes)" % (args.out, len(new)))
    print("md5      : %s" % hashlib.md5(bytes(new)).hexdigest())
    print("sha256   : %s" % hashlib.sha256(bytes(new)).hexdigest())

    if args.dry_run:
        print("dry run: nothing written")
        return 0

    open(args.out, "wb").write(bytes(new))
    print("written.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
