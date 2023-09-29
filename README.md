# Lanttern

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- `source .env`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## `.env` expected variables

```
export GOOGLE_CLIENT_ID="********"
export ROOT_ADMIN_EMAIL="some.email@example.com"
```

## `git_hooks` issue

We need to run `mix git_hooks.install` before commiting for the first time.
See [this issue](https://github.com/qgadrian/elixir_git_hooks/issues/133)

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
