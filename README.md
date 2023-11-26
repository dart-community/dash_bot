## Under construction

A Discord bot with useful utilities for the
[`dart_community` Discord server][discord].

## Features

### `/ping`

The `ping` command checks the bot is online and displays some latency
metrics.

### `/show-lint`

The `show-lint` command displays information about a given linter rule from
https://dart.dev/tools/linter-rules.

### Dartdoc search

`dash_bot` will parse messages for references to API elements or packages from
https://pub.dev and provide a link to that element.

Searches can be embedded in any text message and their syntax is as follows:
- `![Name]` or `![package/Name]`: Return the documentation for `Name` in
  Flutter's or `package`'s API documentation.
- `?[Name]` or `?[package/Name]`: Search for `Name` in Flutter's or
  `package`'s API documentation.
- `\$[name]`: Return the pub.dev page for the package `name`.
- `&[name]`: Search pub.dev for `name`.

## Running dash_bot

If you can use `dart:mirrors` (i.e during development), simply set the `TOKEN`
environment variable to your bot's token and run `bin/dash_bot.dart`. You can
also optionally set the `PREFIX` environment variable to enable running the
bot's command using messages like `!ping` instead of Discord's slash commands.

To create an executable, run
`dart run nyxx_commands:compile -o bin/dash_bot.g.dart bin/dash_bot.dart`. This
will create an executable at `bin/dash_bot.g.exe` which you can run after
setting the same environment variables as above.


[discord]: https://dartcommunity.dev/discord
