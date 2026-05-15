ALTER TYPE dedalus_usage.machine_compute_usage
  ADD ATTRIBUTE granularity TEXT,
  ADD ATTRIBUTE period_end TIMESTAMP,
  ADD ATTRIBUTE period_start TIMESTAMP,
  ADD ATTRIBUTE rows dedalus_usage.machine_compute_usage_row[];

CREATE OR REPLACE FUNCTION dedalus_usage.make_machine_compute_usage(
  granularity TEXT,
  period_end TIMESTAMP,
  period_start TIMESTAMP,
  rows dedalus_usage.machine_compute_usage_row[] DEFAULT NULL
)
RETURNS dedalus_usage.machine_compute_usage
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    granularity, period_end, period_start, rows
  )::dedalus_usage.machine_compute_usage;
$$;

ALTER TYPE dedalus_usage.machine_compute_usage_row
  ADD ATTRIBUTE awake_seconds BIGINT,
  ADD ATTRIBUTE bucket_end TIMESTAMP,
  ADD ATTRIBUTE bucket_start TIMESTAMP,
  ADD ATTRIBUTE cpu_millicore_seconds BIGINT,
  ADD ATTRIBUTE last_window_end TIMESTAMP,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE memory_mib_seconds BIGINT,
  ADD ATTRIBUTE requested_memory_mib INTEGER,
  ADD ATTRIBUTE requested_storage_gib INTEGER,
  ADD ATTRIBUTE requested_vcpu DOUBLE PRECISION,
  ADD ATTRIBUTE spec_fingerprint TEXT,
  ADD ATTRIBUTE window_count BIGINT,
  ADD ATTRIBUTE org_metering_bucket_ids TEXT[],
  ADD ATTRIBUTE stripe_cpu_identifiers TEXT[],
  ADD ATTRIBUTE stripe_memory_identifiers TEXT[],
  ADD ATTRIBUTE latest_stripe_emitted_at TIMESTAMP;

CREATE OR REPLACE FUNCTION dedalus_usage.make_machine_compute_usage_row(
  awake_seconds BIGINT,
  bucket_end TIMESTAMP,
  bucket_start TIMESTAMP,
  cpu_millicore_seconds BIGINT,
  last_window_end TIMESTAMP,
  machine_id TEXT,
  memory_mib_seconds BIGINT,
  requested_memory_mib INTEGER,
  requested_storage_gib INTEGER,
  requested_vcpu DOUBLE PRECISION,
  spec_fingerprint TEXT,
  window_count BIGINT,
  org_metering_bucket_ids TEXT[] DEFAULT NULL,
  stripe_cpu_identifiers TEXT[] DEFAULT NULL,
  stripe_memory_identifiers TEXT[] DEFAULT NULL,
  latest_stripe_emitted_at TIMESTAMP DEFAULT NULL
)
RETURNS dedalus_usage.machine_compute_usage_row
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    awake_seconds,
    bucket_end,
    bucket_start,
    cpu_millicore_seconds,
    last_window_end,
    machine_id,
    memory_mib_seconds,
    requested_memory_mib,
    requested_storage_gib,
    requested_vcpu,
    spec_fingerprint,
    window_count,
    org_metering_bucket_ids,
    stripe_cpu_identifiers,
    stripe_memory_identifiers,
    latest_stripe_emitted_at
  )::dedalus_usage.machine_compute_usage_row;
$$;

ALTER TYPE dedalus_usage.machine_storage_usage
  ADD ATTRIBUTE period_end TIMESTAMP,
  ADD ATTRIBUTE period_start TIMESTAMP,
  ADD ATTRIBUTE rows dedalus_usage.machine_storage_usage_row[];

CREATE OR REPLACE FUNCTION dedalus_usage.make_machine_storage_usage(
  period_end TIMESTAMP,
  period_start TIMESTAMP,
  rows dedalus_usage.machine_storage_usage_row[] DEFAULT NULL
)
RETURNS dedalus_usage.machine_storage_usage
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    period_end, period_start, rows
  )::dedalus_usage.machine_storage_usage;
$$;

ALTER TYPE dedalus_usage.machine_storage_usage_row
  ADD ATTRIBUTE bucket_end TIMESTAMP,
  ADD ATTRIBUTE bucket_start TIMESTAMP,
  ADD ATTRIBUTE logical_storage_bytes BIGINT,
  ADD ATTRIBUTE machine_id TEXT,
  ADD ATTRIBUTE org_metering_bucket_id TEXT,
  ADD ATTRIBUTE storage_mib_seconds BIGINT,
  ADD ATTRIBUTE stripe_storage_identifier TEXT,
  ADD ATTRIBUTE latest_stripe_emitted_at TIMESTAMP;

CREATE OR REPLACE FUNCTION dedalus_usage.make_machine_storage_usage_row(
  bucket_end TIMESTAMP,
  bucket_start TIMESTAMP,
  logical_storage_bytes BIGINT,
  machine_id TEXT,
  org_metering_bucket_id TEXT,
  storage_mib_seconds BIGINT,
  stripe_storage_identifier TEXT,
  latest_stripe_emitted_at TIMESTAMP DEFAULT NULL
)
RETURNS dedalus_usage.machine_storage_usage_row
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    bucket_end,
    bucket_start,
    logical_storage_bytes,
    machine_id,
    org_metering_bucket_id,
    storage_mib_seconds,
    stripe_storage_identifier,
    latest_stripe_emitted_at
  )::dedalus_usage.machine_storage_usage_row;
$$;

ALTER TYPE dedalus_usage.org_usage
  ADD ATTRIBUTE billed_awake_seconds BIGINT,
  ADD ATTRIBUTE billed_cpu_millicore_seconds BIGINT,
  ADD ATTRIBUTE billed_logical_storage_mib_seconds BIGINT,
  ADD ATTRIBUTE billed_memory_mib_seconds BIGINT,
  ADD ATTRIBUTE included_storage_gib BIGINT,
  ADD ATTRIBUTE plan_slug TEXT,
  ADD ATTRIBUTE provisioned_storage_gib BIGINT;

CREATE OR REPLACE FUNCTION dedalus_usage.make_org_usage(
  billed_awake_seconds BIGINT,
  billed_cpu_millicore_seconds BIGINT,
  billed_logical_storage_mib_seconds BIGINT,
  billed_memory_mib_seconds BIGINT,
  included_storage_gib BIGINT,
  plan_slug TEXT,
  provisioned_storage_gib BIGINT
)
RETURNS dedalus_usage.org_usage
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT ROW(
    billed_awake_seconds,
    billed_cpu_millicore_seconds,
    billed_logical_storage_mib_seconds,
    billed_memory_mib_seconds,
    included_storage_gib,
    plan_slug,
    provisioned_storage_gib
  )::dedalus_usage.org_usage;
$$;

CREATE OR REPLACE FUNCTION dedalus_usage._retrieve(
  period_start TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.usage.with_raw_response.retrieve(
      period_start=not_given if period_start is None else period_start,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_usage.retrieve(
  period_start TEXT DEFAULT NULL
)
RETURNS dedalus_usage.org_usage
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_usage.org_usage, dedalus_usage._retrieve(period_start)
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_usage._machine_compute(
  granularity TEXT DEFAULT NULL,
  machine_id TEXT DEFAULT NULL,
  period_end TEXT DEFAULT NULL,
  period_start TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.usage.with_raw_response.machine_compute(
      granularity=not_given if granularity is None else granularity,
      machine_id=not_given if machine_id is None else machine_id,
      period_end=not_given if period_end is None else period_end,
      period_start=not_given if period_start is None else period_start,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_usage.machine_compute(
  granularity TEXT DEFAULT NULL,
  machine_id TEXT DEFAULT NULL,
  period_end TEXT DEFAULT NULL,
  period_start TEXT DEFAULT NULL
)
RETURNS dedalus_usage.machine_compute_usage
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_usage.machine_compute_usage,
      dedalus_usage._machine_compute(
        granularity, machine_id, period_end, period_start
      )
    );
  END;
$$;

CREATE OR REPLACE FUNCTION dedalus_usage._machine_storage(
  machine_id TEXT DEFAULT NULL,
  period_end TEXT DEFAULT NULL,
  period_start TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpython3u
STABLE
AS $$
  from dedalus_sdk._types import not_given

  response = GD["__dedalus_context__"].client.usage.with_raw_response.machine_storage(
      machine_id=not_given if machine_id is None else machine_id,
      period_end=not_given if period_end is None else period_end,
      period_start=not_given if period_start is None else period_start,
  )

  # We don't parse the JSON and let PL/Python perform data mapping because PL/Python errors for omitted
  # fields instead of defaulting them to NULL, but we want to be more lenient, which we handle in the
  # caller later.
  return response.text()
$$;

CREATE OR REPLACE FUNCTION dedalus_usage.machine_storage(
  machine_id TEXT DEFAULT NULL,
  period_end TEXT DEFAULT NULL,
  period_start TEXT DEFAULT NULL
)
RETURNS dedalus_usage.machine_storage_usage
LANGUAGE plpgsql
STABLE
AS $$
  BEGIN
    PERFORM dedalus_internal.ensure_context();
    RETURN jsonb_populate_record(
      NULL::dedalus_usage.machine_storage_usage,
      dedalus_usage._machine_storage(machine_id, period_end, period_start)
    );
  END;
$$;