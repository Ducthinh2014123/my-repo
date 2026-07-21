"""Xuat phu de SRT / VTT / TXT."""


def _fmt_time(seconds: float, sep: str = ",") -> str:
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d}{sep}{ms:03d}"


def to_srt(segments) -> str:
    lines = []
    for i, seg in enumerate(segments, 1):
        lines.append(
            f"{i}\n{_fmt_time(seg['start'])} --> {_fmt_time(seg['end'])}\n{seg['text']}\n"
        )
    return "\n".join(lines)


def to_vtt(segments) -> str:
    lines = ["WEBVTT", ""]
    for seg in segments:
        lines.append(
            f"{_fmt_time(seg['start'], '.')} --> {_fmt_time(seg['end'], '.')}\n{seg['text']}\n"
        )
    return "\n".join(lines)


def to_txt(segments) -> str:
    return "\n".join(seg["text"] for seg in segments)


EXPORTERS = {
    "srt": to_srt,
    "vtt": to_vtt,
    "txt": to_txt,
}
