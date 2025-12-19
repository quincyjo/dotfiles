local M = {}

-- Helper function to check if a character is alphanumeric (or underscore)
---@param char string
---@return boolean
local function is_alphanumeric(char)
    -- Using manual range checks as per "no regex" constraint
    return (char >= 'a' and char <= 'z') or
           (char >= 'A' and char <= 'Z') or
           (char >= '0' and char <= '9') or
           (char == '_')
end

-- Function to shorten a specific dot chain (from the previous response, slightly modified for clarity)
---@param input_string string
---@param N integer
---@return string
local function shortenDotChain(input_string, N)
    local parts = {}
    local last_end = 1
    for i = 1, #input_string do
        if input_string:sub(i, i) == '.' then
            table.insert(parts, input_string:sub(last_end, i - 1))
            last_end = i + 1
        end
    end
    table.insert(parts, input_string:sub(last_end, #input_string))

    local num_parts = #parts

    if num_parts <= N then
        return input_string
    end

    local shortened_parts = {}
    for i = num_parts - N + 1, num_parts do
        table.insert(shortened_parts, parts[i])
    end

    return table.concat(shortened_parts, ".")
end

-- Main function to process the entire sentence
---@param sentence string
---@param N integer
---@return string
function M.trim_dot_chains(sentence, N)
    local result = ""
    local i = 1
    while i <= #sentence do
        -- Check if the current character could be the start of a dot chain element
        if is_alphanumeric(sentence:sub(i, i)) then
            local j = i
            -- Find the end of the potential dot chain
            while j < #sentence do
                -- Look ahead for a dot
                if sentence:sub(j + 1, j + 1) == '.' then
                    -- Check if the character after the dot is alphanumeric
                    if j + 2 <= #sentence and is_alphanumeric(sentence:sub(j + 2, j + 2)) then
                        j = j + 2 -- Move past the dot and the next char
                    else
                        break -- Not a valid dot chain pattern, stop here
                    end
                elseif is_alphanumeric(sentence:sub(j + 1, j + 1)) then
                    j = j + 1
                else
                    break -- End of alphanumeric sequence
                end
            end

            -- Extract the potential chain
            local potential_chain = sentence:sub(i, j)

            -- Check if it actually contains a dot to be a "dot chain"
            if potential_chain:find(".", 1, true) then
                -- Shorten the chain and append it to the result
                result = result .. shortenDotChain(potential_chain, N)
            else
                -- Not a dot chain, just append the alphanumeric sequence
                result = result .. potential_chain
            end
            i = j + 1 -- Move the main index past the processed chain/word
        else
            -- Not alphanumeric, just append the character and move on
            result = result .. sentence:sub(i, i)
            i = i + 1
        end
    end
    return result
end

-- Note that: \19 = ^S and \22 = ^V.
---@return string The display string for the current mode.
local mode_to_str = {
    ['n'] = 'NORMAL',
    ['no'] = 'OP-PENDING',
    ['nov'] = 'OP-PENDING',
    ['noV'] = 'OP-PENDING',
    ['no\22'] = 'OP-PENDING',
    ['niI'] = 'NORMAL',
    ['niR'] = 'NORMAL',
    ['niV'] = 'NORMAL',
    ['nt'] = 'NORMAL',
    ['ntT'] = 'NORMAL',
    ['v'] = 'VISUAL',
    ['vs'] = 'VISUAL',
    ['V'] = 'VISUAL',
    ['Vs'] = 'VISUAL',
    ['\22'] = 'VISUAL',
    ['\22s'] = 'VISUAL',
    ['s'] = 'SELECT',
    ['S'] = 'SELECT',
    ['\19'] = 'SELECT',
    ['i'] = 'INSERT',
    ['ic'] = 'INSERT',
    ['ix'] = 'INSERT',
    ['R'] = 'REPLACE',
    ['Rc'] = 'REPLACE',
    ['Rx'] = 'REPLACE',
    ['Rv'] = 'VIRT REPLACE',
    ['Rvc'] = 'VIRT REPLACE',
    ['Rvx'] = 'VIRT REPLACE',
    ['c'] = 'COMMAND',
    ['cv'] = 'VIM EX',
    ['ce'] = 'EX',
    ['r'] = 'PROMPT',
    ['rm'] = 'MORE',
    ['r?'] = 'CONFIRM',
    ['!'] = 'SHELL',
    ['t'] = 'TERMINAL',
}

function M.mode_string()
    return mode_to_str[vim.api.nvim_get_mode().mode] or 'UNKNOWN'
end

---@return string The highlight mode group
function M.mode_highlight_group()
    -- Get the respective string to display.
    local mode = M.mode_string()

    -- Set the highlight group.
    local hl = 'Other'
    if mode:find 'NORMAL' then
        hl = 'Normal'
    elseif mode:find 'PENDING' then
        hl = 'Pending'
    elseif mode:find 'VISUAL' then
        hl = 'Visual'
    elseif mode:find 'INSERT' or mode:find 'SELECT' then
        hl = 'Insert'
    elseif mode:find 'COMMAND' or mode:find 'TERMINAL' or mode:find 'EX' then
        hl = 'Command'
    end

    return hl
end

---@paraam integer? The buffr id to of the file. If nil, then the curret buffer is used.
---@return string
function M.file_highlight(bufnr)
    local diff = require('git').git_diff(bufnr)
    local num_errors = #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
    return num_errors > 0 and '%#WinBarTargetError#'
        or vim.bo.modified and '%#WinBarTargetModified#'
        or diff and '%#WinBarTargetDirty#'
        or '%#WinBarTarget#'
end

return M
