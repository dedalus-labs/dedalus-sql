ALTER TYPE dedalus_machines_artifacts.artifact
  ADD ATTRIBUTE artifact_id TEXT,
  ADD ATTRIBUTE created_at TIMESTAMP,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE name TEXT,
  ADD ATTRIBUTE size_bytes BIGINT,
  ADD ATTRIBUTE download_url TEXT,
  ADD ATTRIBUTE execution_id TEXT,
  ADD ATTRIBUTE expires_at TIMESTAMP,
  ADD ATTRIBUTE mime_type TEXT,
  ADD ATTRIBUTE sha256 TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts.make_artifact(
  artifact_id TEXT,
  created_at TIMESTAMP,
  machine_id TEXT,
  name TEXT,
  size_bytes BIGINT,
  download_url TEXT DEFAULT NULL,
  execution_id TEXT DEFAULT NULL,
  expires_at TIMESTAMP DEFAULT NULL,
  mime_type TEXT DEFAULT NULL,
  sha256 TEXT DEFAULT NULL
)
RETURNS dedalus_machines_artifacts.artifact
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    artifact_id,
    created_at,
    machine_id,
    name,
    size_bytes,
    download_url,
    execution_id,
    expires_at,
    mime_type,
    sha256
  )::dedalus_machines_artifacts.artifact;
$$;

ALTER TYPE dedalus_machines_artifacts.artifact_list
  ADD ATTRIBUTE items dedalus_machines_artifacts.artifact[],
  ADD ATTRIBUTE next_cursor TEXT;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts.make_artifact_list(
  items dedalus_machines_artifacts.artifact[] DEFAULT NULL,
  next_cursor TEXT DEFAULT NULL
)
RETURNS dedalus_machines_artifacts.artifact_list
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(items, next_cursor)::dedalus_machines_artifacts.artifact_list;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts._retrieve(
  machine_id TEXT, artifact_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  response = GD["__dedalus_context__"].client.machines.artifacts.with_raw_response.retrieve(
      machine_id=machine_id,
      artifact_id=artifact_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts.retrieve(
  machine_id TEXT, artifact_id TEXT
)
RETURNS dedalus_machines_artifacts.artifact
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_artifacts.artifact,
      dedalus_machines_artifacts._retrieve(machine_id, artifact_id)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts._list_first_page_py(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client.machines.artifacts.list(
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

-- A simpler wrapper around `dedalus_machines_artifacts._list_first_page` that ensures the global client is initialized.
CREATE OR REPLACE FUNCTION dedalus_machines_artifacts._list_first_page(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS dedalus_internal.page
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN dedalus_machines_artifacts._list_first_page_py(
      machine_id, cursor, "limit"
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts._list_next_page(request_options JSONB)
RETURNS dedalus_internal.page
LANGUAGE plpython3u
STABLE
AS $$
  import json
  from dedalus_sdk.types.machines import Artifact
  from dedalus_sdk.pagination import SyncCursorPage
  from dedalus_sdk._models import FinalRequestOptions
  from pydantic import TypeAdapter
  from typing import Any

  page = GD["__dedalus_context__"].client._request_api_list(
    model=Artifact,
    page=SyncCursorPage[Artifact],
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

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts.list(
  machine_id TEXT, cursor TEXT DEFAULT NULL, "limit" BIGINT DEFAULT NULL
)
RETURNS SETOF dedalus_machines_artifacts.artifact
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE paginated AS (
    SELECT page.*
    FROM dedalus_machines_artifacts._list_first_page(
      machine_id, cursor, "limit"
    ) AS page

    UNION ALL

    SELECT page.*
    FROM paginated
    CROSS JOIN dedalus_machines_artifacts._list_next_page(paginated.next_request_options) AS page
    WHERE paginated.next_request_options IS NOT NULL
  )
  SELECT (jsonb_populate_recordset(NULL::dedalus_machines_artifacts.artifact, data)).* FROM paginated;
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts._delete(
  machine_id TEXT, artifact_id TEXT
)
RETURNS JSONB
LANGUAGE plpython3u
AS $$
  response = GD["__dedalus_context__"].client.machines.artifacts.with_raw_response.delete(
      machine_id=machine_id,
      artifact_id=artifact_id,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_machines_artifacts.delete(
  machine_id TEXT, artifact_id TEXT
)
RETURNS dedalus_machines_artifacts.artifact
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_machines_artifacts.artifact,
      dedalus_machines_artifacts._delete(machine_id, artifact_id)
    );
  END;
$$;