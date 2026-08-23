import { assertEquals } from "@std/assert";
import {
  bboxOfPath,
  type Cell,
  extractGeometry,
  type Finding,
  parseDrawio,
  parsePolyline,
  parseTranslate,
  pointInRect,
  run,
  segCrossesBorder,
  segEntersRect,
  segIntersect,
} from "./check-readability.ts";

// ---- geometry primitives -------------------------------------------------

Deno.test("segIntersect: transversal crossing", () => {
  assertEquals(
    segIntersect({ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 5, y: -5 }, {
      x: 5,
      y: 5,
    }),
    "cross",
  );
});

Deno.test("segIntersect: collinear overlap", () => {
  assertEquals(
    segIntersect({ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 5, y: 0 }, {
      x: 15,
      y: 0,
    }),
    "collinear-overlap",
  );
});

Deno.test("segIntersect: collinear but disjoint", () => {
  assertEquals(
    segIntersect({ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 20, y: 0 }, {
      x: 30,
      y: 0,
    }),
    "none",
  );
});

Deno.test("segIntersect: parallel non-collinear", () => {
  assertEquals(
    segIntersect({ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 0, y: 5 }, {
      x: 10,
      y: 5,
    }),
    "none",
  );
});

Deno.test("segEntersRect: passes through interior", () => {
  const rect = { x: 0, y: 0, w: 10, h: 10 };
  assertEquals(segEntersRect({ x: 5, y: -5 }, { x: 5, y: 15 }, rect), true);
});

Deno.test("segEntersRect: fully outside", () => {
  const rect = { x: 0, y: 0, w: 10, h: 10 };
  assertEquals(segEntersRect({ x: 20, y: 20 }, { x: 30, y: 30 }, rect), false);
});

Deno.test("segEntersRect: grazing the border is not entering (INSET)", () => {
  const rect = { x: 0, y: 0, w: 10, h: 10 };
  // y=0 ちょうどの線は内側マージン (INSET) の外なので貫通扱いにしない。
  assertEquals(segEntersRect({ x: -5, y: 0 }, { x: 15, y: 0 }, rect), false);
});

Deno.test("segCrossesBorder: counts entry and exit edges", () => {
  const rect = { x: 0, y: 0, w: 10, h: 10 };
  assertEquals(segCrossesBorder({ x: 5, y: -5 }, { x: 5, y: 15 }, rect), 2);
});

Deno.test("pointInRect", () => {
  const rect = { x: 0, y: 0, w: 10, h: 10 };
  assertEquals(pointInRect({ x: 5, y: 5 }, rect), true);
  assertEquals(pointInRect({ x: 15, y: 5 }, rect), false);
});

// ---- parsing -------------------------------------------------------------

Deno.test("parseTranslate: two args and one arg", () => {
  assertEquals(parseTranslate("translate(0.5,0.5)"), { x: 0.5, y: 0.5 });
  assertEquals(parseTranslate("translate(3)"), { x: 3, y: 0 });
});

Deno.test("parsePolyline: M/L vertices with offset", () => {
  const pts = parsePolyline("M 100 20 L 400 20 L 400 213.63", { x: 0, y: 0 });
  assertEquals(pts, [
    { x: 100, y: 20 },
    { x: 400, y: 20 },
    { x: 400, y: 213.63 },
  ]);
});

Deno.test("bboxOfPath: closed rectangle path", () => {
  const r = bboxOfPath("M 40 240 L 118 240 L 118 318 L 40 318 Z", {
    x: 0,
    y: 0,
  });
  assertEquals(r, { x: 40, y: 240, w: 78, h: 78 });
});

Deno.test("parseDrawio: classifies edge / node / group", () => {
  const xml = `
    <root>
      <mxCell id="0"/>
      <mxCell id="1" parent="0"/>
      <mxCell id="vpc" style="container=1;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc;" vertex="1" parent="1"><mxGeometry/></mxCell>
      <mxCell id="ec2" style="shape=mxgraph.aws4.resourceIcon;" vertex="1" parent="vpc"><mxGeometry/></mxCell>
      <mxCell id="rds" style="shape=mxgraph.aws4.resourceIcon;" vertex="1" parent="1"><mxGeometry/></mxCell>
      <mxCell id="e1" edge="1" source="ec2" target="rds" parent="1"><mxGeometry/></mxCell>
    </root>`;
  const cells = parseDrawio(xml);
  assertEquals(cells.get("vpc")?.kind, "group"); // container=1
  assertEquals(cells.get("ec2")?.kind, "node");
  assertEquals(cells.get("rds")?.kind, "node");
  const e1 = cells.get("e1");
  assertEquals(e1?.kind, "edge");
  assertEquals(e1?.source, "ec2");
  assertEquals(e1?.target, "rds");
  // root cells (0, 1) are not tracked as vertices/edges
  assertEquals(cells.has("0"), false);
});

Deno.test("parseDrawio: vertex with children is treated as a group", () => {
  const xml = `
    <root>
      <mxCell id="1" parent="0"/>
      <mxCell id="band" style="rounded=0;" vertex="1" parent="1"><mxGeometry/></mxCell>
      <mxCell id="child" style="shape=mxgraph.aws4.resourceIcon;" vertex="1" parent="band"><mxGeometry/></mxCell>
    </root>`;
  const cells = parseDrawio(xml);
  // band は container 指定が無くても、子を持つので枠とみなす。
  assertEquals(cells.get("band")?.kind, "group");
  assertEquals(cells.get("child")?.kind, "node");
});

// ---- integration over real drawio export fixtures ------------------------

function findingsFor(name: string): Finding[] {
  const xml = Deno.readTextFileSync(
    new URL(`./testdata/${name}.drawio`, import.meta.url),
  );
  const svg = Deno.readTextFileSync(
    new URL(`./testdata/${name}.svg`, import.meta.url),
  );
  const cells: Map<string, Cell> = parseDrawio(xml);
  const { rects, polylines } = extractGeometry(svg, cells);
  return run(cells, rects, polylines, "legend");
}

function countByCheck(findings: Finding[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const f of findings) out[f.check] = (out[f.check] ?? 0) + 1;
  return out;
}

Deno.test("integration: clean diagram has no findings", () => {
  const findings = findingsFor("clean");
  assertEquals(findings, []);
});

Deno.test("integration: bad diagram fires all four checks", () => {
  const findings = findingsFor("bad");
  const errors = findings.filter((f) => f.severity === "error");
  const warns = findings.filter((f) => f.severity === "warn");
  assertEquals(errors.length, 5);
  assertEquals(warns.length, 0);
  assertEquals(countByCheck(errors), {
    "overlaps": 1, // e_ab1 と e_ab2 の共線重なり
    "legend-hits": 1, // e_cd が凡例を横切る
    "node-cross": 2, // e_ab1 / e_ab2 が mid を貫く
    "group-cross": 1, // e_ef が vpc を貫く
  });
});
