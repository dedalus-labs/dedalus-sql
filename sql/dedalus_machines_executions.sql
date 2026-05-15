ALTER TYPE dedalus_machines_executions.artifact_ref
  ADD ATTRIBUTE artifact_id TEXT, ADD ATTRIBUTE name TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_artifact_ref(
  artifact_id TEXT, name TEXT
)
RETURNS dedalus_machines_executions.artifact_ref
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(artifact_id, name)::dedalus_machines_executions.artifact_ref;
$$;

ALTER TYPE dedalus_machines_executions.execution
  ADD ATTRIBUTE created_at TIMESTAMP,
  ADD ATTRIBUTE execution_id TEXT,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE status TEXT,
  ADD ATTRIBUTE command TEXT[],
  ADD ATTRIBUTE artifacts dedalus_machines_executions.artifact_ref[],
  ADD ATTRIBUTE completed_at TIMESTAMP,
  ADD ATTRIBUTE cwd TEXT,
  ADD ATTRIBUTE env_keys TEXT[],
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT,
  ADD ATTRIBUTE exit_code BIGINT,
  ADD ATTRIBUTE expires_at TIMESTAMP,
  ADD ATTRIBUTE retry_after_ms BIGINT,
  ADD ATTRIBUTE signal BIGINT,
  ADD ATTRIBUTE started_at TIMESTAMP,
  ADD ATTRIBUTE stderr_bytes BIGINT,
  ADD ATTRIBUTE stderr_truncated BOOLEAN,
  ADD ATTRIBUTE stdout_bytes BIGINT,
  ADD ATTRIBUTE stdout_truncated BOOLEAN;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_execution(
  created_at TIMESTAMP,
  execution_id TEXT,
  machine_id TEXT,
  status TEXT,
  command TEXT[] DEFAULT NULL,
  artifacts dedalus_machines_executions.artifact_ref[] DEFAULT NULL,
  completed_at TIMESTAMP DEFAULT NULL,
  cwd TEXT DEFAULT NULL,
  env_keys TEXT[] DEFAULT NULL,
  error_code TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  exit_code BIGINT DEFAULT NULL,
  expires_at TIMESTAMP DEFAULT NULL,
  retry_after_ms BIGINT DEFAULT NULL,
  signal BIGINT DEFAULT NULL,
  started_at TIMESTAMP DEFAULT NULL,
  stderr_bytes BIGINT DEFAULT NULL,
  stderr_truncated BOOLEAN DEFAULT NULL,
  stdout_bytes BIGINT DEFAULT NULL,
  stdout_truncated BOOLEAN DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    created_at,
    execution_id,
    machine_id,
    status,
    command,
    artifacts,
    completed_at,
    cwd,
    env_keys,
    error_code,
    error_message,
    exit_code,
    expires_at,
    retry_after_ms,
    signal,
    started_at,
    stderr_bytes,
    stderr_truncated,
    stdout_bytes,
    stdout_truncated
  )::dedalus_machines_executions.execution;
$$;

ALTER TYPE dedalus_machines_executions.execution_create_params
  ADD ATTRIBUTE command TEXT[],
  ADD ATTRIBUTE cwd TEXT,
  ADD ATTRIBUTE env JSONB,
  ADD ATTRIBUTE stdin TEXT,
  ADD ATTRIBUTE timeout_ms BIGINT;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_execution_create_params(
  command TEXT[] DEFAULT NULL,
  cwd TEXT DEFAULT NULL,
  env JSONB DEFAULT NULL,
  stdin TEXT DEFAULT NULL,
  timeout_ms BIGINT DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution_create_params
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    command, cwd, env, stdin, timeout_ms
  )::dedalus_machines_executions.execution_create_params;
$$;

ALTER TYPE dedalus_machines_executions.execution_event
  ADD ATTRIBUTE at TIMESTAMP,
  ADD ATTRIBUTE sequence BIGINT,
  ADD ATTRIBUTE type TEXT,
  ADD ATTRIBUTE chunk TEXT,
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT,
  ADD ATTRIBUTE exit_code BIGINT,
  ADD ATTRIBUTE signal BIGINT,
  ADD ATTRIBUTE status TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_execution_event(
  at TIMESTAMP,
  sequence BIGINT,
  type TEXT,
  chunk TEXT DEFAULT NULL,
  error_code TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  exit_code BIGINT DEFAULT NULL,
  signal BIGINT DEFAULT NULL,
  status TEXT DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution_event
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    at,
    sequence,
    type,
    chunk,
    error_code,
    error_message,
    exit_code,
    signal,
    status
  )::dedalus_machines_executions.execution_event;
$$;

ALTER TYPE dedalus_machines_executions.execution_events
  ADD ATTRIBUTE items dedalus_machines_executions.execution_event[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_execution_events(
  items dedalus_machines_executions.execution_event[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution_events
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines_executions.execution_events;
$$;

ALTER TYPE dedalus_machines_executions.execution_list
  ADD ATTRIBUTE items dedalus_machines_executions.execution[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_execution_list(
  items dedalus_machines_executions.execution[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution_list
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines_executions.execution_list;
$$;

ALTER TYPE dedalus_machines_executions.execution_output
  ADD ATTRIBUTE execution_id TEXT,
  ADD ATTRIBUTE stderr TEXT,
  ADD ATTRIBUTE stderr_bytes BIGINT,
  ADD ATTRIBUTE stderr_truncated BOOLEAN,
  ADD ATTRIBUTE stdout TEXT,
  ADD ATTRIBUTE stdout_bytes BIGINT,
  ADD ATTRIBUTE stdout_truncated BOOLEAN;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.make_execution_output(
  execution_id TEXT,
  stderr TEXT DEFAULT NULL,
  stderr_bytes BIGINT DEFAULT NULL,
  stderr_truncated BOOLEAN DEFAULT NULL,
  stdout TEXT DEFAULT NULL,
  stdout_bytes BIGINT DEFAULT NULL,
  stdout_truncated BOOLEAN DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution_output
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    execution_id,
    stderr,
    stderr_bytes,
    stderr_truncated,
    stdout,
    stdout_bytes,
    stdout_truncated
  )::dedalus_machines_executions.execution_output;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._create(
  machine_id TEXT,
  command TEXT[] DEFAULT NULL,
  cwd TEXT DEFAULT NULL,
  env JSONB DEFAULT NULL,
  stdin TEXT DEFAULT NULL,
  timeout_ms BIGINT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  import json
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.machines.executions.with_raw_response.create(
      machine_id=machine_id,
      command=command,
      cwd=not_given if cwd is None else cwd,
      env=not_given if env is None else json.loads(env),
      stdin=not_given if stdin is None else stdin,
      timeout_ms=not_given if timeout_ms is None else timeout_ms,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.create(
  machine_id TEXT,
  command TEXT[] DEFAULT NULL,
  cwd TEXT DEFAULT NULL,
  env JSONB DEFAULT NULL,
  stdin TEXT DEFAULT NULL,
  timeout_ms BIGINT DEFAULT NULL
)
RETURNS dedalus_machines_executions.execution
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_executions.execution,
      dedalus_machines_executions._create(
        machine_id, command, cwd, env, stdin, timeout_ms
      )
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._retrieve(
  machine_id TEXT, execution_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.executions.with_raw_response.retrieve(
      machine_id=machine_id,
      execution_id=execution_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.retrieve(
  machine_id TEXT, execution_id TEXT
)
RETURNS dedalus_machines_executions.execution
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_executions.execution,
      dedalus_machines_executions._retrieve(machine_id, execution_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._list_first_page_py(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.executions.list(
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

-- A simpler wrapper around `dedalus_machines_executions._list_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines_executions._list_first_page(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines_executions._list_first_page_py(
      machine_id, cursor, "limit"
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._list_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types.machines import Execution
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=Execution,
    page=SyncCursorPage[Execution],
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

CREATE OR REPLACE FUNCTION dedalus_machines_executions.list(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines_executions.execution
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines_executions._list_first_page(
      machine_id, cursor, "limit"
    ) AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines_executions._list_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines_executions.execution, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._delete(
  machine_id TEXT, execution_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.executions.with_raw_response.delete(
      machine_id=machine_id,
      execution_id=execution_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.delete(
  machine_id TEXT, execution_id TEXT
)
RETURNS dedalus_machines_executions.execution
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_executions.execution,
      dedalus_machines_executions._delete(machine_id, execution_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._events_first_page_py(
  machine_id TEXT,
  execution_id TEXT,
  cursor TEXT DEFAULT NULL,
  "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.executions.events(
      machine_id=machine_id,
      execution_id=execution_id,
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

-- A simpler wrapper around `dedalus_machines_executions._events_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines_executions._events_first_page(
  machine_id TEXT,
  execution_id TEXT,
  cursor TEXT DEFAULT NULL,
  "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines_executions._events_first_page_py(
      machine_id, execution_id, cursor, "limit"
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._events_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types.machines import ExecutionEvent
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=ExecutionEvent,
    page=SyncCursorPage[ExecutionEvent],
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

CREATE OR REPLACE FUNCTION dedalus_machines_executions.events(
  machine_id TEXT,
  execution_id TEXT,
  cursor TEXT DEFAULT NULL,
  "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines_executions.execution_event
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines_executions._events_first_page(
      machine_id, execution_id, cursor, "limit"
    ) AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines_executions._events_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines_executions.execution_event, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions._output(
  machine_id TEXT, execution_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.executions.with_raw_response.output(
      machine_id=machine_id,
      execution_id=execution_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_executions.output(
  machine_id TEXT, execution_id TEXT
)
RETURNS dedalus_machines_executions.execution_output
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_executions.execution_output,
      dedalus_machines_executions._output(machine_id, execution_id)
    );
  END;
$$;