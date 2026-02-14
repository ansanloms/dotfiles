import { getInput, getMessage } from "./utils.ts";

try {
  const url = Deno.env.get("NTFW_URL");
  const token = Deno.env.get("NTFW_TOKEN");

  if (url && token) {
    const input = await getInput();
    const message = (await getMessage(input)) ?? "";

    await fetch(url, {
      method: "POST", // PUT works too
      body: message,
      headers: {
        Authorization: `Bearer ${token}`,
        Markdown: "yes",
        Title: "Claude Code",
        Tags: input.hook_event_name,
      },
    });
  }
} catch (error) {
  console.error("Client error:", error);
  throw error;
}
