local sqlite3 = require "sqlite3"

local migrations = {
    [[
    CREATE TABLE file_history (
        id INTEGER PRIMARY KEY,
        file_name TEXT NOT NULL UNIQUE,
        timestamp INTEGER NOT NULL
    )
    ]]
}

local function migrate(db)
    local version = nil

    local stmt = db:prepare("PRAGMA user_version")

    if stmt:step() == sqlite3.ROW then
        version = stmt:get_value(0)
    end

    stmt:finalize()

    if version == nil then
        return false
    end

    if version == #migrations then
        return true
    end

    for i=version, #migrations - 1, 1 do
        db:exec(migrations[i + 1])
    end

    db:exec("PRAGMA user_version = "..#migrations)

    return true
end

return migrate
