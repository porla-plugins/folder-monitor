# A folder monitor for Porla

This plugin adds folder monitoring capabilities to Porla.

## Configuration

The plugin is configured directly in the Porla TOML config file.

```toml
[folder-monitor]
# A cron expression to set how often the monitored folders
# should be checked. This example means every 5 seconds.
cron = "*/5 * * * * *"
# Where folder monitor should store its database file.
db   = "/var/lib/porla/folder-monitor.db"

[[folder-monitor.dirs]]
extensions = [".torrent"]   # What file extensions are we monitoring?
path = "/home/viktor/watch" # The path to monitor
save_path = "/tmp"          # The save path for torrents
```
