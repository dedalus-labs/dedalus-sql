ALTER TYPE dedalus_machines_previews.preview
  ADD ATTRIBUTE created_at TIMESTAMP,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE port BIGINT,
  ADD ATTRIBUTE preview_id TEXT,
  ADD ATTRIBUTE status TEXT,
  ADD ATTRIBUTE visibility TEXT,
  ADD ATTRIBUTE error_code TEXT,
  ADD ATTRIBUTE error_message TEXT,
  ADD ATTRIBUTE expires_at TIMESTAMP,
  ADD ATTRIBUTE protocol TEXT,
  ADD ATTRIBUTE ready_at TIMESTAMP,
  ADD ATTRIBUTE retry_after_ms BIGINT,
  ADD ATTRIBUTE url TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_previews.make_preview(
  created_at TIMESTAMP,
  machine_id TEXT,
  port BIGINT,
  preview_id TEXT,
  status TEXT,
  visibility TEXT,
  error_code TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  expires_at TIMESTAMP DEFAULT NULL,
  protocol TEXT DEFAULT NULL,
  ready_at TIMESTAMP DEFAULT NULL,
  retry_after_ms BIGINT DEFAULT NULL,
  url TEXT DEFAULT NULL
)
RETURNS dedalus_machines_previews.preview
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    created_at,
    machine_id,
    port,
    preview_id,
    status,
    visibility,
    error_code,
    error_message,
    expires_at,
    protocol,
    ready_at,
    retry_after_ms,
    url
  )::dedalus_machines_previews.preview;
$$;

ALTER TYPE dedalus_machines_previews.preview_create_params
  ADD ATTRIBUTE port BIGINT,
  ADD ATTRIBUTE protocol TEXT,
  ADD ATTRIBUTE visibility TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_previews.make_preview_create_params(
  port BIGINT, protocol TEXT DEFAULT NULL, visibility TEXT DEFAULT NULL
)
RETURNS dedalus_machines_previews.preview_create_params
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    port, protocol, visibility
  )::dedalus_machines_previews.preview_create_params;
$$;

ALTER TYPE dedalus_machines_previews.preview_list
  ADD ATTRIBUTE items dedalus_machines_previews.preview[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_previews.make_preview_list(
  items dedalus_machines_previews.preview[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines_previews.preview_list
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines_previews.preview_list;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews._create(
  machine_id TEXT,
  port BIGINT,
  protocol TEXT DEFAULT NULL,
  visibility TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.machines.previews.with_raw_response.create(
      machine_id=machine_id,
      port=port,
      protocol=not_given if protocol is None else protocol,
      visibility=not_given if visibility is None else visibility,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews.create(
  machine_id TEXT,
  port BIGINT,
  protocol TEXT DEFAULT NULL,
  visibility TEXT DEFAULT NULL
)
RETURNS dedalus_machines_previews.preview
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_previews.preview,
      dedalus_machines_previews._create(machine_id, port, protocol, visibility)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews._retrieve(
  machine_id TEXT, preview_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.previews.with_raw_response.retrieve(
      machine_id=machine_id,
      preview_id=preview_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews.retrieve(
  machine_id TEXT, preview_id TEXT
)
RETURNS dedalus_machines_previews.preview
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_previews.preview,
      dedalus_machines_previews._retrieve(machine_id, preview_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews._list_first_page_py(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.previews.list(
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

-- A simpler wrapper around `dedalus_machines_previews._list_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines_previews._list_first_page(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines_previews._list_first_page_py(
      machine_id, cursor, "limit"
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews._list_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types.machines import Preview
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=Preview,
    page=SyncCursorPage[Preview],
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

CREATE OR REPLACE FUNCTION dedalus_machines_previews.list(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines_previews.preview
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines_previews._list_first_page(
      machine_id, cursor, "limit"
    ) AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines_previews._list_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines_previews.preview, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews._delete(
  machine_id TEXT, preview_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.previews.with_raw_response.delete(
      machine_id=machine_id,
      preview_id=preview_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_previews.delete(
  machine_id TEXT, preview_id TEXT
)
RETURNS dedalus_machines_previews.preview
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_previews.preview,
      dedalus_machines_previews._delete(machine_id, preview_id)
    );
  END;
$$;