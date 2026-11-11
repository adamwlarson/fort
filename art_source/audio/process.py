"""Turn the raw generated audio in art_source/audio/raw into the game's .ogg files.

  python art_source/audio/process.py

One-shot effects and voice lines are trimmed of silence, given short fades, mixed to mono
and peak-normalised. Loops are cross-faded end-into-start so they repeat without a click.
Music is loudness-normalised. Needs ffmpeg on PATH.
"""
import array, math, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(ROOT, "raw")
OUT = os.path.normpath(os.path.join(ROOT, "..", "..", "assets", "audio"))
LOOPS = {"amb_day": (-25.0, 1.5), "amb_night": (-25.0, 1.5), "amb_water": (-24.0, 1.2), "fire_loop": (-22.0, 0.8), "jetpack_loop": (-20.0, 0.5), "pot_loop": (-22.0, 0.8)}
TRIM = "silenceremove=start_periods=1:start_threshold=-42dB:start_silence=0.01,areverse,silenceremove=start_periods=1:start_threshold=-46dB:start_silence=0.03,areverse"


def run(args):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-y"] + args, capture_output=True, text=True, encoding="utf-8", errors="replace")


def measure(path, chain):
    """Peak and mean level (dB) and length (s) of a file after a filter chain."""
    out = run(["-i", path, "-af", chain + ",volumedetect", "-f", "null", "-"]).stderr
    found = re.search(r"max_volume: (-?[\d.]+) dB", out)
    if not found:
        return None, None, 0.0
    peak = float(found.group(1))
    mean = float(re.search(r"mean_volume: (-?[\d.]+) dB", out).group(1))
    times = re.findall(r"time=(\d+):(\d+):([\d.]+)", out)
    length = int(times[-1][0]) * 3600 + int(times[-1][1]) * 60 + float(times[-1][2]) if times else 0.0
    return peak, mean, length


def one_shot(source, target, peak_target=-2.0, extra=""):
    chain = "aformat=channel_layouts=mono," + extra + TRIM
    peak, mean, length = measure(source, chain)
    if peak is None or length < 0.05:
        # The trim ate the whole clip (a sound with no clear attack): keep it untrimmed.
        chain = "aformat=channel_layouts=mono," + extra + "anull"
        peak, mean, length = measure(source, chain)
    fade_out = min(0.06, max(0.01, length * 0.2))
    final = "%s,volume=%.2fdB,afade=t=in:d=0.004,afade=t=out:st=%.3f:d=%.3f" % (chain, peak_target - peak, max(0.0, length - fade_out), fade_out)
    result = run(["-i", source, "-af", final, "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", target])
    return result.returncode, length, mean + peak_target - peak


def loop(source, target, mean_target, blend):
    """Cross-fade the last `blend` seconds into the first, in plain PCM, so the loop has no seam."""
    peak, mean, length = measure(source, "anull")
    gain = 10 ** (min(mean_target - mean, -1.0 - peak) / 20.0)
    raw = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", source, "-f", "s16le", "-ac", "2", "-ar", "44100", "-"], capture_output=True).stdout
    samples = array.array("h"); samples.frombytes(raw[:len(raw) // 4 * 4])
    frames = len(samples) // 2
    overlap = int(blend * 44100)
    kept = frames - overlap
    out = array.array("h", bytes(kept * 4))
    for i in range(kept):
        for channel in (0, 1):
            value = samples[i * 2 + channel]
            if i < overlap:
                t = i / overlap
                value = value * t + samples[(kept + i) * 2 + channel] * (1.0 - t)
            out[i * 2 + channel] = max(-32768, min(32767, int(value * gain)))
    result = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-y", "-f", "s16le", "-ac", "2", "-ar", "44100", "-i", "-", "-c:a", "libvorbis", "-q:a", "5", target], input=out.tobytes(), capture_output=True)
    return result.returncode, kept / 44100.0, mean + 20.0 * math.log10(gain)


def music(source, target):
    result = run(["-i", source, "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", target])
    return result.returncode


def main():
    failed = 0
    for folder in ("sfx", "voice", "music"):
        os.makedirs(os.path.join(OUT, folder), exist_ok=True)
        for name in sorted(os.listdir(os.path.join(RAW, folder))):
            stem = os.path.splitext(name)[0]
            source = os.path.join(RAW, folder, name)
            target = os.path.join(OUT, folder, stem + ".ogg")
            if folder == "music":
                code = music(source, target); note = ""
            elif stem in LOOPS:
                code, length, level = loop(source, target, *LOOPS[stem]); note = "loop %.1fs mean %.1f dB" % (length, level)
            else:
                # Speech gets a gentle high-pass so pitched-down lines are not boomy.
                code, length, level = one_shot(source, target, -2.0, "highpass=f=90," if folder == "voice" else "")
                note = "%.2fs mean %.1f dB" % (length, level)
            # A file ffmpeg wrote but nothing can read is a failure too.
            if code == 0 and measure(target, "anull")[0] is None:
                code = 1
            failed += code != 0
            print("%-6s %-18s %s %s" % (folder, stem, "ok" if code == 0 else "FAILED", note))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
