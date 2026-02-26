export type {
  HookInput,
  NotificationHookInput,
  PermissionRequestHookInput,
  StopHookInput,
} from "@anthropic-ai/claude-agent-sdk";

/**
 * Claude Code Statusline JSON Input Types
 *
 * Type definitions for the JSON data passed via stdin to statusline commands.
 *
 * Sources:
 * - https://code.claude.com/docs/en/statusline (official docs)
 * - https://github.com/Piebald-AI/claude-code-system-prompts (system prompt, ccVersion 2.1.47)
 * - https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
 *
 * Note: No official JSON Schema is published by Anthropic.
 * These types are derived from documentation and internal system prompts.
 * Fields may be added or changed across Claude Code versions.
 */
export interface StatusLineInput {
  /** Hook event identifier. Always "Status" for statusline. */
  hook_event_name: "Status";

  /** Unique session ID. */
  session_id: string;

  /** Human-readable session name set via /rename. */
  session_name?: string;

  /** Path to the conversation transcript file. */
  transcript_path: string;

  /** Current working directory. */
  cwd: string;

  /** Information about the active Claude model. */
  model: StatusLineModel;

  /** Workspace directory information. */
  workspace: StatusLineWorkspace;

  /** Claude Code application version (e.g. "1.0.85"). */
  version: string;

  /** Output style configuration. */
  output_style: StatusLineOutputStyle;

  /** Context window usage statistics. */
  context_window: StatusLineContextWindow;

  /** Session cost and performance metrics. */
  cost: StatusLineCost;

  /** Vim mode state. Only present when vim mode is enabled. */
  vim?: StatusLineVim;

  /** Agent metadata. Only present when started with --agent flag. */
  agent?: StatusLineAgent;
}

export interface StatusLineModel {
  /** Model identifier (e.g. "claude-opus-4-1", "claude-sonnet-4-5-20250929"). */
  id: string;

  /** Human-readable model name (e.g. "Opus", "Sonnet"). */
  display_name: string;
}

export interface StatusLineWorkspace {
  /** Current working directory path. */
  current_dir: string;

  /** Project root directory path. */
  project_dir: string;

  /** Directories added via /add-dir. */
  added_dirs?: string[];
}

export interface StatusLineOutputStyle {
  /** Output style name (e.g. "default", "Explanatory", "Learning"). */
  name: string;
}

export interface StatusLineContextWindow {
  /** Total input tokens used in session (cumulative). */
  total_input_tokens: number;

  /** Total output tokens used in session (cumulative). */
  total_output_tokens: number;

  /** Context window size for current model (e.g. 200000). */
  context_window_size: number;

  /** Token usage from last API call. null if no messages have been sent yet. */
  current_usage: StatusLineTokenUsage | null;

  /** Pre-calculated percentage of context used (0-100). null if no messages yet. */
  used_percentage: number | null;

  /** Pre-calculated percentage of context remaining (0-100). null if no messages yet. */
  remaining_percentage: number | null;
}

export interface StatusLineTokenUsage {
  /** Input tokens for current context. */
  input_tokens: number;

  /** Output tokens generated. */
  output_tokens: number;

  /** Tokens written to prompt cache. */
  cache_creation_input_tokens: number;

  /** Tokens read from prompt cache. */
  cache_read_input_tokens: number;
}

export interface StatusLineCost {
  /** Total session cost in USD. */
  total_cost_usd: number;

  /** Total session duration in milliseconds. */
  total_duration_ms: number;

  /** Total API call duration in milliseconds. */
  total_api_duration_ms: number;

  /** Total lines of code added in session. */
  total_lines_added: number;

  /** Total lines of code removed in session. */
  total_lines_removed: number;
}

export interface StatusLineVim {
  /** Current vim editor mode. */
  mode: "INSERT" | "NORMAL";
}

export interface StatusLineAgent {
  /** Agent name (e.g. "code-architect", "test-runner"). */
  name: string;

  /** Agent type identifier. */
  type?: string;
}

/**
 * Settings configuration for statusline in .claude/settings.json.
 */
export interface StatusLineSettings {
  type: "command";

  /** Shell command or script path to execute. */
  command: string;

  /** Horizontal padding. Set to 0 to let status line go to edge. */
  padding?: number;
}
