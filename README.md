# A folder monitor for Porla

This plugin adds folder monitoring capabilities to Porla.

## Configuration

The plugin is configured with Lua. The following is an overview of all the
parameters you can use.

```lua
return {
  cron = "*/5 * * * * *",
  db   = __state_dir.."/folder-monitor.db",
  dirs = {
    {
      extensions = {".torrent"},
      path       = "/home/viktor/watch",
      save_path  = "/tmp"
    }
  }
}
```
