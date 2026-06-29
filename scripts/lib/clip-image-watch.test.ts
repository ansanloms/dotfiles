import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  EVENT_LINE,
  LISTENER_PS,
  run,
  type WatchDeps,
} from "./clip-image-watch.ts";

Deno.test("LISTENER_PS は EVENT_LINE を出力し here-string を閉じる", () => {
  assertStringIncludes(
    LISTENER_PS,
    `[Console]::Out.WriteLine("${EVENT_LINE}")`,
  );
  assertStringIncludes(LISTENER_PS, "$src = @'");
  // here-string の終端 '@ が行頭にあること。
  assertStringIncludes(LISTENER_PS, "\n'@\n");
  // C# の二重引用符が素のまま入っていること。
  assertStringIncludes(
    LISTENER_PS,
    '[DllImport("user32.dll", SetLastError = true)]',
  );
});

function fakeDeps(lineList: string[], overrides: Partial<WatchDeps> = {}): {
  deps: WatchDeps;
  clips: number;
  errors: string[];
} {
  let clips = 0;
  const errors: string[] = [];

  async function* lines(): AsyncIterable<string> {
    for (const l of lineList) {
      yield l;
    }
  }

  const deps: WatchDeps = {
    lines,
    runClip: () => {
      clips++;
      return Promise.resolve();
    },
    errorLine: (m) => errors.push(m),
    ...overrides,
  };

  return {
    deps,
    get clips() {
      return clips;
    },
    set clips(v) {
      clips = v;
    },
    errors,
  };
}

Deno.test("run: EVENT_LINE のたびに clip-image を起動し他の行は無視する", async () => {
  const f = fakeDeps(["image", "noise", "  image  ", ""]);
  const code = await run(f.deps);
  assertEquals(code, 1); // 行ストリーム枯渇で再起動を促す
  assertEquals(f.clips, 2);
  assertEquals(f.errors, ["clip-image-watch: listener exited"]);
});

Deno.test("run: clip-image の失敗で監視を止めない", async () => {
  let n = 0;
  const f = fakeDeps(["image", "image"], {
    runClip: () => {
      n++;
      if (n === 1) {
        return Promise.reject(new Error("boom"));
      }
      return Promise.resolve();
    },
  });
  const code = await run(f.deps);
  assertEquals(code, 1);
  // 1 回目失敗のエラー行 + 終了行。
  assertEquals(f.errors.length, 2);
  assertStringIncludes(f.errors[0], "clip-image failed");
  assertStringIncludes(f.errors[0], "boom");
});
