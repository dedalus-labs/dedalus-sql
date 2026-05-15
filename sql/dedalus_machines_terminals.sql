ALTER TYPE dedalus_machines_terminals.terminal
  ADD ATTRIBUTE created_at TIMESTAMP,
  ADD ATTRIBUTE height BIGINT,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE status TEXT,
  ADD ATTRIBUTE terminal_id TEXT,
  ADD ATTRIBUTE width BIGINT,
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT,
  ADD ATTRIBUTE expires_at TIMESTAMP,
  ADD ATTRIBUTE protocol TEXT,
  ADD ATTRIBUTE ready_at TIMESTAMP,
  ADD ATTRIBUTE retry_after_ms BIGINT,
  ADD ATTRIBUTE stream_url TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal(
  created_at TIMESTAMP,
  height BIGINT,
  machine_id TEXT,
  status TEXT,
  terminal_id TEXT,
  width BIGINT,
  error_code TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  expires_at TIMESTAMP DEFAULT NULL,
  protocol TEXT DEFAULT NULL,
  ready_at TIMESTAMP DEFAULT NULL,
  retry_after_ms BIGINT DEFAULT NULL,
  stream_url TEXT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    created_at,
    height,
    machine_id,
    status,
    terminal_id,
    width,
    error_code,
    error_message,
    expires_at,
    protocol,
    ready_at,
    retry_after_ms,
    stream_url
  )::dedalus_machines_terminals.terminal;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_client_event
  ADD ATTRIBUTE type TEXT,
  ADD ATTRIBUTE data TEXT,
  ADD ATTRIBUTE height BIGINT,
  ADD ATTRIBUTE width BIGINT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_client_event(
  type TEXT,
  data TEXT DEFAULT NULL,
  height BIGINT DEFAULT NULL,
  width BIGINT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal_client_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    type, data, height, width
  )::dedalus_machines_terminals.terminal_client_event;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_closed_event
  ADD ATTRIBUTE type TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_closed_event(
  type TEXT
)
RETURNS dedalus_machines_terminals.terminal_closed_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(type)::dedalus_machines_terminals.terminal_closed_event;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_create_params
  ADD ATTRIBUTE height BIGINT,
  ADD ATTRIBUTE width BIGINT,
  ADD ATTRIBUTE cwd TEXT,
  ADD ATTRIBUTE env JSONB,
  ADD ATTRIBUTE shell TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_create_params(
  height BIGINT,
  width BIGINT,
  cwd TEXT DEFAULT NULL,
  env JSONB DEFAULT NULL,
  shell TEXT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal_create_params
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    height, width, cwd, env, shell
  )::dedalus_machines_terminals.terminal_create_params;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_error_event
  ADD ATTRIBUTE type TEXT,
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_error_event(
  type TEXT, error_code TEXT DEFAULT NULL, error_message TEXT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal_error_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    type, error_code, error_message
  )::dedalus_machines_terminals.terminal_error_event;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_input_event
  ADD ATTRIBUTE data TEXT, ADD ATTRIBUTE type TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_input_event(
  data TEXT, type TEXT
)
RETURNS dedalus_machines_terminals.terminal_input_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(data, type)::dedalus_machines_terminals.terminal_input_event;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_list
  ADD ATTRIBUTE items dedalus_machines_terminals.terminal[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_list(
  items dedalus_machines_terminals.terminal[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal_list
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines_terminals.terminal_list;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_output_event
  ADD ATTRIBUTE data TEXT, ADD ATTRIBUTE type TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_output_event(
  data TEXT, type TEXT
)
RETURNS dedalus_machines_terminals.terminal_output_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(data, type)::dedalus_machines_terminals.terminal_output_event;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_resize_event
  ADD ATTRIBUTE height BIGINT,
  ADD ATTRIBUTE type TEXT,
  ADD ATTRIBUTE width BIGINT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_resize_event(
  height BIGINT, type TEXT, width BIGINT
)
RETURNS dedalus_machines_terminals.terminal_resize_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    height, type, width
  )::dedalus_machines_terminals.terminal_resize_event;
$$;

ALTER TYPE dedalus_machines_terminals.terminal_server_event
  ADD ATTRIBUTE type TEXT,
  ADD ATTRIBUTE data TEXT,
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.make_terminal_server_event(
  type TEXT,
  data TEXT DEFAULT NULL,
  error_code TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal_server_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    type, data, error_code, error_message
  )::dedalus_machines_terminals.terminal_server_event;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals._create(
  machine_id TEXT,
  height BIGINT,
  width BIGINT,
  cwd TEXT DEFAULT NULL,
  env JSONB DEFAULT NULL,
  shell TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  import json
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.machines.terminals.with_raw_response.create(
      machine_id=machine_id,
      height=height,
      width=width,
      cwd=not_given if cwd is None else cwd,
      env=not_given if env is None else json.loads(env),
      shell=not_given if shell is None else shell,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.create(
  machine_id TEXT,
  height BIGINT,
  width BIGINT,
  cwd TEXT DEFAULT NULL,
  env JSONB DEFAULT NULL,
  shell TEXT DEFAULT NULL
)
RETURNS dedalus_machines_terminals.terminal
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_terminals.terminal,
      dedalus_machines_terminals._create(
        machine_id, height, width, cwd, env, shell
      )
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals._retrieve(
  machine_id TEXT, terminal_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.terminals.with_raw_response.retrieve(
      machine_id=machine_id,
      terminal_id=terminal_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.retrieve(
  machine_id TEXT, terminal_id TEXT
)
RETURNS dedalus_machines_terminals.terminal
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_terminals.terminal,
      dedalus_machines_terminals._retrieve(machine_id, terminal_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals._list_first_page_py(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.terminals.list(
      machine_id=machine_id,
      cursor=not_given if cursor is None else cursor,
      limit=not_given if limit is None else limit,
  )
  next_page_info = page.next_page_info()
  if next_page_info is None:
      next_request_options = None
  else:
      next_request_options = page._info_to_options(next_page_info).model_dump_json(
        exclude_unset=True,
        exclude={'post_parser'}
      )

  # We convert to JSON instead of letting PL/Python perform data mapping because PL/Python errors for
  # omitted fields instead of defaulting them to NULL, but we want to be more lenient, which we handle
  # in the calling function later.
  type_adapter = TypeAdapter(Any)
  return (
    type_adapter.dump_json(page._get_page_items(), exclude_unset=True).decode("utf-8"),
    next_request_options
  )
$$;

-- A simpler wrapper around `dedalus_machines_terminals._list_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines_terminals._list_first_page(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines_terminals._list_first_page_py(
      machine_id, cursor, "limit"
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals._list_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types.machines import Terminal
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=Terminal,
    page=SyncCursorPage[Terminal],
    options=FinalRequestOptions.construct(**json.loads(request_options))
  )
  next_page_info = page.next_page_info()
  if next_page_info is None:
      next_request_options = None
  else:
      next_request_options = page._info_to_options(next_page_info).model_dump_json(
        exclude_unset=True,
        exclude={'post_parser'}
      )

  # We convert to JSON instead of letting PL/Python perform data mapping because PL/Python errors for
  # omitted fields instead of defaulting them to NULL, but we want to be more lenient, which we handle
  # in the calling function later.
  type_adapter = TypeAdapter(Any)
  return (
    type_adapter.dump_json(page._get_page_items(), exclude_unset=True).decode("utf-8"),
    next_request_options
  )
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.list(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines_terminals.terminal
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines_terminals._list_first_page(
      machine_id, cursor, "limit"
    ) AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines_terminals._list_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines_terminals.terminal, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals._delete(
  machine_id TEXT, terminal_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.terminals.with_raw_response.delete(
      machine_id=machine_id,
      terminal_id=terminal_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_terminals.delete(
  machine_id TEXT, terminal_id TEXT
)
RETURNS dedalus_machines_terminals.terminal
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_terminals.terminal,
      dedalus_machines_terminals._delete(machine_id, terminal_id)
    );
  END;
$$;