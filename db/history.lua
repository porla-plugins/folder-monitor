local sqlite3 = require "sqlite3"

local History = {}

function History:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function History:contains(file_name)
    local exists = false

    local stmt = self.db:prepare("SELECT COUNT(*) AS count FROM file_history WHERE file_name = $1")
    stmt:bind(1, file_name)

    local s = stmt:step()

    if s == sqlite3.ROW then
        exists = stmt:get_value(0) > 0
    end

    stmt:finalize()

    return exists
end

function History:insert(file_name)
    local stmt = self.db:prepare("INSERT INTO file_history (file_name, timestamp) VALUES ($1, strftime('%s'))")
    stmt:bind(1, file_name)
    stmt:step()
    stmt:finalize()
end

return History
