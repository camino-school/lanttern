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

## Localization

We use [Gettext](https://hexdocs.pm/gettext/Gettext.html) for localization.

```bash
mix gettext.extract # to extract gettext() calls to .pot
mix gettext.merge priv/gettext # to update all locale-specific .po
```

Currently supported locales are `en` (default) and `pt_BR`.

## `git_hooks` issue

We need to run `mix git_hooks.install` before commiting for the first time.
See [this issue](https://github.com/qgadrian/elixir_git_hooks/issues/133)

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
- `OPENAI_MODEL`
- `OPENAI_COOLDOWN_MINUTES`

#### Others

- `PHX_HOST` - e.g. `lanttern.org`
- `SECRET_KEY_BASE` - Phoenix generated
- `CONTENT_SECURITY_POLICY` - CSP headers

## Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
