import * as fs from "@std/fs";
import * as path from "@std/path";
import { parse } from "@std/yaml";
import { colors } from "@cliffy/ansi/colors";

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
      console.info();
      console.info(
        `${colors.blue(dest)} ${colors.gray("->")} ${colors.yellow(src)}`,
      );

      console.info(
        ` ${colors.gray("Removing:")} ${colors.cyan(dest)}${colors.gray(".")}`,
      );
      await clean(dest);

      console.info(
        ` ${colors.gray("Creating link:")} ${colors.cyan(dest)} ${
          colors.gray("->")
        } ${colors.cyan(src)}${colors.gray(".")}`,
      );
      await link(dest, src);

      console.info(` ${colors.green("Successed.")}`);
    } catch (e) {
      console.error(` ${colors.red(e.toString())}`);
    }
  }
}
