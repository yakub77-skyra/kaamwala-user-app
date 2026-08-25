-- KaamWala v2 — 0007 schema usage grant (applied via MCP)
-- Roles need USAGE on kw_private for its trigger functions to execute.
grant usage on schema kw_private to authenticated, service_role, anon;
