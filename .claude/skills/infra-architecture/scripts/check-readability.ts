#!/usr/bin/env -S deno run --allow-read
/**
 * check-readability.ts
 *
 * draw.io で作成した AWS 構成図の「見やすさ」を幾何的に検査する。
 *
 * 検査は人間の目視ではなく座標計算で行う。判定対象は次の 4 観点。
 *
 *   - overlaps    : エッジ線同士が重なる / 交差する
 *   - legend-hits : エッジ線が凡例ボックスを横切る
 *   - node-cross  : エッジ線が始点・終点でない無関係なノードを貫く
 *   - group-cross : エッジ線が所属しない枠 (VPC / Subnet / 帯 など) を貫く
 *
 * 入力は 2 ファイル。
 *
 *   - .drawio (XML)        : グラフモデル。セルの種別 (edge / vertex / container)、
 *                            エッジの source / target、親子関係 (parent) を取る。
 *   - .drawio.svg / .svg   : エクスポート後の SVG。auto-router で解決済みの実経路と
 *                            ノード矩形を data-cell-id 付きで取る。
 *
 * .drawio の mxGeometry は auto-router の折れ曲がりを含まないため、幾何は必ず SVG から取る。
 * .drawio はセルの意味づけ (種別・接続・所属) だけに使い、両者を id (= data-cell-id) で突き合わせる。
 *
 * Usage:
 *   deno run --allow-read check-readability.ts --drawio diagram.drawio --svg diagram.drawio.svg
 *   deno run --allow-read check-readability.ts --drawio d.drawio --svg d.svg --json
 *   deno run --allow-read check-readability.ts --drawio d.drawio --svg d.svg --legend-id legend
 *
 * 終了コード: ERROR 重大度の指摘が 1 件でもあれば 1、無ければ 0。
 */

export type Point = { x: number; y: number };
export type Rect = { x: number; y: number; w: number; h: number };

export type Cell = {
  id: string;
  kind: "edge" | "node" | "group";
  parent?: string;
  source?: string;
  target?: string;
};

export type Severity = "error" | "warn";
export type Finding = {
  check: "overlaps" | "legend-hits" | "node-cross" | "group-cross";
  severity: Severity;
  message: string;
  cells: string[];
};

const EPS = 1e-6;
// 端点が矩形の境界に乗っているだけの接触を「貫通」と誤検知しないための内側マージン (px)。
const INSET = 0.5;

function die(msg: string): never {
  console.error(`error: ${msg}`);
  Deno.exit(2);
}

function parseArgs(argv: string[]): {
  drawio: string;
  svg: string;
  json: boolean;
  legendId: string;
} {
  let drawio = "";
  let svg = "";
  let json = false;
  let legendId = "legend";
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--drawio") drawio = argv[++i] ?? "";
    else if (a === "--svg") svg = argv[++i] ?? "";
    else if (a === "--json") json = true;
    else if (a === "--legend-id") legendId = argv[++i] ?? "";
    else die(`unknown argument: ${a}`);
  }
  if (!drawio || !svg) {
    die(
      "usage: --drawio <file.drawio> --svg <file.svg> [--json] [--legend-id <id>]",
    );
  }
  return { drawio, svg, json, legendId };
}

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function attr(tag: string, name: string): string | undefined {
  const m = tag.match(new RegExp(`\\b${name}="([^"]*)"`));
  return m ? m[1] : undefined;
}

/**
 * .drawio XML から全 mxCell を読み、種別・接続・所属を確定する。
 * container 判定: style に container=1 / shape=...group / grIcon が含まれる、
 * もしくは他セルの parent に指定されている (= 子を持つ) もの。
 */
export function parseDrawio(xml: string): Map<string, Cell> {
  const cells = new Map<string, Cell>();
  const raw: {
    id: string;
    style: string;
    isEdge: boolean;
    isVertex: boolean;
    parent?: string;
    source?: string;
    target?: string;
  }[] = [];

  const tagRe = /<mxCell\b[^>]*?\/?>/g;
  let m: RegExpExecArray | null;
  while ((m = tagRe.exec(xml)) !== null) {
    const tag = m[0];
    const id = attr(tag, "id");
    if (!id) continue;
    raw.push({
      id,
      style: attr(tag, "style") ?? "",
      isEdge: attr(tag, "edge") === "1",
      isVertex: attr(tag, "vertex") === "1",
      parent: attr(tag, "parent"),
      source: attr(tag, "source"),
      target: attr(tag, "target"),
    });
  }

  const hasChildren = new Set<string>();
  for (const c of raw) if (c.parent) hasChildren.add(c.parent);

  for (const c of raw) {
    if (c.isEdge) {
      cells.set(c.id, {
        id: c.id,
        kind: "edge",
        parent: c.parent,
        source: c.source,
        target: c.target,
      });
      continue;
    }
    if (!c.isVertex) continue; // root cells (0, 1) は対象外
    const looksGroup = /container=1/.test(c.style) ||
      /shape=[^;]*group/.test(c.style) ||
      /grIcon=/.test(c.style);
    const isGroup = looksGroup || hasChildren.has(c.id);
    cells.set(c.id, {
      id: c.id,
      kind: isGroup ? "group" : "node",
      parent: c.parent,
    });
  }
  return cells;
}

/** "translate(tx,ty)" / "translate(tx)" から平行移動量を取る。drawio export は translate のみ使う。 */
export function parseTranslate(s: string): Point {
  const m = s.match(/translate\(\s*([-\d.]+)(?:\s*[, ]\s*([-\d.]+))?\s*\)/);
  if (!m) return { x: 0, y: 0 };
  return { x: parseFloat(m[1]), y: m[2] !== undefined ? parseFloat(m[2]) : 0 };
}

/** path の d から M/L の頂点列を取る (折れ線用)。C などの曲線コマンドは構成図のエッジでは使われない。 */
export function parsePolyline(d: string, off: Point): Point[] {
  const pts: Point[] = [];
  const re = /([ML])\s*([-\d.]+)[ ,]+([-\d.]+)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(d)) !== null) {
    pts.push({ x: parseFloat(m[2]) + off.x, y: parseFloat(m[3]) + off.y });
  }
  return pts;
}

/** path の d に現れる全座標から bbox を取る (ノード / グループの外形矩形用)。 */
export function bboxOfPath(d: string, off: Point): Rect {
  const nums = d.match(/-?\d+(?:\.\d+)?/g)?.map(Number) ?? [];
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (let i = 0; i + 1 < nums.length; i += 2) {
    const x = nums[i] + off.x;
    const y = nums[i + 1] + off.y;
    if (x < minX) minX = x;
    if (y < minY) minY = y;
    if (x > maxX) maxX = x;
    if (y > maxY) maxY = y;
  }
  return { x: minX, y: minY, w: maxX - minX, h: maxY - minY };
}

/**
 * SVG から各 cell id のジオメトリを取る。
 * drawio export は <g data-cell-id="ID"><g transform="translate(t)"><rect|path ...> の順で
 * 最初の図形にセル本体を描く。エッジはその最初の path (fill="none" の開いた線) が経路。
 */
export function extractGeometry(
  svg: string,
  cells: Map<string, Cell>,
): { rects: Map<string, Rect>; polylines: Map<string, Point[]> } {
  const rects = new Map<string, Rect>();
  const polylines = new Map<string, Point[]>();

  for (const [id, cell] of cells) {
    const re = new RegExp(
      `data-cell-id="${
        escapeRe(id)
      }"\\s*>\\s*<g transform="(translate\\([^)]*\\))"\\s*>\\s*(<rect\\b[^>]*>|<path\\b[^>]*>)`,
    );
    const m = svg.match(re);
    if (!m) continue;
    const off = parseTranslate(m[1]);
    const el = m[2];

    if (el.startsWith("<rect")) {
      const x = parseFloat(attr(el, "x") ?? "NaN") + off.x;
      const y = parseFloat(attr(el, "y") ?? "NaN") + off.y;
      const w = parseFloat(attr(el, "width") ?? "NaN");
      const h = parseFloat(attr(el, "height") ?? "NaN");
      if ([x, y, w, h].every((n) => Number.isFinite(n))) {
        rects.set(id, { x, y, w, h });
      }
      continue;
    }

    const d = attr(el, "d") ?? "";
    if (cell.kind === "edge") {
      const pts = parsePolyline(d, off);
      if (pts.length >= 2) polylines.set(id, pts);
    } else {
      rects.set(id, bboxOfPath(d, off));
    }
  }
  return { rects, polylines };
}

// ---- geometry primitives -------------------------------------------------

function sub(a: Point, b: Point): Point {
  return { x: a.x - b.x, y: a.y - b.y };
}
function cross(a: Point, b: Point): number {
  return a.x * b.y - a.y * b.x;
}

/** 線分 p1-p2 と p3-p4 の交差種別。 */
export function segIntersect(
  p1: Point,
  p2: Point,
  p3: Point,
  p4: Point,
): "none" | "cross" | "collinear-overlap" {
  const r = sub(p2, p1);
  const s = sub(p4, p3);
  const rxs = cross(r, s);
  const qp = sub(p3, p1);
  const qpxr = cross(qp, r);

  if (Math.abs(rxs) < EPS && Math.abs(qpxr) < EPS) {
    // 共線。射影区間が正の長さで重なれば overlap。
    const rr = r.x * r.x + r.y * r.y;
    if (rr < EPS) return "none";
    const t0 = (qp.x * r.x + qp.y * r.y) / rr;
    const t1 = t0 + (s.x * r.x + s.y * r.y) / rr;
    const lo = Math.min(t0, t1);
    const hi = Math.max(t0, t1);
    const overlap = Math.min(hi, 1) - Math.max(lo, 0);
    return overlap > EPS ? "collinear-overlap" : "none";
  }
  if (Math.abs(rxs) < EPS) return "none"; // 平行で非共線

  const t = cross(qp, s) / rxs;
  const u = qpxr / rxs;
  if (t >= -EPS && t <= 1 + EPS && u >= -EPS && u <= 1 + EPS) return "cross";
  return "none";
}

/** Liang-Barsky。線分が矩形の内部 (INSET だけ縮めた開矩形) を通るか。 */
export function segEntersRect(p1: Point, p2: Point, rect: Rect): boolean {
  const xmin = rect.x + INSET;
  const ymin = rect.y + INSET;
  const xmax = rect.x + rect.w - INSET;
  const ymax = rect.y + rect.h - INSET;
  if (xmax <= xmin || ymax <= ymin) return false;

  const dx = p2.x - p1.x;
  const dy = p2.y - p1.y;
  let t0 = 0;
  let t1 = 1;
  const clip = (p: number, q: number): boolean => {
    if (Math.abs(p) < EPS) return q >= 0;
    const r = q / p;
    if (p < 0) {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    } else {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    }
    return true;
  };
  if (
    clip(-dx, p1.x - xmin) && clip(dx, xmax - p1.x) &&
    clip(-dy, p1.y - ymin) && clip(dy, ymax - p1.y)
  ) {
    return t1 - t0 > EPS;
  }
  return false;
}

/** 線分が矩形の境界 (4 辺) と交わる回数。 */
export function segCrossesBorder(p1: Point, p2: Point, rect: Rect): number {
  const c: Point[] = [
    { x: rect.x, y: rect.y },
    { x: rect.x + rect.w, y: rect.y },
    { x: rect.x + rect.w, y: rect.y + rect.h },
    { x: rect.x, y: rect.y + rect.h },
  ];
  let n = 0;
  for (let i = 0; i < 4; i++) {
    if (segIntersect(p1, p2, c[i], c[(i + 1) % 4]) !== "none") n++;
  }
  return n;
}

export function pointInRect(p: Point, rect: Rect): boolean {
  return p.x >= rect.x - EPS && p.x <= rect.x + rect.w + EPS &&
    p.y >= rect.y - EPS && p.y <= rect.y + rect.h + EPS;
}

// ---- checks --------------------------------------------------------------

function segmentsOf(pts: Point[]): [Point, Point][] {
  const segs: [Point, Point][] = [];
  for (let i = 0; i + 1 < pts.length; i++) segs.push([pts[i], pts[i + 1]]);
  return segs;
}

/** あるエッジの端点ノード集合 (source / target) を、親チェーンも含めて返す。 */
export function ancestorsOf(
  id: string | undefined,
  cells: Map<string, Cell>,
): Set<string> {
  const out = new Set<string>();
  let cur = id;
  const guard = new Set<string>();
  while (cur && !guard.has(cur)) {
    guard.add(cur);
    out.add(cur);
    cur = cells.get(cur)?.parent;
  }
  return out;
}

export function run(
  cells: Map<string, Cell>,
  rects: Map<string, Rect>,
  polylines: Map<string, Point[]>,
  legendId: string,
): Finding[] {
  const findings: Finding[] = [];
  const edges = [...cells.values()].filter((c) =>
    c.kind === "edge" && polylines.has(c.id)
  );

  // 1) overlaps: 異なるエッジ同士の線分の重なり / 交差。
  for (let i = 0; i < edges.length; i++) {
    for (let j = i + 1; j < edges.length; j++) {
      const a = polylines.get(edges[i].id)!;
      const b = polylines.get(edges[j].id)!;
      let overlap = false;
      let crossCount = 0;
      for (const [a1, a2] of segmentsOf(a)) {
        for (const [b1, b2] of segmentsOf(b)) {
          const r = segIntersect(a1, a2, b1, b2);
          if (r === "collinear-overlap") overlap = true;
          else if (r === "cross") crossCount++;
        }
      }
      if (overlap) {
        findings.push({
          check: "overlaps",
          severity: "error",
          message: `エッジ ${edges[i].id} と ${
            edges[j].id
          } の線が重なっている (共線)`,
          cells: [edges[i].id, edges[j].id],
        });
      } else if (crossCount > 0) {
        findings.push({
          check: "overlaps",
          severity: "warn",
          message: `エッジ ${edges[i].id} と ${
            edges[j].id
          } が ${crossCount} 箇所で交差している`,
          cells: [edges[i].id, edges[j].id],
        });
      }
    }
  }

  // 2) legend-hits: エッジが凡例矩形を横切る。
  const legendRect = rects.get(legendId);
  if (legendRect) {
    for (const e of edges) {
      const pts = polylines.get(e.id)!;
      const hit = segmentsOf(pts).some(([p1, p2]) =>
        segEntersRect(p1, p2, legendRect)
      );
      if (hit) {
        findings.push({
          check: "legend-hits",
          severity: "error",
          message: `エッジ ${e.id} が凡例 (${legendId}) を横切っている`,
          cells: [e.id, legendId],
        });
      }
    }
  }

  // 3) node-cross: エッジが始点・終点でないノードを貫く。凡例はノードではないので除外する。
  const nodes = [...cells.values()].filter((c) =>
    c.kind === "node" && c.id !== legendId && rects.has(c.id)
  );
  for (const e of edges) {
    const pts = polylines.get(e.id)!;
    const endpoints = new Set([e.source, e.target].filter(Boolean) as string[]);
    for (const n of nodes) {
      if (endpoints.has(n.id)) continue;
      const rect = rects.get(n.id)!;
      const through = segmentsOf(pts).some(([p1, p2]) =>
        segEntersRect(p1, p2, rect)
      );
      if (through) {
        findings.push({
          check: "node-cross",
          severity: "error",
          message: `エッジ ${e.id} が無関係なノード ${n.id} を貫いている`,
          cells: [e.id, n.id],
        });
      }
    }
  }

  // 4) group-cross: エッジが所属しない枠を貫く。
  //    エッジの端点 (source / target) がその枠の内側にあれば、枠への出入りは正当とみなす。
  const groups = [...cells.values()].filter((c) =>
    c.kind === "group" && rects.has(c.id)
  );
  for (const e of edges) {
    const pts = polylines.get(e.id)!;
    const srcAnc = ancestorsOf(e.source, cells);
    const tgtAnc = ancestorsOf(e.target, cells);
    for (const g of groups) {
      const rect = rects.get(g.id)!;
      // モデル上 source / target がこの枠の子孫なら正当。
      if (srcAnc.has(g.id) || tgtAnc.has(g.id)) continue;
      // 幾何上いずれかの端点が枠内なら正当 (帯など parent 化していない枠への接続)。
      const ep0 = pts[0];
      const epN = pts[pts.length - 1];
      if (pointInRect(ep0, rect) || pointInRect(epN, rect)) continue;
      const pierces = segmentsOf(pts).some(([p1, p2]) =>
        segCrossesBorder(p1, p2, rect) > 0
      );
      if (pierces) {
        findings.push({
          check: "group-cross",
          severity: "error",
          message: `エッジ ${e.id} が所属しない枠 ${g.id} を貫いている`,
          cells: [e.id, g.id],
        });
      }
    }
  }

  return findings;
}

// ---- main ----------------------------------------------------------------

function main() {
  const { drawio, svg, json, legendId } = parseArgs(Deno.args);
  let xmlText: string;
  let svgText: string;
  try {
    xmlText = Deno.readTextFileSync(drawio);
  } catch {
    die(`cannot read drawio file: ${drawio}`);
  }
  try {
    svgText = Deno.readTextFileSync(svg);
  } catch {
    die(`cannot read svg file: ${svg}`);
  }

  const cells = parseDrawio(xmlText);
  const { rects, polylines } = extractGeometry(svgText, cells);
  const findings = run(cells, rects, polylines, legendId);

  const errors = findings.filter((f) => f.severity === "error");
  const warns = findings.filter((f) => f.severity === "warn");

  if (json) {
    console.log(JSON.stringify(
      {
        summary: { error: errors.length, warn: warns.length },
        findings,
      },
      null,
      2,
    ));
  } else {
    if (findings.length === 0) {
      console.log("OK: 見やすさの幾何チェックで指摘なし");
    } else {
      for (const f of findings) {
        const tag = f.severity === "error" ? "ERROR" : "WARN ";
        console.log(`[${tag}] ${f.check}: ${f.message}`);
      }
      console.log(`\n${errors.length} error / ${warns.length} warn`);
    }
  }

  Deno.exit(errors.length > 0 ? 1 : 0);
}

if (import.meta.main) main();
