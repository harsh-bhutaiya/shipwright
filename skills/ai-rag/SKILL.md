---
name: ai-rag
description: Use in a project that calls LLMs, when adding or changing retrieval-augmented generation: deciding between RAG, long context and fine-tuning, ingesting documents, chunking, choosing or changing an embedding model, building search, filtering by user or tenant, or making answers cite sources.
---

# RAG and Document Ingestion

Retrieval feeds documents into the model's context so it can answer from them. Most RAG failures are retrieval failures or access-control failures, not model failures, so each stage is built and checked on its own.

**REQUIRED SUB-SKILL:** invoke `shipwright:ai-engineering` first, if it is not already
loaded. It holds the shared rules and the rule marks this skill relies on.

## Rules
- [practice] Decide RAG vs long context vs fine-tuning before building anything. Only the developer's answer settles it (see Ask the developer). Retrieval is for knowledge that is large, changing or permissioned. Fine-tuning changes behaviour and style, not what the model knows.
- [practice] Ingestion handles each source type on purpose:
  - parse PDFs and keep tables as tables, not flattened text;
  - run OCR on scanned pages and handle images (caption them, extract text, or skip them on purpose);
  - clean boilerplate such as headers, footers and navigation;
  - attach metadata to every chunk: source, document ID, section, date, and the access fields retrieval needs.
- [practice] Ingestion reports what it could not parse. A document that silently yields no text is a bug, not an empty result.
- [practice] Chunk along document structure (headings, paragraphs, table rows, code blocks) before falling back to a fixed size. Keep a chunk understandable alone: carry the title or section path with it. Size and overlap are the developer's choice; tune them with the retrieval eval.
- [reliability] Embeddings are versioned, and everything is re-embedded when the embedding model changes. Store the model ID and version on every vector. Never mix vectors from two models in one index. Build the new index beside the old one, then switch over. See `shipwright:ai-model-lifecycle`.
- [practice] Build search the way the developer chose (see Ask the developer). One option to offer: hybrid search where exact terms matter (IDs, names, codes), keyword plus vector with the scores merged, and metadata filters to narrow by source, date or type.
- [security] Per-user access control is enforced in retrieval, in code, before results reach the prompt.
  - Filter by the caller's permissions inside the search query. Do not retrieve first and drop results afterwards.
  - The caller's identity comes from the authenticated session, never from the model or the request text.
  - A user never sees a chunk, a title, a citation or a count from a document they cannot open.
  - Copy access fields onto chunks at ingestion, and update them when permissions change.
  - Do not cache retrieval results or answers across users.
- [security] Tenant isolation: one tenant's documents are never searchable by another tenant. Enforce it with a mandatory tenant filter applied by the retrieval layer, or a separate index per tenant. A query with no tenant is rejected, not run unfiltered.
- [practice] Query rewriting and multi-query (turning a chat turn into a standalone query, or one question into several) are added only where the retrieval eval shows a gain. Reranking, when used, runs on a wider candidate set and keeps the top few. Cap both, since each adds a model call.
- [practice] Ground the answer in the retrieved chunks and cite them by source. Tell the model it may answer "I don't know" when the chunks do not contain the answer, and check that it does. Show the empty-retrieval case as "nothing found", not a guess.
- [practice] Keep the index fresh with incremental updates: re-index only changed documents. Deletes remove the vectors and the keyword entries, and a deleted or revoked document stops being retrievable. Record when each document was last indexed.
- [practice] Evaluate retrieval separately from generation. Measure recall@k and MRR on questions with known source chunks, then judge the answer on top of that. See `shipwright:ai-evaluation`.
- [security] Retrieved chunks are untrusted data, never instructions. See `shipwright:ai-prompt-injection`.

## Ask the developer
- RAG, long context or fine-tuning? RAG scales to large, changing, permissioned corpora and allows citations, but adds a retrieval system to build and evaluate. Long context is simplest for a small, stable corpus, but costs more per call and degrades as it grows. Fine-tuning shapes style and format, not facts, and needs retraining to update. Follow the project's existing choice if there is one.
- Chunk size and overlap? Small chunks match precisely but lose context. Large chunks keep context but dilute the match and use more of the context budget. Overlap protects boundaries but grows the index. Follow the project's existing choice if there is one.
- Embedding model? A hosted model is easy to run but sends text to a provider and can change under you. A self-hosted model keeps data local but adds operations. Domain fit, language, dimensions, cost and context length all matter. Follow the project's existing choice if there is one.
- Search approach (hybrid, filters)? Vector search finds meaning; keyword search finds exact terms; hybrid covers both at the cost of tuning the merge. Filters narrow results but need clean metadata. Follow the project's existing choice if there is one.
- Reranking? It improves precision at the top, but adds latency and cost per query. Skipping it is simpler and faster. Follow the project's existing choice if there is one.
- Query rewriting? It helps with chat follow-ups and vague questions, but adds a model call and can drift from what the user meant. Follow the project's existing choice if there is one.
- Freshness approach? Real-time sync is current but complex. Scheduled re-indexing is simple but lags. Full rebuilds are easy to reason about but costly. Follow the project's existing choice if there is one.

## Checks
- Was RAG vs long context vs fine-tuning decided with the developer, not assumed?
- Does ingestion handle tables, scans and images, clean the text, attach metadata, and report documents it failed to parse?
- Do chunks follow document structure and carry enough context to stand alone?
- Is the embedding model recorded on every vector, with a plan to re-embed everything when it changes?
- Is the permission or tenant filter applied inside the search query, using an identity taken from the session?
- Does a query with no tenant fail instead of running unfiltered?
- Can a user ever see a chunk, title, citation or count from a document they cannot access?
- Are retrieved chunks treated as untrusted data in the prompt?
- Do answers cite sources, and can the model say "I don't know" when retrieval finds nothing relevant?
- Do updates and deletes reach both the vector and keyword indexes, including revoked access?
- Is retrieval evaluated apart from generation, with recall@k and MRR?

## Related skills
- `shipwright:ai-security-privacy`: authorization in code, personal data in indexed documents.
- `shipwright:ai-prompt-injection`: retrieved chunks are untrusted; injection defences.
- `shipwright:ai-evaluation`: retrieval evals, datasets and graders.
- `shipwright:ai-context-management`: how many chunks fit and where they go in the context.
- `shipwright:ai-model-lifecycle`: migrating the embedding model.
- `shipwright:ai-ux`: showing citations and sources to users.
