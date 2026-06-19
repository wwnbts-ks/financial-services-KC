# Financial Services Plugins

Cowork plugins and Claude Managed Agent templates for financial services. Each named agent ships two ways from one source.

## Repository Structure

```
├── plugins/
│   ├── agent-plugins/               #   named agents — one self-contained plugin each
│   │   └── <slug>/
│   │       ├── .claude-plugin/plugin.json
│   │       ├── agents/<slug>.md     #   ← canonical system prompt (one source, two wrappers)
│   │       └── skills/              #   ← bundled copies, synced from vertical-plugins/
│   ├── vertical-plugins/            #   FSI verticals — skill sources, commands, MCPs
│   │   └── <vertical>/
│   │       ├── .claude-plugin/plugin.json
│   │       ├── commands/
│   │       ├── skills/
│   │       └── .mcp.json
│   └── partner-built/               #   partner plugins (LSEG, S&P Global)
├── managed-agent-cookbooks/         # CMA cookbooks (one dir per named agent)
│   └── <slug>/
│       ├── agent.yaml               #   system + skills → ../../plugins/agent-plugins/<slug>/...
│       ├── subagents/*.yaml         #   depth-1 leaf workers
│       ├── steering-examples.json
│       └── README.md                #   security tier + handoff notes
├── claude-for-msft-365-install/     # admin tooling for the Microsoft 365 add-in (separate from FSI plugins)
└── scripts/                         # deploy-managed-agent.sh, check.py, validate.py, orchestrate.py, sync-agent-skills.py
```

Run `python3 scripts/check.py` before committing — it lints every manifest, verifies all `system.file` / `skills.path` / `callable_agents.manifest` references resolve, and fails if any `agent-plugins/<slug>/skills/` copy has drifted from its `vertical-plugins/` source. **Edit skills in `vertical-plugins/`**, then run `python3 scripts/sync-agent-skills.py` to propagate into the agent bundles.

`check.py` also self-installs a `pre-commit` hook (`git config core.hooksPath .githooks` — no Husky/Node). The hook patch-bumps any plugin's `.claude-plugin/plugin.json` `version` so a branch ends up exactly one patch ahead of `main` (bumped once, not per commit — a plugin's `version` gates update delivery to already-installed users). The `version-bump` GitHub Action enforces the same rule on PRs as a backstop. Bypass a single commit with `git commit --no-verify`; bump logic lives in `scripts/version_bump.py`.

## Key Files

- `marketplace.json`: Marketplace manifest - registers all plugins with source paths
- `plugin.json`: Plugin metadata - name, description, version, and component discovery settings
- `commands/*.md`: Slash commands invoked as `/plugin:command-name`
- `skills/*/SKILL.md`: Detailed knowledge and workflows for specific tasks
- `*.local.md`: User-specific configuration (gitignored)
- `mcp-categories.json`: Canonical MCP category definitions shared across plugins

## Development Workflow

1. Edit markdown files directly - changes take effect immediately
2. Test commands with `/plugin:command-name` syntax
3. Skills are invoked automatically when their trigger conditions match

### Local development loop (avoiding stale-skill surprises)

A plugin you install locally (via the directory marketplace in `~/.claude`) is served from a **version-gated cache**: Claude Code only re-delivers a plugin when its `.claude-plugin/plugin.json` `version` changes. Because `version_bump.py` bumps a branch's version **once** (to one patch ahead of `main`), every edit you make *after* that first bump leaves the version unchanged — so your own installed copy keeps serving the cached snapshot and your new/edited skills never show up in your session. This is a *self-consumption* artifact, not a delivery bug: on merge to `main` the bumped version ships the final content to everyone. **Do not work around it by inflating the version per-commit.**

To iterate on a skill and see edits without bumping/reinstalling, live-load it as a **project skill** (read fresh every session, not cached, not version-gated):

```
scripts/dev-link-skill.sh <vertical> <skill>   # symlink into .claude/skills/ (gitignored)
# edit the skill in plugins/vertical-plugins/<vertical>/skills/<skill>/, then RESTART the session
scripts/dev-link-skill.sh --unlink <skill>     # remove when the skill is stable
```

`.claude/skills/` is gitignored so dev links stay local (a committed link would make every clone load a duplicate of a skill that already ships in the plugin). To validate the *packaged* plugin form before release, bump the patch version, update the plugin in Claude Code, and restart — reserve that for final QA, not routine iteration.

### Pulling Anthropic's upstream updates

This repo is installed as a local **directory** marketplace, so Claude Code's "upstream" is this directory — official upgrades from `anthropics/financial-services` (the `upstream` remote) do **not** arrive automatically. Run `scripts/pull-upstream.sh` to fetch upstream, fast-forward local `main`, and merge it into your customization branch (it stops on conflicts and never pushes). Then update the plugin in Claude Code and restart the session so the new skills reload.
