local cron_ref = nil
local db_ref   = nil

local migrations = {
    [[
    CREATE TABLE file_history (
        id INTEGER PRIMARY KEY,
        file_name TEXT NOT NULL UNIQUE,
        timestamp INTEGER NOT NULL
    )
    ]]
}

local function historyContains(entry)
    local exists = false

    db_ref
        :prepare("SELECT COUNT(*) FROM file_history WHERE file_name = $1")
        :bind(1, entry.path)
        :step(function(row)
            exists = row:int(0) > 0
        end)

    return exists
end

local function historyInsert(entry)
    db_ref
        :prepare("INSERT INTO file_history (file_name, timestamp) VALUES ($1, strftime('%s'))")
        :bind(1, entry.path)
        :step(function(row)
        end)
end

local function check(ctx, directories)
    for _, directory in pairs(directories) do
        local dir = fs.Directory(directory.path)

        if not dir:exists() then
            goto next
        end

        for _, entry in pairs(dir:iterate()) do
            if entry.extension ~= ".torrent" then
                goto next_entry
            end

            if historyContains(entry) then
                goto next_entry
            end

            local torrent = load_torrent_file(entry.path)

            if ctx.session:hasTorrent(torrent) then
                goto next_entry
            end

            ctx.session:addTorrent({
                path = "/tmp",
                torrent = torrent
            })

            historyInsert(entry)

            ::next_entry::
        end

        ::next::
    end
end

local function migrate()
    local version

    db_ref
        :prepare("PRAGMA user_version")
        :step(function(row)
            version = row:int(0)
        end)

    if version == #migrations then
        return
    end

    print(string.format("Migrating folder-monitor from version %d to version %d", version, #migrations))

    for i=version, #migrations - 1, 1 do
        db_ref:exec(migrations[i + 1])
    end

    db_ref:exec("PRAGMA user_version = "..#migrations)
end

local P = {
    init = function(ctx)
        if ctx.config["folder-monitor"] == nil then
            print("No folder-monitor config")
            return
        end

        local cfg = ctx.config["folder-monitor"]

        cron_ref = cron({
            expression = cfg.cron,
            callback = function()
                check(ctx, cfg.dirs)
            end
        })

        db_ref = sqlite3.open(":memory:")
        db_ref:exec("PRAGMA journal_mode = WAL")

        migrate()
    end
}

return P
