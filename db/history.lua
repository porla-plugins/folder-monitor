return {
    contains = function(db, file_name)
        local exists = false
    
        db:prepare("SELECT COUNT(*) FROM file_history WHERE file_name = $1")
            :bind(1, file_name)
            :step(function(row)
                exists = row:int(0) > 0
            end)
    
        return exists
    end,

    insert = function(db, file_name)
        db:prepare("INSERT INTO file_history (file_name, timestamp) VALUES ($1, strftime('%s'))")
            :bind(1, file_name)
            :exec()
    end
}
