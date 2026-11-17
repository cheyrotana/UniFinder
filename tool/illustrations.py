"""Makes assets/illustrations/*.svg from the Storyset sources in branding/illustrations/.

(Ported from PhumiYerng mobile.)

Each source is a Storyset "pana" scene: one accent colour on greys, drawn as
top-level layers (`<g id="freepik--Character--inject-14">`). The app themes
and animates them (`AppIllustration`), so this:

- writes every colour as lower-case #rrggbb;
- turns the scene's accent (coral, or blue in the older web exports) into
  coral #ff725e, the one colour the app swaps for the theme's primary;
- names the layers plainly (`<g id="character">`) and adds each one's
  bounding box (`data-box="x y w h"`) so the app can turn a plant around its
  pot or bob a speech bubble around its own centre.

    python -X utf8 tool/illustrations.py
"""

import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / 'branding/illustrations'
OUT = ROOT / 'assets/illustrations'

ACCENT = '#ff725e'
# Storyset's colour choices that are the accent, never skin or a neutral.
ACCENTS = {'#ff725e', '#407bff', '#92e3a9', '#ba68c8', '#ffc727'}

HEX = re.compile(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})(?![0-9a-fA-F])')
NUMBER = re.compile(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')


def colours(svg: str) -> str:
    def six(m: re.Match) -> str:
        h = m.group(1).lower()
        return '#' + (''.join(c * 2 for c in h) if len(h) == 3 else h)
    svg = HEX.sub(six, svg)
    counts = {c: svg.count(c) for c in ACCENTS}
    accent = max(counts, key=counts.get)
    return svg.replace(accent, ACCENT) if counts[accent] else svg


# --- bounding boxes ---------------------------------------------------------

Matrix = tuple[float, float, float, float, float, float]
IDENTITY: Matrix = (1, 0, 0, 1, 0, 0)


def multiply(m: Matrix, n: Matrix) -> Matrix:
    a, b, c, d, e, f = m
    p, q, r, s, t, u = n
    return (a * p + c * q, b * p + d * q, a * r + c * s, b * r + d * s, a * t + c * u + e, b * t + d * u + f)


def parse_transform(text: str) -> Matrix:
    m = IDENTITY
    for name, args in re.findall(r'(\w+)\s*\(([^)]*)\)', text):
        v = [float(x) for x in NUMBER.findall(args)]
        if name == 'matrix':
            n = tuple(v)
        elif name == 'translate':
            n = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            n = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif name == 'rotate':
            r = math.radians(v[0])
            n = (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0)
            if len(v) == 3:
                n = multiply(multiply((1, 0, 0, 1, v[1], v[2]), n), (1, 0, 0, 1, -v[1], -v[2]))
        else:
            continue
        m = multiply(m, n)
    return m


def path_points(d: str) -> list[tuple[float, float]]:
    """The path's end and control points: a box around them holds the path."""
    points = []
    x = y = sx = sy = 0.0
    for cmd, args in re.findall(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)', d):
        v = [float(n) for n in NUMBER.findall(args)]
        rel = cmd.islower()
        c = cmd.upper()
        if c == 'Z':
            x, y = sx, sy
            continue
        size = {'M': 2, 'L': 2, 'T': 2, 'H': 1, 'V': 1, 'C': 6, 'S': 4, 'Q': 4, 'A': 7}[c]
        for i in range(0, len(v) - size + 1, size):
            chunk = v[i:i + size]
            if c == 'H':
                x = x + chunk[0] if rel else chunk[0]
            elif c == 'V':
                y = y + chunk[0] if rel else chunk[0]
            elif c == 'A':
                # Storyset's arcs are short (rounded corners), so their ends
                # bound them well enough; the radii can be huge.
                nx, ny = chunk[5], chunk[6]
                x, y = (x + nx, y + ny) if rel else (nx, ny)
            else:
                for j in range(0, size, 2):
                    px, py = chunk[j], chunk[j + 1]
                    points.append((x + px, y + py) if rel else (px, py))
                x, y = points[-1]
            points.append((x, y))
            if c == 'M' and i == 0:
                sx, sy = x, y
                c = 'L'  # later pairs after a moveto are lines
    return points


def attr(tag: str, name: str, default: float = 0.0) -> float:
    m = re.search(rf'\s{name}="([^"]*)"', tag)
    return float(m.group(1)) if m else default


def element_points(tag: str) -> list[tuple[float, float]]:
    name = re.match(r'<(\w+)', tag).group(1)
    if name == 'path':
        d = re.search(r'\sd="([^"]*)"', tag)
        return path_points(d.group(1)) if d else []
    if name in ('polygon', 'polyline'):
        v = [float(n) for n in NUMBER.findall(re.search(r'points="([^"]*)"', tag).group(1))]
        return list(zip(v[::2], v[1::2]))
    if name == 'rect':
        x, y, w, h = attr(tag, 'x'), attr(tag, 'y'), attr(tag, 'width'), attr(tag, 'height')
        return [(x, y), (x + w, y), (x, y + h), (x + w, y + h)]
    if name in ('circle', 'ellipse'):
        cx, cy = attr(tag, 'cx'), attr(tag, 'cy')
        rx = attr(tag, 'r') or attr(tag, 'rx')
        ry = attr(tag, 'r') or attr(tag, 'ry')
        return [(cx - rx, cy - ry), (cx + rx, cy + ry)]
    if name == 'line':
        return [(attr(tag, 'x1'), attr(tag, 'y1')), (attr(tag, 'x2'), attr(tag, 'y2'))]
    return []


def box(layer: str) -> tuple[float, float, float, float]:
    xs, ys = [], []
    stack = [IDENTITY]
    in_defs = 0
    for tag in re.findall(r'<[^>]+>', layer):
        if tag.startswith('</'):
            if tag.startswith('</g'):
                stack.pop()
            elif tag.startswith(('</defs', '</clipPath')):
                in_defs -= 1
            continue
        if tag.startswith(('<defs', '<clipPath')):
            in_defs += 1
            continue
        t = re.search(r'\stransform="([^"]*)"', tag)
        m = multiply(stack[-1], parse_transform(t.group(1))) if t else stack[-1]
        if tag.startswith('<g'):
            if not tag.endswith('/>'):
                stack.append(m)
            continue
        if in_defs:
            continue
        a, b, c, d, e, f = m
        for px, py in element_points(tag):
            xs.append(a * px + c * py + e)
            ys.append(b * px + d * py + f)
    if not xs:
        return (0, 0, 0, 0)
    return (min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys))


# --- layers -------------------------------------------------------------------

def layers(svg: str):
    """Yields (start, end) of every top-level <g>…</g> inside <svg>."""
    depth = 0
    start = None
    for m in re.finditer(r'<(/?)g\b[^>]*?(/?)>', svg):
        closing, self_closing = m.group(1), m.group(2)
        if self_closing:
            continue
        if not closing:
            if depth == 0:
                start = m.start()
            depth += 1
        else:
            depth -= 1
            if depth == 0:
                yield start, m.end()


def tidy(svg: str) -> str:
    svg = colours(svg)
    # Plain ids: "freepik--Character--inject-14" → "character".
    svg = re.sub(r'id="freepik--([A-Za-z0-9-]+?)--inject-\d+"', lambda m: f'id="{m.group(1).lower()}"', svg)
    svg = re.sub(r'url\(#freepik--([A-Za-z0-9-]+?)--inject-\d+\)', lambda m: f'url(#{m.group(1).lower()})', svg)
    # Scenes from Storyset's storage use plain ids ("Character"): lower-case
    # them and their references the same way.
    svg = re.sub(r'\bid="([^"]+)"', lambda m: f'id="{m.group(1).lower()}"', svg)
    svg = re.sub(r'url\(#([^)]+)\)', lambda m: f'url(#{m.group(1).lower()})', svg)
    svg = re.sub(r'href="#([^"]+)"', lambda m: f'href="#{m.group(1).lower()}"', svg)
    out, last = [], 0
    for start, end in layers(svg):
        g = svg[start:end]
        x, y, w, h = box(g)
        out.append(svg[last:start])
        out.append(re.sub(r'^<g\b', f'<g data-box="{x:.1f} {y:.1f} {w:.1f} {h:.1f}"', g, count=1))
        last = end
    out.append(svg[last:])
    return ''.join(out)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for source in sorted(SOURCES.glob('*.svg')):
        svg = tidy(source.read_text(encoding='utf8'))
        (OUT / source.name).write_text(svg, encoding='utf8')
        names = re.findall(r'<g data-box="([^"]+)" id="([^"]+)"', svg)
        print(f'{source.name}: {len(svg):,} bytes; ' + ', '.join(f'{n} [{b}]' for b, n in names))


main()
