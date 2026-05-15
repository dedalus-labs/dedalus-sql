ALTER TYPE dedalus_machines_ssh.ssh_connection
  ADD ATTRIBUTE endpoint TEXT,
  ADD ATTRIBUTE port BIGINT,
  ADD ATTRIBUTE ssh_username TEXT,
  ADD ATTRIBUTE host_trust dedalus_machines_ssh.ssh_host_trust,
  ADD ATTRIBUTE user_certificate TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.make_ssh_connection(
  endpoint TEXT,
  port BIGINT,
  ssh_username TEXT,
  host_trust dedalus_machines_ssh.ssh_host_trust DEFAULT NULL,
  user_certificate TEXT DEFAULT NULL
)
RETURNS dedalus_machines_ssh.ssh_connection
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    endpoint, port, ssh_username, host_trust, user_certificate
  )::dedalus_machines_ssh.ssh_connection;
$$;

ALTER TYPE dedalus_machines_ssh.ssh_host_trust
  ADD ATTRIBUTE host_pattern TEXT,
  ADD ATTRIBUTE kind TEXT,
  ADD ATTRIBUTE public_key TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.make_ssh_host_trust(
  host_pattern TEXT, kind TEXT, public_key TEXT
)
RETURNS dedalus_machines_ssh.ssh_host_trust
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    host_pattern, kind, public_key
  )::dedalus_machines_ssh.ssh_host_trust;
$$;

ALTER TYPE dedalus_machines_ssh.ssh_session
  ADD ATTRIBUTE created_at TIMESTAMP,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE session_id TEXT,
  ADD ATTRIBUTE status TEXT,
  ADD ATTRIBUTE connection dedalus_machines_ssh.ssh_connection,
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT,
  ADD ATTRIBUTE expires_at TIMESTAMP,
  ADD ATTRIBUTE ready_at TIMESTAMP,
  ADD ATTRIBUTE retry_after_ms BIGINT;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.make_ssh_session(
  created_at TIMESTAMP,
  machine_id TEXT,
  session_id TEXT,
  status TEXT,
  connection dedalus_machines_ssh.ssh_connection DEFAULT NULL,
  error_code TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  expires_at TIMESTAMP DEFAULT NULL,
  ready_at TIMESTAMP DEFAULT NULL,
  retry_after_ms BIGINT DEFAULT NULL
)
RETURNS dedalus_machines_ssh.ssh_session
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    created_at,
    machine_id,
    session_id,
    status,
    connection,
    error_code,
    error_message,
    expires_at,
    ready_at,
    retry_after_ms
  )::dedalus_machines_ssh.ssh_session;
$$;

ALTER TYPE dedalus_machines_ssh.ssh_session_create_params
  ADD ATTRIBUTE public_key TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.make_ssh_session_create_params(
  public_key TEXT
)
RETURNS dedalus_machines_ssh.ssh_session_create_params
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(public_key)::dedalus_machines_ssh.ssh_session_create_params;
$$;

ALTER TYPE dedalus_machines_ssh.ssh_session_list
  ADD ATTRIBUTE items dedalus_machines_ssh.ssh_session[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.make_ssh_session_list(
  items dedalus_machines_ssh.ssh_session[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines_ssh.ssh_session_list
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines_ssh.ssh_session_list;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh._create(
  machine_id TEXT, public_key TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.ssh.with_raw_response.create(
      machine_id=machine_id,
      public_key=public_key,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.create(
  machine_id TEXT, public_key TEXT
)
RETURNS dedalus_machines_ssh.ssh_session
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_ssh.ssh_session,
      dedalus_machines_ssh._create(machine_id, public_key)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh._retrieve(
  machine_id TEXT, session_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.ssh.with_raw_response.retrieve(
      machine_id=machine_id,
      session_id=session_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.retrieve(
  machine_id TEXT, session_id TEXT
)
RETURNS dedalus_machines_ssh.ssh_session
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_ssh.ssh_session,
      dedalus_machines_ssh._retrieve(machine_id, session_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh._list_first_page_py(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.ssh.list(
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

-- A simpler wrapper around `dedalus_machines_ssh._list_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines_ssh._list_first_page(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines_ssh._list_first_page_py(
      machine_id, cursor, "limit"
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh._list_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types.machines import SSHSession
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=SSHSession,
    page=SyncCursorPage[SSHSession],
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

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.list(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines_ssh.ssh_session
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines_ssh._list_first_page(
      machine_id, cursor, "limit"
    ) AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines_ssh._list_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines_ssh.ssh_session, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh._delete(
  machine_id TEXT, session_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.ssh.with_raw_response.delete(
      machine_id=machine_id,
      session_id=session_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_ssh.delete(
  machine_id TEXT, session_id TEXT
)
RETURNS dedalus_machines_ssh.ssh_session
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_ssh.ssh_session,
      dedalus_machines_ssh._delete(machine_id, session_id)
    );
  END;
$$;