-- our own code split into files
local history  = require "db.history"
local migrate  = require "db.migrate"

-- dependencies that porla provides
local config   = require "config"
local cron     = require "cron"
local fs       = require "fs"
local log      = require "log"
local sqlite   = require "sqlite"
local torrents = require "torrents"

local function check()
    for _, directory in pairs(cfg.dirs) do
        if not fs.exists(directory.path) then
            goto next
        end

        for _, file in ipairs(fs.dir(directory.path)) do
            if fs.ext(file) ~= ".torrent" then
                goto next_entry
            end

            if history.contains(db, file) then
                goto next_entry
            end

            local torrent = torrents.load(file)

            if torrents.has(torrent) then
                history.insert(db, file)
                goto next_entry
            end

            torrents.add({
                path    = directory.save_path,
                torrent = torrent
            })

            history.insert(db, file)

            ::next_entry::
        end

        ::next::
    end
end

function porla.init()
    cfg = config["folder-monitor"]

    if cfg == nil then
        log.warning("No folder-monitor config")
        return false
    end

    db = sqlite.open(cfg.db)
    db:exec("PRAGMA journal_mode = WAL")

    if not migrate(db) then
        log.error("Failed to run migrations for folder-monitor")
        return false
    end

    cron_ref = cron.schedule({
        expression = cfg.cron,
        callback   = check
    })

    return true
end
