# Dedalus API PostgreSQL Extension

> [!NOTE]
>
> The Dedalus API PostgreSQL Extension is currently **experimental** and we're excited for you to experiment with it!
>
> This extension has not yet been exhaustively tested in production environments and may be missing some features you'd expect in a stable release. As we continue development, there may be breaking changes that require updates to your code.
>
> **We'd love your feedback!** Please share any suggestions, bug reports, feature requests, or general thoughts by [filing an issue](https://www.github.com/dedalus-labs/dedalus-sql/issues/new).

The Dedalus API PostgreSQL Extension provides convenient access to the [Dedalus REST API](https://docs.dedaluslabs.ai) from PostgreSQL.

It is generated with [Stainless](https://www.stainless.com/).

The REST API documentation can be found on [docs.dedaluslabs.ai](https://docs.dedaluslabs.ai).

## Installation

Clone the repository:

```sh
git clone git@github.com:dedalus-labs/dedalus-sql.git
cd dedalus-sql
```

Install the extension:

```sh
make install
```

Load it into the relevant database:

```sql
CREATE EXTENSION IF NOT EXISTS plpython3u; -- Dependency
CREATE EXTENSION dedalus;
```

And install the Python SDK dependency:

```sh
# install from PyPI
pip install dedalus-sdk
```

See [`./scripts/test`](./scripts/test) how to use a [Python virtual environment](https://docs.python.org/3/library/sys_path_init.html#sys-path-init-virtual-environments) if you prefer that instead.

Use [the troubleshooting section](#troubleshooting) if you encounter issues during or after installation.

## Requirements

This extension requires:

- PostgreSQL 14 or higher
- [PL/Python](https://www.postgresql.org/docs/current/plpython.html)
- Python 3.9 or higher
- The dedalus-sdk Python package

## Usage

```sql
SELECT *
FROM dedalus_usage.retrieve();
```

## Client configuration

Configure the client by setting configuration parameters at the database level:

```sql
ALTER DATABASE my_database SET dedalus.api_key = 'My API Key';
```

> [!NOTE]
>
> `ALTER DATABASE` persistently alters the database, but doesn't take effect until the next session. To
> ephemerally modify the current session, use `SET dedalus.api_key TO 'My API Key';`.

See this table for the available configuration parameters:

| Parameter           | Required | Default value                  |
| ------------------- | -------- | ------------------------------ |
| `dedalus.api_key`   | false    | -                              |
| `dedalus.x_api_key` | false    | -                              |
| `dedalus.org_id`    | false    | -                              |
| `dedalus.base_url`  | false    | `'https://dcs.dedaluslabs.ai'` |

## Requests and responses

To send a request to the Dedalus API, call the relevant SQL function with values corresponding to the parameter types and `SELECT` the columns you need from the returned rows.

## Pagination

For Dedalus API endpoints that return a paginated lists of results, the extension automatically fetches more pages as needed.

For example, the following query will make the minimum number of requests necessary to satisfy the `LIMIT`:

```sql
SELECT *
FROM dedalus_machines.list()
LIMIT 200;
```

> [!IMPORTANT]
>
> Place your `LIMIT` as close to the paginated function call as possible. If the `LIMIT` is too far
> removed, then PostgreSQL may not [push down the condition](https://wiki.postgresql.org/wiki/Inlining_of_SQL_functions),
> causing all pages to be requested and buffered.

## Caching

Sending requests to the Dedalus API for every SQL query can be slow. Combine [materialized views](https://www.postgresql.org/docs/current/rules-materializedviews.html) with [`pg_cron`](https://github.com/citusdata/pg_cron) for scheduled data pulls:

```sql
CREATE MATERIALIZED VIEW dedalus_machines_machine_list_items AS
SELECT *
FROM dedalus_machines.list();

-- Refresh the view every 4 hours.
SELECT cron.schedule(
  'refresh-dedalus-machines-machine-list-items',
  '0 */4 * * *',
  'REFRESH MATERIALIZED VIEW CONCURRENTLY dedalus_machines_machine_list_items'
);
```

## Troubleshooting

### Installation

If you encounter an error such as:

```
Operation not permitted
```

Then run with `sudo`. If necessary, ensure your terminal has full disk access.

If you encounter an error such as:

```
make: pg_config: Command not found
```

Then ensure you have `pg_config` installed and in your `PATH`. If necessary, tell `make` where to find it:

```sh
PG_CONFIG=/path/to/pg_config make install
```

To install the extension in a custom prefix on PostgreSQL 18 or later, pass the `prefix` argument:

```sh
make install prefix=/usr/local/extras
```

You must also ensure that the prefix is included in the following [`postgresql.conf` parameters](https://www.postgresql.org/docs/current/config-setting.html#CONFIG-SETTING-CONFIGURATION-FILE):

```conf
extension_control_path = '/usr/local/extras/postgresql/share:$system'
dynamic_library_path   = '/usr/local/extras/postgresql/lib:$libdir'
```

### Loading

If you encounter an error such as:

```
ERROR: could not load library
```

Then ensure your Python installation is linked to the directory where PostgreSQL was looking for it. You can print out the directory of your Python installation with this command:

```sh
python3 -c "import sys; print(sys.prefix)"
```

## Semantic versioning

This package generally follows [SemVer](https://semver.org/spec/v2.0.0.html) conventions, though certain backwards-incompatible changes may be released as minor versions:

1. Changes to library internals which are technically public but not intended or documented for external use. _(Please open a GitHub issue to let us know if you are relying on such internals.)_
2. Changes that we do not expect to impact the vast majority of users in practice.

We take backwards-compatibility seriously and work hard to ensure you can rely on a smooth upgrade experience.

We are keen for your feedback; please open an [issue](https://www.github.com/dedalus-labs/dedalus-sql/issues) with questions, bugs, or suggestions.
