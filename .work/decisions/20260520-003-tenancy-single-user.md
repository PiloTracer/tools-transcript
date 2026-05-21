# ADR 003: Single-user CLI (no multi-tenant)

**Status:** Decided  
**Date:** 2026-05-20

## Context

Product is a local operator tool, not a hosted SaaS.

## Decision

- **No authentication, tenancy, or database** in v1.
- One operator per machine; `./sources` and `./outputs` are local directories.
- No row-level security or API keys.

## Consequences

- Simplifies threat model and stack (no Postgres/Redis).
- Not suitable as multi-user shared service without future ADRs.

## References

- Foundation doc 04 §2
