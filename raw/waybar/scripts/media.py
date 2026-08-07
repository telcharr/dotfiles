#!/usr/bin/env python3

import json
import os
import select
import subprocess
import sys
import time
import unicodedata

WIDTH = 36
STEP = 0.25
DWELL = 2.0
RETRY = 2.0
NOTIFY_MS = 2000
SUFFIX = " - Topic"
PLAYER = "playerctld,%any"
FMT = "{{status}}\t{{artist}}\t{{title}}"

notifiers = []


def width(ch):
    return 2 if unicodedata.east_asian_width(ch) in "WF" else 1


def cols(text):
    return sum(width(ch) for ch in text)


def frame(text, start):
    out = []
    used = 0
    for ch in text[start:]:
        w = width(ch)
        if used + w > WIDTH:
            break
        out.append(ch)
        used += w
    return "".join(out) + " " * (WIDTH - used)


def last_offset(text):
    for i in range(len(text)):
        if cols(text[i:]) <= WIDTH:
            return i
    return 0


def escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def clean(text):
    return " ".join(text.split()).lower()


def parse(raw):
    parts = raw.decode("utf-8", "replace").split("\t", 2)
    if len(parts) < 3:
        return "", "", ""
    artist = parts[1].strip()
    if artist.endswith(SUFFIX):
        artist = artist[: -len(SUFFIX)]
    return parts[0], clean(artist), clean(parts[2])


def joined(artist, title):
    if artist and title:
        return f"{artist} — {title}"
    return title or artist


def notify(artist, title):
    args = [
        "notify-send",
        "-a",
        "music",
        "-t",
        str(NOTIFY_MS),
        "-h",
        "string:x-canonical-private-synchronous:music",
    ]
    args += [artist, title] if artist else [title]
    try:
        notifiers.append(
            subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        )
    except FileNotFoundError:
        pass
    notifiers[:] = [p for p in notifiers if p.poll() is None]


def spawn():
    return subprocess.Popen(
        ["playerctl", "--player", PLAYER, "--follow", "--format", FMT, "metadata"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        bufsize=0,
    )


def main():
    try:
        proc = spawn()
    except FileNotFoundError:
        print(json.dumps({"text": "", "class": "stopped"}), flush=True)
        return

    buf = b""
    status = ""
    notified = None
    text = ""
    offset = 0
    limit = 0
    forward = True
    deadline = None
    emitted = None

    while True:
        timeout = None if deadline is None else max(0.0, deadline - time.monotonic())
        ready, _, _ = select.select([proc.stdout], [], [], timeout)

        if not ready:
            if forward:
                offset = min(offset + 1, limit)
            else:
                offset = max(offset - 1, 0)
            if offset in (0, limit):
                forward = not forward
                deadline = time.monotonic() + DWELL
            else:
                deadline = time.monotonic() + STEP
        else:
            chunk = os.read(proc.stdout.fileno(), 4096)
            if not chunk:
                proc.wait()
                print(json.dumps({"text": "", "class": "stopped"}), flush=True)
                emitted = None
                status, text, offset, limit, deadline = "", "", 0, 0, None
                time.sleep(RETRY)
                proc = spawn()
                buf = b""
                continue

            buf += chunk
            while b"\n" in buf:
                raw, buf = buf.split(b"\n", 1)
                incoming, artist, title = parse(raw)
                body = joined(artist, title)
                current = (artist, title)
                restart = False

                if notified is None:
                    notified = current
                elif body and incoming == "Playing" and current != notified:
                    notify(artist, title)
                    notified = current

                if body != text:
                    text = body
                    limit = last_offset(text)
                    restart = True

                if incoming == "Playing" and status != "Playing":
                    restart = True
                status = incoming
                if restart:
                    offset = 0
                    forward = True
                if status == "Playing" and limit > 0:
                    if restart or deadline is None:
                        deadline = time.monotonic() + DWELL
                else:
                    deadline = None

        if not text:
            payload = {"text": "", "class": "stopped"}
        else:
            body = frame(text, offset) if limit > 0 else text
            payload = {
                "text": escape(body),
                "class": "playing" if status == "Playing" else "paused",
            }

        line = json.dumps(payload)
        if line != emitted:
            emitted = line
            print(line, flush=True)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
