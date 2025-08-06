# Lanttern

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- `source .env`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## `.env` expected variables

```bash
export GOOGLE_CLIENT_ID="********"
export ROOT_ADMIN_EMAIL="some.email@example.com"
```

### To enable automatic environment reloading, you can

1. Install `direnv`

2. Add the following configuration to your shell configuration file (`~/.bashrc` or `~/.bash_profile`):

```bash
eval "$(direnv hook bash)"
```

3. Create a `.envrc` file in the root of your project. Copy the same information from your `.env` file into `.envrc`. This allows the environment variables to be loaded automatically, without needing to run `source .env`.

4. Allow direnv to load the .envrc file by running:

```bash
direnv allow
```

## Localization

We use [Gettext](https://hexdocs.pm/gettext/Gettext.html) for localization.

```bash
mix gettext.extract # to extract gettext() calls to .pot
mix gettext.merge priv/gettext # to update all locale-specific .po
```

Currently supported locales are `en` (default) and `pt_BR`.

## Deployment

We're currently running Lanttern on [fly.io](https://fly.io), connected to a managed [Supabase](https://supabase.com/) Postgresql database, and we use [GitHub Actions](https://docs.github.com/en/actions) for automation.

The main secrets/env vars that we need for this are the following:

### On GitHub

- `FLY_API_TOKEN` for each **environment**

### On fly.io

#### Supabase

- `DATABASE_HOST` - used in repo's `ssl_opts` `server_name_indication`
- `DATABASE_SSL_CERT` - using `\n` string for line breaks
- `DATABASE_URL`
- `SUPABASE_PROJECT_API_KEY` - used for Supabase client (interface with Storage)
- `SUPABASE_PROJECT_URL` - also used for Supabase client (interface with Storage)

#### Google

- `GOOGLE_CLIENT_ID`

#### OpenAI

- `OPENAI_API_KEY`
- `OPENAI_ORGANIZATION_KEY`

#### Others

- `PHX_HOST` - e.g. `lanttern.org`
- `SECRET_KEY_BASE` - Phoenix generated
- `CONTENT_SECURITY_POLICY` - CSP headers

## Tests

### Coverage

The default behavior when test with `mix test` is to run with coverage.
To configure the minimum coverage percentage, ignored files, and terminal output,
use the `coveralls.json` file. To generate a coverage report, run `mix coveralls.html`
and view it in the `cover/` folder. Source: [excoveralls](https://github.com/parroty/excoveralls)

### Tips

To investigate the perfomance process run `mix test --slowest 10`

## Restoring a PostgreSQL Backup

### Requirements

- A backup file: `FILENAME.sql`
- PostgreSQL client installed  

### Create/Recreate the Database

Drop and recreate the target database:

```bash
PGPASSWORD=postgres psql -h localhost -U postgres -d postgres -c "DROP DATABASE IF EXISTS lanttern_dev;"
PGPASSWORD=postgres psql -h localhost -U postgres -d postgres -c "CREATE DATABASE lanttern_dev;"
```

### Install Required Extensions

Before restoring the database, make sure the required PostgreSQL extensions are installed:

```bash
PGPASSWORD=postgres psql -h localhost -U postgres -d lanttern_dev -c "CREATE EXTENSION IF NOT EXISTS citext;"
PGPASSWORD=postgres psql -h localhost -U postgres -d lanttern_dev -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
```

### Restore the Backup

`PGPASSWORD=postgres psql --set ON_ERROR_STOP=on -h localhost -U postgres lanttern_dev < <FILENAME>.sql`

## Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
