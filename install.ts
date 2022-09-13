import * as fs from "std/fs/mod.ts";
import * as path from "std/path/mod.ts";
import { parse } from "std/encoding/yaml.ts";

const __filename = path.fromFileUrl(import.meta.url);
const __dirname = path.dirname(path.fromFileUrl(import.meta.url));

interface Option {
  target?: string[];
  skip?: string[] | boolean;
  clean?: boolean;
}

interface Link {
  src: string;
  option?: Option;
}

interface Config {
  link: {
    [Key in string]: Link;
  };
}

const config = parse(
  (new TextDecoder("utf-8")).decode(
    await Deno.readAll(await Deno.open(path.join(__dirname, "config.yaml"))),
  ),
) as Config;

const homedir = Deno.env.get(
  Deno.build.os === "windows" ? "USERPROFILE" : "HOME",
);

if (typeof homedir === "undefined") {
  throw new Error("Cannot find home directory.");
  Deno.exit(1);
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

const skip = (option: Option | undefined) => {
  if (typeof option === "undefined") {
    return false;
  }

  if (
    typeof option?.target !== "undefined" &&
    !option.target.includes(Deno.build.os)
  ) {
    return true;
  }

  if (
    typeof option?.skip !== "undefined" &&
    Array.isArray(option?.skip) &&
    option.skip.includes(Deno.build.os)
  ) {
    return true;
  }

  if (option?.skip === true) {
    return true;
  }

  return false;
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

for (const dest in config.link) {
  try {
    const _src = expand(config.link[dest].src);
    const _dest = expand(dest);
    const _option = config.link[dest].option;

    console.log();
    console.log(
      "%c" + _dest + "%c -> %c" + _src,
      "color: blue",
      "color: gray",
      "color: yellow",
    );

    if (skip(_option)) {
      if (_option?.clean === true) {
        console.log(
          " %cRemoving: %c" + _dest + "%c.",
          "color: gray",
          "color: cyan",
          "color: gray",
        );
        await clean(_dest);
      }

      console.log(" %cThis is a skip target.", "color: gray");
    } else {
      console.log(
        " %cRemoving: %c" + _dest + "%c.",
        "color: gray",
        "color: cyan",
        "color: gray",
      );
      await clean(_dest);

      console.log(
        " %cCreating link: %c" + _dest + "%c -> %c" + _src + "%c.",
        "color: gray",
        "color: cyan",
        "color: gray",
        "color: cyan",
        "color: gray",
      );
      await link(_dest, _src);
    }

    console.log("  %cSuccessed.", "color: green");
  } catch (e) {
    console.error("  %c" + e.toString(), "color: red");
  }
}
