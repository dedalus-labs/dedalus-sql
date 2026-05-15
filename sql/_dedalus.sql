-- A file that declares all schemas and types upfront so that their definitions don't
-- have to be topologically sorted in other files. It also creates some internal utility functions.

CREATE SCHEMA IF NOT EXISTS dedalus_internal;
REVOKE ALL ON SCHEMA dedalus_internal FROM PUBLIC;

CREATE OR REPLACE FUNCTION dedalus_internal.ensure_empty_type(
  p_schema TEXT,
  p_type TEXT
)
RETURNS void
LANGUAGE plpgsql
AS $$
  DECLARE
    attr RECORD;
  BEGIN
    -- Create an empty type if it doesn't exist from a previous extension version.
    IF NOT EXISTS (
      SELECT 1
      FROM pg_type t
      JOIN pg_namespace n ON n.oid = t.typnamespace
      WHERE t.typname = p_type
        AND n.nspname = p_schema
    ) THEN
      EXECUTE format(
        'CREATE TYPE %I.%I AS ();',
        p_schema,
        p_type
      );
      -- Already empty, nothing to drop.
      RETURN;
    END IF;

    -- Drop all existing attributes from the previous extension version so we can readd them.
    FOR attr IN
      SELECT a.attname
      FROM pg_attribute a
      JOIN pg_type t ON t.typrelid = a.attrelid
      JOIN pg_namespace n ON n.oid = t.typnamespace
      WHERE t.typname = p_type
        AND n.nspname = p_schema
        AND a.attnum > 0
        AND NOT a.attisdropped
      ORDER BY a.attnum DESC
    LOOP
      EXECUTE format(
        'ALTER TYPE %I.%I DROP ATTRIBUTE %I;',
        p_schema,
        p_type,
        attr.attname
      );
    END LOOP;
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_internal.ensure_context()
RETURNS void
LANGUAGE plpython3u
AS $$
  from types import SimpleNamespace
  from dedalus_sdk import Dedalus

  if "__dedalus_context__" in GD:
      # The context was already created.
      return

  client_options = {}
  try:
      value = plpy.execute("SELECT current_setting('dedalus.base_url') AS value")[0]['value']
      client_options["base_url"] = value
  except Exception:
      # This configuration parameter was not set, but it's optional so ignore the exception.
      pass
  try:
      value = plpy.execute("SELECT current_setting('dedalus.api_key') AS value")[0]['value']
      client_options["api_key"] = value
  except Exception:
      # This configuration parameter was not set, but it's optional so ignore the exception.
      pass
  try:
      value = plpy.execute("SELECT current_setting('dedalus.x_api_key') AS value")[0]['value']
      client_options["x_api_key"] = value
  except Exception:
      # This configuration parameter was not set, but it's optional so ignore the exception.
      pass
  try:
      value = plpy.execute("SELECT current_setting('dedalus.org_id') AS value")[0]['value']
      client_options["dedalus_org_id"] = value
  except Exception:
      # This configuration parameter was not set, but it's optional so ignore the exception.
      pass

  def strip_none(value):
      if isinstance(value, dict):
          return {
              k: strip_none(v)
              for k, v in value.items()
              if v is not None
          }
      elif isinstance(value, list):
          return [strip_none(v) for v in value]
      else:
          return value

  GD["__dedalus_context__"] = SimpleNamespace(
      client=Dedalus(**client_options),
      strip_none=strip_none,
  )
$$;

CREATE TYPE dedalus_internal.page AS (
  data JSONB,
  next_request_options JSONB
);

CREATE SCHEMA IF NOT EXISTS dedalus_usage;

CREATE TYPE dedalus_usage.machine_compute_usage AS ();
CREATE TYPE dedalus_usage.machine_compute_usage_row AS ();
CREATE TYPE dedalus_usage.machine_storage_usage AS ();
CREATE TYPE dedalus_usage.machine_storage_usage_row AS ();
CREATE TYPE dedalus_usage.org_usage AS ();

CREATE SCHEMA IF NOT EXISTS dedalus_machines;

CREATE TYPE dedalus_machines.create_params AS ();
CREATE TYPE dedalus_machines.lifecycle_status AS ();
CREATE TYPE dedalus_machines.machine AS ();
CREATE TYPE dedalus_machines.machine_list AS ();
CREATE TYPE dedalus_machines.machine_list_item AS ();
CREATE TYPE dedalus_machines.update_params AS ();

CREATE SCHEMA IF NOT EXISTS dedalus_machines_artifacts;

CREATE TYPE dedalus_machines_artifacts.artifact AS ();
CREATE TYPE dedalus_machines_artifacts.artifact_list AS ();

CREATE SCHEMA IF NOT EXISTS dedalus_machines_previews;

CREATE TYPE dedalus_machines_previews.preview AS ();
CREATE TYPE dedalus_machines_previews.preview_create_params AS ();
CREATE TYPE dedalus_machines_previews.preview_list AS ();

CREATE SCHEMA IF NOT EXISTS dedalus_machines_ssh;

CREATE TYPE dedalus_machines_ssh.ssh_connection AS ();
CREATE TYPE dedalus_machines_ssh.ssh_host_trust AS ();
CREATE TYPE dedalus_machines_ssh.ssh_session AS ();
CREATE TYPE dedalus_machines_ssh.ssh_session_create_params AS ();
CREATE TYPE dedalus_machines_ssh.ssh_session_list AS ();

CREATE SCHEMA IF NOT EXISTS dedalus_machines_executions;

CREATE TYPE dedalus_machines_executions.artifact_ref AS ();
CREATE TYPE dedalus_machines_executions.execution AS ();
CREATE TYPE dedalus_machines_executions.execution_create_params AS ();
CREATE TYPE dedalus_machines_executions.execution_event AS ();
CREATE TYPE dedalus_machines_executions.execution_events AS ();
CREATE TYPE dedalus_machines_executions.execution_list AS ();
CREATE TYPE dedalus_machines_executions.execution_output AS ();

CREATE SCHEMA IF NOT EXISTS dedalus_machines_terminals;

CREATE TYPE dedalus_machines_terminals.terminal AS ();
CREATE TYPE dedalus_machines_terminals.terminal_client_event AS ();
CREATE TYPE dedalus_machines_terminals.terminal_closed_event AS ();
CREATE TYPE dedalus_machines_terminals.terminal_create_params AS ();
CREATE TYPE dedalus_machines_terminals.terminal_error_event AS ();
CREATE TYPE dedalus_machines_terminals.terminal_input_event AS ();
CREATE TYPE dedalus_machines_terminals.terminal_list AS ();
CREATE TYPE dedalus_machines_terminals.terminal_output_event AS ();
CREATE TYPE dedalus_machines_terminals.terminal_resize_event AS ();
CREATE TYPE dedalus_machines_terminals.terminal_server_event AS ();