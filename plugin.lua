-- our own code split into files
local History  = require "db.history"
local migrate  = require "db.migrate"

-- dependencies that porla provides
local config   = require "config"
local cron     = require "cron"
local fs       = require "fs"
local log      = require "log"
local presets  = require "presets"
local sessions = require "sessions"
local sqlite3  = require "sqlite3"
local torrents = require "torrents"

local function apply(preset, params)
    if preset == nil then
        return
    end

    if preset.download_limit  ~= nil then params.download_limit  = preset.download_limit  end
    if preset.max_connections ~= nil then params.max_connections = preset.max_connections end
    if preset.max_uploads     ~= nil then params.max_uploads     = preset.download_limit  end
    if preset.save_path       ~= nil then params.save_path       = preset.save_path       end
    if preset.upload_limit    ~= nil then params.upload_limit    = preset.upload_limit    end

    if preset.category ~= nil then
        params.userdata.category = preset.category
    end

    if preset.tags ~= nil then
        params.userdata.tags = preset.tags
    end
end

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

            local params = nil

            if string.sub(file_buffer, 0, 7) == "magnet:" then
                local trimmed_buffer = file_buffer:gsub("^%s*(.-)%s*$", "%1")
                local p, err = AddTorrentParams.from_magnet(trimmed_buffer)

                if err ~= nil then
                    log.error("Failed to parse magnet link: "..err)
                    goto next_entry
                end

                params = p
            else
                params = AddTorrentParams.new()

                local ti, err = TorrentInfo.from_buffer(file_buffer)

                if err ~= nil then
                    log.error("Failed to parse torrent file: "..err)
                    goto next_entry
                end

                params.ti = ti
            end

            local info_hash = nil

            if params.ti ~= nil           then info_hash = params.ti:info_hash() end
            if params.info_hash.v1 ~= nil then info_hash = params.info_hash      end

            log.debug("Adding torrent with info hash "..info_hash.v1)

            local preset_default = presets.get("default")
            apply(preset_default, params)

            local preset_dir = nil

            if directory.preset ~= nil then
                preset_dir = presets.get(directory.preset)
                apply(preset_dir, params)
            end

            -- override save path from directory config
            if directory.save_path ~= nil then params.save_path = directory.save_path end

            local session = nil

            if preset_dir ~= nil and preset_dir.session ~= nil then
                session = sessions.get(preset_dir.session)
            elseif preset_default.session ~= nil then
                session = sessions.get(preset_default.session)
            else
                session = sessions.get("default")
            end

            session:add_torrent(params)

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
