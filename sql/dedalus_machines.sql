ALTER TYPE dedalus_machines.create_params
  ADD ATTRIBUTE memory_mib BIGINT,
  ADD ATTRIBUTE storage_gib BIGINT,
  ADD ATTRIBUTE vcpu DOUBLE PRECISION,
  ADD ATTRIBUTE autosleep TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines.make_create_params(
  memory_mib BIGINT,
  storage_gib BIGINT,
  vcpu DOUBLE PRECISION,
  autosleep TEXT DEFAULT NULL
)
RETURNS dedalus_machines.create_params
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    memory_mib, storage_gib, vcpu, autosleep
  )::dedalus_machines.create_params;
$$;

ALTER TYPE dedalus_machines.lifecycle_status
  ADD ATTRIBUTE last_progress_at TIMESTAMP,
  ADD ATTRIBUTE last_transition_at TIMESTAMP,
  ADD ATTRIBUTE phase TEXT,
  ADD ATTRIBUTE reason TEXT,
  ADD ATTRIBUTE retryable BOOLEAN,
  ADD ATTRIBUTE revision TEXT,
  ADD ATTRIBUTE last_error TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines.make_lifecycle_status(
  last_progress_at TIMESTAMP,
  last_transition_at TIMESTAMP,
  phase TEXT,
  reason TEXT,
  retryable BOOLEAN,
  revision TEXT,
  last_error TEXT DEFAULT NULL
)
RETURNS dedalus_machines.lifecycle_status
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    last_progress_at,
    last_transition_at,
    phase,
    reason,
    retryable,
    revision,
    last_error
  )::dedalus_machines.lifecycle_status;
$$;

ALTER TYPE dedalus_machines.machine
  ADD ATTRIBUTE autosleep_seconds BIGINT,
  ADD ATTRIBUTE desired_state TEXT,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE memory_mib BIGINT,
  ADD ATTRIBUTE status dedalus_machines.lifecycle_status,
  ADD ATTRIBUTE storage_gib BIGINT,
  ADD ATTRIBUTE vcpu DOUBLE PRECISION;

CREATE OR REPLACE FUNCTION dedalus_machines.make_machine(
  autosleep_seconds BIGINT,
  desired_state TEXT,
  machine_id TEXT,
  memory_mib BIGINT,
  status dedalus_machines.lifecycle_status,
  storage_gib BIGINT,
  vcpu DOUBLE PRECISION
)
RETURNS dedalus_machines.machine
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    autosleep_seconds,
    desired_state,
    machine_id,
    memory_mib,
    status,
    storage_gib,
    vcpu
  )::dedalus_machines.machine;
$$;

ALTER TYPE dedalus_machines.machine_list
  ADD ATTRIBUTE items dedalus_machines.machine_list_item[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines.make_machine_list(
  items dedalus_machines.machine_list_item[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines.machine_list
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines.machine_list;
$$;

ALTER TYPE dedalus_machines.machine_list_item
  ADD ATTRIBUTE autosleep_seconds BIGINT,
  ADD ATTRIBUTE created_at TIMESTAMP,
  ADD ATTRIBUTE desired_state TEXT,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE memory_mib BIGINT,
  ADD ATTRIBUTE status dedalus_machines.lifecycle_status,
  ADD ATTRIBUTE storage_gib BIGINT,
  ADD ATTRIBUTE vcpu DOUBLE PRECISION;

CREATE OR REPLACE FUNCTION dedalus_machines.make_machine_list_item(
  autosleep_seconds BIGINT,
  created_at TIMESTAMP,
  desired_state TEXT,
  machine_id TEXT,
  memory_mib BIGINT,
  status dedalus_machines.lifecycle_status,
  storage_gib BIGINT,
  vcpu DOUBLE PRECISION
)
RETURNS dedalus_machines.machine_list_item
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    autosleep_seconds,
    created_at,
    desired_state,
    machine_id,
    memory_mib,
    status,
    storage_gib,
    vcpu
  )::dedalus_machines.machine_list_item;
$$;

ALTER TYPE dedalus_machines.update_params
  ADD ATTRIBUTE autosleep TEXT,
  ADD ATTRIBUTE memory_mib BIGINT,
  ADD ATTRIBUTE storage_gib BIGINT,
  ADD ATTRIBUTE vcpu DOUBLE PRECISION;

CREATE OR REPLACE FUNCTION dedalus_machines.make_update_params(
  autosleep TEXT DEFAULT NULL,
  memory_mib BIGINT DEFAULT NULL,
  storage_gib BIGINT DEFAULT NULL,
  vcpu DOUBLE PRECISION DEFAULT NULL
)
RETURNS dedalus_machines.update_params
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    autosleep, memory_mib, storage_gib, vcpu
  )::dedalus_machines.update_params;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._create(
  memory_mib BIGINT,
  storage_gib BIGINT,
  vcpu DOUBLE PRECISION,
  autosleep TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.machines.with_raw_response.create(
      memory_mib=memory_mib,
      storage_gib=storage_gib,
      vcpu=vcpu,
      autosleep=not_given if autosleep is None else autosleep,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.create(
  memory_mib BIGINT,
  storage_gib BIGINT,
  vcpu DOUBLE PRECISION,
  autosleep TEXT DEFAULT NULL
)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine,
      dedalus_machines._create(memory_mib, storage_gib, vcpu, autosleep)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._retrieve(machine_id TEXT)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.with_raw_response.retrieve(
      machine_id=machine_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.retrieve(machine_id TEXT)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine, dedalus_machines._retrieve(machine_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._update(
  machine_id TEXT,
  autosleep TEXT DEFAULT NULL,
  memory_mib BIGINT DEFAULT NULL,
  storage_gib BIGINT DEFAULT NULL,
  vcpu DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.machines.with_raw_response.update(
      machine_id=machine_id,
      autosleep=not_given if autosleep is None else autosleep,
      memory_mib=not_given if memory_mib is None else memory_mib,
      storage_gib=not_given if storage_gib is None else storage_gib,
      vcpu=not_given if vcpu is None else vcpu,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.update(
  machine_id TEXT,
  autosleep TEXT DEFAULT NULL,
  memory_mib BIGINT DEFAULT NULL,
  storage_gib BIGINT DEFAULT NULL,
  vcpu DOUBLE PRECISION DEFAULT NULL
)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine,
      dedalus_machines._update(
        machine_id, autosleep, memory_mib, storage_gib, vcpu
      )
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._list_first_page_py(
  cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.list(
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

-- A simpler wrapper around `dedalus_machines._list_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines._list_first_page(
  cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines._list_first_page_py(cursor, "limit");
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._list_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types import MachineListItem
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=MachineListItem,
    page=SyncCursorPage[MachineListItem],
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

CREATE OR REPLACE FUNCTION dedalus_machines.list(
  cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines.machine_list_item
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines._list_first_page(cursor, "limit") AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines._list_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines.machine_list_item, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._delete(machine_id TEXT)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.with_raw_response.delete(
      machine_id=machine_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.delete(machine_id TEXT)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine, dedalus_machines._delete(machine_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._sleep(machine_id TEXT)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.with_raw_response.sleep(
      machine_id=machine_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.sleep(machine_id TEXT)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine, dedalus_machines._sleep(machine_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._wake(machine_id TEXT)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.with_raw_response.wake(
      machine_id=machine_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.wake(machine_id TEXT)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine, dedalus_machines._wake(machine_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines._watch(
  machine_id TEXT, last_event_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.machines.with_raw_response.watch(
      machine_id=machine_id,
      last_event_id=not_given if last_event_id is None else last_event_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines.watch(
  machine_id TEXT, last_event_id TEXT DEFAULT NULL
)
RETURNS dedalus_machines.machine
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines.machine,
      dedalus_machines._watch(machine_id, last_event_id)
    );
  END;
$$;