import * as fs from "std/fs/mod.ts";
import * as path from "std/path/mod.ts";
import { parse } from "std/yaml/mod.ts";

const __dirname = path.dirname(path.fromFileUrl(import.meta.url));

interface Link {
  src: string;
  targets?: ("darwin" | "linux" | "windows")[];
}

interface Config {
  link: {
    [Key in string]: Link[];
  };
}

const config = parse(
  await Deno.readTextFile(path.join(__dirname, "config.yaml")),
) as Config;

const homedir = Deno.env.get(
  Deno.build.os === "windows" ? "USERPROFILE" : "HOME",
);

if (typeof homedir === "undefined") {
  throw new Error("Cannot find home directory.");
}

const expand = (filepath: string) => {
  if (filepath[0] === "~") {
    filepath = path.join(homedir, filepath.slice(1));
  }
  filepath = path.normalize(filepath);

  if (!path.isAbsolute(filepath)) {
    filepath = path.join(__dirname, filepath);
  }

  return filepath;
};

const clean = async (dest: string) => {
  if (await fs.exists(dest)) {
    if ((await Deno.readLink(dest).catch(() => null)) !== null) {
      await Deno.remove(dest);
    } else {
      throw new Error("'" + dest + "' already exists.");
    }
  }
};

const link = async (dest: string, src: string) => {
  if (!(await fs.exists(src))) {
    throw new Error("'" + src + "' not exists.");
  }

  await Deno.mkdir(path.dirname(dest), { recursive: true });
  await Deno.symlink(src, dest, {
    type: (await Deno.open(src).catch(() => null)) !== null ? "file" : "dir",
  });
};

for (const v of Object.entries(config.link)) {
  const dest = expand(v[0]);

  for (const l of v[1]) {
    const src = expand(l.src);
    const targets = l.targets;

    if (
      typeof targets !== "undefined" &&
      !targets.map(String).includes(String(Deno.build.os))
    ) {
      continue;
    }

    try {
      console.log();
      console.log(
        "%c" + dest + "%c -> %c" + src,
        "color: blue",
        "color: gray",
        "color: yellow",
      );

      console.log(
        " %cRemoving: %c" + dest + "%c.",
        "color: gray",
        "color: cyan",
        "color: gray",
      );
      await clean(dest);

      console.log(
        " %cCreating link: %c" + dest + "%c -> %c" + src + "%c.",
        "color: gray",
        "color: cyan",
        "color: gray",
        "color: cyan",
        "color: gray",
      );
      await link(dest, src);

      console.log("  %cSuccessed.", "color: green");
    } catch (e) {
      console.error("  %c" + e.toString(), "color: red");
    }
  }
}
