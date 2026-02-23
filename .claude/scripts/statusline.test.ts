#!/usr/bin/env deno

const mockInput = {
  hook_event_name: "statusline",
  session_id: "test-session-123",
  transcript_path: "/tmp/test-transcript",
  cwd: "/home/ansanloms/dev/github.com/ansanloms/dotfiles",
  model: {
    id: "claude-sonnet-4-6",
    display_name: "Sonnet",
  },
  workspace: {
    current_dir: "/home/ansanloms/dev/github.com/ansanloms/dotfiles",
    project_dir: "/home/ansanloms/dev/github.com/ansanloms/dotfiles",
  },
  version: "1.0.0",
  output_style: {
    name: "default",
  },
  cost: {
    total_cost_usd: 0.0123,
    total_duration_ms: 45000,
    total_api_duration_ms: 2300,
    total_lines_added: 10,
    total_lines_removed: 3,
  },
  context_window: {
    total_input_tokens: 15000,
    total_output_tokens: 4000,
    context_window_size: 200000,
    used_percentage: 8,
    remaining_percentage: 92,
    current_usage: {
      input_tokens: 8500,
      output_tokens: 1200,
      cache_creation_input_tokens: 5000,
      cache_read_input_tokens: 2000,
    },
  },
};

const proc = new Deno.Command("deno", {
  args: ["run", "-A", new URL("./statusline.ts", import.meta.url).pathname],
  stdin: "piped",
  stdout: "piped",
  stderr: "piped",
});

const child = proc.spawn();

const encoder = new TextEncoder();
const writer = child.stdin.getWriter();
await writer.write(encoder.encode(JSON.stringify(mockInput)));
await writer.close();

const { code, stdout, stderr } = await child.output();

if (code !== 0) {
  console.error("エラー:", new TextDecoder().decode(stderr));
  Deno.exit(1);
}

console.log(new TextDecoder().decode(stdout));
