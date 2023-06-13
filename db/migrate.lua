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
    local version

    db
        :prepare("PRAGMA user_version")
        :step(function(row)
            version = row:int(0)
        end)

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
