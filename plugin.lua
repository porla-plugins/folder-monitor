-- our own code split into files
local History  = require "db.history"
local migrate  = require "db.migrate"

-- dependencies that porla provides
local config   = require "config"
local cron     = require "cron"
local fs       = require "fs"
local log      = require "log"
local sqlite3  = require "sqlite3"
local torrents = require "torrents"

-- small function to check if an array contains
-- a specific value
local function contains(array, value)
    for _, item in pairs(array) do
        if item == value then
            return true
        end
    end

    return false
end

local function check(db)
    local history = History:new{db = db}

    for _, directory in pairs(config.dirs) do
        if not fs.exists(directory.path) then
            goto next
        end

        local extensions = {".torrent"}

        if type(directory.extensions) == "table" then
            extensions = directory.extensions
        end

        if type(directory.extensions) == "string" then
            extensions = {directory.extensions}
        end

        for _, file in ipairs(fs.dir(directory.path)) do
            if not contains(extensions, fs.ext(file)) then
                goto next_entry
            end

            if history:contains(file) then
                goto next_entry
            end

            local file_handle = io.open(file, 'rb')
            local file_buffer = file_handle:read("*all")
            file_handle:close()

            if not file_buffer then
                goto next_entry
            end

            local params = {
                preset    = directory.preset,
                save_path = directory.save_path
            }

            -- no support for magnet links just yet
            if string.sub(file_buffer, 0, 7) == "magnet:" then
                log.info("File contents parsed as magnet URI")
                params.magnet_uri = file_buffer
            else
                local torrent = torrents.parse(file_buffer, 'buffer')

                if torrents.has(torrent) then
                    history:insert(file)
                    goto next_entry
                end

                params.ti = torrent
            end

            torrents.add(params)

            history:insert(file)

            ::next_entry::
        end

        ::next::
    end
end

local db = nil

function porla.init()
    if config == nil then
        log.warning("No folder-monitor config")
        return false
    end

    db = sqlite3.open(config.db)
    db:exec("PRAGMA journal_mode = WAL")

    if not migrate(db) then
        log.error("Failed to run migrations for folder-monitor")
        return false
    end

    cron_ref = cron.schedule({
        expression = config.cron,
        callback   = function()
            check(db)
        end
    })

    return true
end

function porla.destroy()
    if db ~= nil then
        db:close()
    end
end
