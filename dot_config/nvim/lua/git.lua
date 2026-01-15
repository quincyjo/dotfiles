local git_icons = require('icons').git

local M = {}

--- Builds the git metrics for the target buffer.
---@param bufnr? integer The bufnr to diff. If nil, the current buffer is used.
---@return string | nil The styled diff, if any.
function M.git_diff(bufnr)
    if not package.loaded['gitsigns'] then
        return nil
    end
    local hunks = require('gitsigns').get_hunks(bufnr or vim.api.nvim_get_current_buf())
    if not hunks or #hunks == 0 then
        return nil
    end
    local added, removed, changed = 0, 0, 0
    for _, hunk in ipairs(hunks) do
        if hunk.type == 'change' then
            changed = changed + math.max(hunk.added.count, hunk.removed.count)
        else
            if hunk.added then
                added = added + hunk.added.count
            end
            if hunk.removed then
                removed = removed + hunk.removed.count
            end
        end
    end
    if added > 0 or changed > 0 or removed > 0 then
        local segments = {}
        if added > 0 then
            table.insert(segments,
                string.format('%%#%s#%s%d', 'GitSignsAdd', git_icons.additions, added))
        end
        if changed > 0 then
            table.insert(segments,
                string.format('%%#%s#%s%d', 'GitSignsChange', git_icons.modified, changed))
        end
        if removed > 0 then
            table.insert(segments,
                string.format('%%#%s#%s%d', 'GitSignsDelete', git_icons.deletions, removed))
        end
        return table.concat(segments, ' ')
    end
end

return M
