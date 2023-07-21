# A folder monitor for Porla

This plugin adds folder monitoring capabilities to Porla. It can filter files
based on extension.

If the contents of a matched file starts with `magnet:` that file will be
treated as a magnet link in a file, and added as such.

## Configuration

The plugin is configured with Lua. The following is an example Lua
configuration that you can adjust to your needs and then paste in the plugin
configuration field in Porla.

```lua
return {
  cron = "*/5 * * * * *",
  db   = __state_dir.."/folder-monitor.db",
  dirs = {
    {
      extensions = {".magnet", ".torrent"},
      path       = "/home/viktor/watch",
      preset     = "default",
      save_path  = "/tmp"
    }
  }
}
```

### `cron`

The cron schedule to use when monitor folders. All monitored folders share this
schedule and are checked at the same time.

### `db`

Path to the database where the folder monitor will store its state. The file
will be created if it does not exist. Can be set to `:memory:` to use a SQLite
in-memory database.

### `dirs`

This is an array of tables where each item represents a folder to monitor.

| Property | Description |
|----------|-------------|
| `extensions` | An array of strings that contains the extensions to allow. |
| `path` | The path to the folder that this item monitors. |
| `preset` | A Porla preset to apply to this torrent when adding it. |
| `save_path` | The save path to set for this torrent. |
