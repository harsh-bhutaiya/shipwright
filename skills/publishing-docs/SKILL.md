---
name: publishing-docs
description: Use after writing a spec, plan or investigation write-up, to publish that local markdown file to the project's wiki when docs_mode is shared-tool. Does nothing in other modes.
---

# Publishing docs

Publishing is one way: the local markdown file is the source, the wiki page is a copy. Never read edits back from the wiki into the file.

Argument: the path of the doc just written (under `<docs_dir>/specs/`, `plans/` or `investigations/`).

## 1. Mode check

```
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get docs_mode
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get wiki_connector
"${CLAUDE_PLUGIN_ROOT}/scripts/shipwright-config" get wiki_location
```

- `docs_mode` is not `shared-tool`: do nothing and say nothing. Stop.
- `wiki_connector` is empty, or no MCP tools from that connector are available in this session: say there is no connector configured, and offer `in-repo` or `local` mode (only if the developer agrees: `shipwright-config set docs_mode <mode>`, then `shipwright-config exclude`, in that order, because `exclude` reads `docs_mode`). Do not publish. Stop.

## 2. Connector operations

Use only four operations from the connector: search, read, create, update a page. Pick the connector's tools by what they do, whatever they are named.

## 3. Publish record

`.shipwright/work/published.conf` holds one `key=value` pair per line, for each published doc:

```
<file path>.page_id=<wiki page id>
<file path>.last_published_version=<page version the wiki returned>
```

It stays after the end-of-work cleanup of `.shipwright/work/`. If the file is missing, no doc has been published. Update a pair by rewriting its line; keep the other lines.

## 4. Publish

1. Look up the record for the file.
2. **No record:** search `wiki_location` for a page with the doc's title.
   - **None found:** create the page in `wiki_location` with the file's content, then write `page_id` and `last_published_version` from the create result.
   - **Found:** stop and show the developer: Shipwright did not create it and will not overwrite it. Only if the developer explicitly says it is this doc's page (for example a teammate published it, or the work dir was wiped), adopt it: write its `page_id` and current version to the record, then go to step 3.
3. **Record exists:** read the page by `page_id` and compare its current version with `last_published_version`.
   - **Equal:** update the page with the file's content, then store the version the update returns as `last_published_version`.
   - **Different:** someone edited the page since the last publish. **Stop. Do not call update.** Show the developer the recorded version, the page's current version and the page URL, and ask what to do (fold their edits into the local file, or overwrite on their explicit say-so). Do not touch the record.
4. Report the page link.

If any connector call fails, report the error and stop; the record stays as it was.
