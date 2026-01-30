-- Reset highlighting.
vim.cmd.highlight 'clear'
if vim.fn.exists 'syntax_on' then
    vim.cmd.syntax 'reset'
end
vim.o.termguicolors = true
vim.g.colors_name = 'qubit-true'

local hp = require('colors.helpers')
local palette = require('colors.palettes.qubit')
local colors = hp.colors_from_palette(palette)

-- Terminal colors.
vim.g.terminal_color_0 = colors.bg_2
vim.g.terminal_color_1 = colors.red
vim.g.terminal_color_2 = colors.green
vim.g.terminal_color_3 = colors.yellow
vim.g.terminal_color_4 = colors.purple
vim.g.terminal_color_5 = colors.pink
vim.g.terminal_color_6 = colors.cyan
vim.g.terminal_color_7 = colors.white
vim.g.terminal_color_8 = colors.fg_2
vim.g.terminal_color_9 = colors.bright_red
vim.g.terminal_color_10 = colors.bright_green
vim.g.terminal_color_11 = colors.bright_yellow
vim.g.terminal_color_12 = colors.bright_cyan
vim.g.terminal_color_13 = colors.bright_pink
vim.g.terminal_color_14 = colors.bright_cyan
vim.g.terminal_color_15 = colors.bright_white
vim.g.terminal_color_background = colors.bg
vim.g.terminal_color_foreground = colors.fg

-- Groups used for my statusline.
---@type table<string, vim.api.keyset.highlight>
local statusline_groups = {}
for mode, color in pairs {
    Normal = { color = colors.purple, extra = { bold = true } },
    Pending = colors.pink,
    Visual = colors.yellow,
    Insert = colors.green,
    Command = colors.cyan,
    Other = colors.orange,
} do
    if type(color) ~= 'table' then
        statusline_groups['StatusLineMode' .. mode] = { fg = colors.bg_2, bg = color }
        statusline_groups['StatusLineModeSeparator' .. mode] = { fg = color, bg = colors.bg_2 }
    else
        statusline_groups['StatusLineMode' .. mode] =
            vim.tbl_extend('keep', color.extra or {}, { fg = colors.bg_2, bg = color.color })
        statusline_groups['StatusLineModeSeparator' .. mode] =
            vim.tbl_extend('keep', color.extra or {}, { fg = color.color, bg = colors.bg_2 })
    end
end
statusline_groups = vim.tbl_extend('error', statusline_groups, {
    StatusLineSeparator = { fg = colors.bg_3 },
    StatusLineItalic = { fg = colors.grey },
    StatusLineSpinner = { fg = colors.bright_green, bold = true },
    StatusLineTitle = { fg = colors.bright_white, bold = true },
    StatusLineFilename = { fg = colors.bright_white },
})

--[[ Highlights are added after colorscheme, so need to figure this out.
local function get_highlights_by_pattern(pattern)
    local matching_groups = {}
    local ok, all_groups = pcall(vim.api.nvim_get_hl, 0, {})
    if not ok then
        return matching_groups
    end
    for group_name, opts in pairs(all_groups) do
        if group_name:match(pattern) then
            matching_groups[group_name] = opts
        end
    end

    return matching_groups
end

vim.tbl_extend('error', statusline_groups,
    vim.iter(get_highlights_by_pattern('^BufferLine.*Selected'))
    :map(function(group, opts)
        opts.bg = colors.bg_2
        return group, opts
    end)
    :totable()
)
]]

---@type table<string, vim.api.keyset.highlight>
local groups = vim.tbl_extend('error', statusline_groups, {
    -- Builtins.
    Boolean = { fg = colors.cyan },
    Character = { fg = colors.green },
    ColorColumn = { bg = colors.fg_2 },
    Comment = { fg = colors.comment, italic = true },
    Conceal = { fg = colors.comment },
    Conditional = { fg = colors.pink },
    Constant = { fg = colors.yellow },
    CurSearch = { fg = colors.black, bg = colors.fuchsia },
    Cursor = { fg = colors.black, bg = colors.white },
    CursorColumn = { bg = colors.bg_2 },
    CursorLine = { bg = colors.bg_2 },
    FoldColumn = { bg = colors.bg_2 },
    SignColumn = { bg = colors.bg_2 },
    LineNr = { fg = colors.lilac, bg = colors.bg_2 },
    CursorLineNr = { bg = colors.bg_3, fg = colors.purple, bold = true },
    CursorLineSign = { bg = colors.bg_3, bold = true },
    CursorLineFold = { bg = colors.bg_3, bold = true },
    Define = { fg = colors.purple },
    Directory = { fg = colors.cyan },
    EndOfBuffer = { fg = colors.bg },
    Error = { fg = colors.bright_red },
    ErrorMsg = { fg = colors.bright_red },
    Folded = { bg = colors.bg_2 },
    Function = { fg = colors.yellow },
    Identifier = { fg = colors.cyan },
    IncSearch = { link = 'CurSearch' },
    Include = { fg = colors.purple },
    Keyword = { fg = colors.cyan },
    Label = { fg = colors.cyan },
    Macro = { fg = colors.purple },
    MatchParen = { sp = colors.fg, underline = true },
    NonText = { fg = colors.bg_3 },
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.bg_2 },
    FloatBorder = { fg = colors.lilac, bg = colors.bg_2 },
    Number = { fg = colors.purple },
    Pmenu = { fg = colors.white, bg = colors.bg },
    PmenuSbar = { bg = colors.transparent_blue },
    PmenuSel = { fg = colors.cyan, bg = colors.fg_2 },
    PmenuThumb = { bg = colors.fg_2 },
    PreCondit = { fg = colors.cyan },
    PreProc = { fg = colors.yellow },
    Question = { fg = colors.purple },
    Repeat = { fg = colors.pink },
    Search = { fg = colors.bg, bg = colors.orange },
    String = { fg = colors.yellow },
    Special = { fg = colors.green, italic = true, bold = true },
    SpecialComment = { fg = colors.comment, italic = true },
    SpecialKey = { fg = colors.bg_3 },
    SpellBad = { sp = colors.bright_red, underline = true },
    SpellCap = { sp = colors.yellow, underline = true },
    SpellLocal = { sp = colors.yellow, underline = true },
    SpellRare = { sp = colors.yellow, underline = true },
    Statement = { fg = colors.purple },
    StatusLine = { fg = colors.white, bg = colors.bg_2 },
    StatusLineNC = { fg = colors.white, bg = colors.bg_2 },
    StorageClass = { fg = colors.pink },
    Structure = { fg = colors.yellow },
    Substitute = { fg = colors.fuchsia, bg = colors.orange, bold = true },
    Title = { fg = colors.cyan },
    Todo = { fg = colors.purple, italic = true },
    Type = { fg = colors.cyan },
    TypeDef = { fg = colors.yellow },
    Underlined = { fg = colors.cyan, underline = true },
    VertSplit = { fg = colors.white },
    Visual = { bg = colors.bg_3 },
    VisualNOS = { fg = colors.bg_3 },
    WarningMsg = { fg = colors.yellow },
    WildMenu = { fg = colors.bg_2, bg = colors.white },
    Delimiter = { fg = colors.bg_3 },

    -- Treesitter.
    ['@annotation'] = { fg = colors.yellow },
    ['@attribute'] = { fg = colors.cyan },
    ['@boolean'] = { fg = colors.purple },
    ['@character'] = { fg = colors.green },
    ['@comment.documentation'] = { fg = colors.comment, italic = true, bold = true },
    ['@constant'] = { fg = colors.purple },
    ['@constant.builtin'] = { fg = colors.purple },
    ['@constant.macro'] = { fg = colors.cyan },
    ['@constructor'] = { fg = colors.cyan },
    ['@error'] = { fg = colors.bright_red },
    ['@function'] = { fg = colors.green },
    ['@function.builtin'] = { fg = colors.cyan },
    ['@function.macro'] = { fg = colors.green },
    ['@function.method'] = { fg = colors.green },
    ['@keyword'] = { fg = colors.pink },
    ['@keyword.conditional'] = { fg = colors.pink },
    ['@keyword.exception'] = { fg = colors.purple },
    ['@keyword.function'] = { fg = colors.cyan },
    ['@keyword.function.ruby'] = { fg = colors.pink },
    ['@keyword.include'] = { fg = colors.pink },
    ['@keyword.operator'] = { fg = colors.pink },
    ['@keyword.repeat'] = { fg = colors.pink },
    ['@label'] = { fg = colors.cyan },
    ['@markup'] = { fg = colors.orange },
    ['@markup.emphasis'] = { fg = colors.yellow, italic = true, bold = true },
    ['@markup.heading'] = { fg = colors.pink, bold = true },
    ['@markup.link'] = { fg = colors.orange, bold = true },
    ['@markup.link.uri'] = { fg = colors.yellow },
    ['@markup.list'] = { fg = colors.cyan },
    ['@markup.raw'] = { fg = colors.yellow },
    ['@markup.strong'] = { fg = colors.orange, bold = true },
    ['@markup.underline'] = { fg = colors.orange },
    ['@module'] = { fg = colors.orange },
    ['@number'] = { fg = colors.purple },
    ['@number.float'] = { fg = colors.green },
    ['@operator'] = { fg = colors.pink },
    ['@parameter.reference'] = { fg = colors.orange },
    ['@property'] = { fg = colors.purple },
    ['@punctuation.bracket'] = { fg = colors.fg },
    ['@punctuation.delimiter'] = { fg = colors.fg },
    ['@string'] = { fg = colors.yellow },
    ['@string.escape'] = { fg = colors.cyan },
    ['@string.regexp'] = { fg = colors.bright_red },
    ['@string.special.symbol'] = { fg = colors.purple },
    ['@structure'] = { fg = colors.purple },
    ['@tag'] = { fg = colors.cyan },
    ['@tag.attribute'] = { fg = colors.green },
    ['@tag.delimiter'] = { fg = colors.cyan },
    ['@type'] = { fg = colors.bright_cyan },
    ['@type.builtin'] = { fg = colors.cyan, italic = true, bold = true },
    ['@type.qualifier'] = { fg = colors.pink },
    ['@variable'] = { fg = colors.fg },
    ['@variable.builtin'] = { fg = colors.purple },
    ['@variable.member'] = { fg = colors.orange },
    ['@variable.parameter'] = { fg = colors.orange },

    -- Semantic tokens.
    ['@class'] = { fg = colors.cyan },
    ['@decorator'] = { fg = colors.cyan },
    ['@enum'] = { fg = colors.cyan },
    ['@enumMember'] = { fg = colors.purple },
    ['@event'] = { fg = colors.cyan },
    ['@interface'] = { fg = colors.cyan },
    ['@lsp.type.class'] = { fg = colors.cyan },
    ['@lsp.type.decorator'] = { fg = colors.green },
    ['@lsp.type.enum'] = { fg = colors.cyan },
    ['@lsp.type.enumMember'] = { fg = colors.purple },
    ['@lsp.type.function'] = { fg = colors.green },
    ['@lsp.type.interface'] = { fg = colors.cyan },
    ['@lsp.type.macro'] = { fg = colors.cyan },
    ['@lsp.type.method'] = { fg = colors.green },
    ['@lsp.type.namespace'] = { fg = colors.orange },
    ['@lsp.type.parameter'] = { fg = colors.orange },
    ['@lsp.type.property'] = { fg = colors.purple },
    ['@lsp.type.struct'] = { fg = colors.cyan },
    ['@lsp.type.type'] = { fg = colors.bright_cyan },
    ['@lsp.type.variable'] = { fg = colors.fg },
    ['@modifier'] = { fg = colors.cyan },
    ['@regexp'] = { fg = colors.yellow },
    ['@struct'] = { fg = colors.cyan },
    ['@typeParameter'] = { fg = colors.cyan },

    -- Python.
    ['@string.documentation.python'] = { link = '@comment.documentation' },

    -- Package manager.
    LazyDimmed = { fg = colors.grey },
    LazyComment = { link = 'Conceal' },

    -- LSP.
    DiagnosticDeprecated = { strikethrough = true, fg = colors.fg },
    DiagnosticError = { fg = colors.red },
    DiagnosticFloatingError = { fg = colors.red },
    DiagnosticFloatingHint = { fg = colors.cyan },
    DiagnosticFloatingInfo = { fg = colors.cyan },
    DiagnosticFloatingWarn = { fg = colors.yellow },
    DiagnosticHint = { fg = colors.cyan },
    DiagnosticInfo = { fg = colors.cyan },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
    DiagnosticUnnecessary = { fg = colors.grey, undercurl = true },
    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.transparent_red },
    DiagnosticVirtualTextHint = { fg = colors.cyan, bg = colors.transparent_blue },
    DiagnosticVirtualTextInfo = { fg = colors.cyan, bg = colors.transparent_blue },
    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.transparent_yellow },
    DiagnosticWarn = { fg = colors.yellow },
    LspCodeLens = { fg = colors.cyan, underline = true },
    LspFloatWinBorder = { fg = colors.comment },
    LspInlayHint = { fg = colors.fg_2 },
    LspReferenceRead = { bg = colors.transparent_blue }, --, sp = colors.blue, underline = true },
    LspReferenceText = {},
    LspReferenceWrite = { bg = colors.transparent_red }, -- sp = colors.red, underline = true },
    LspSignatureActiveParameter = { bold = true, underline = true, sp = colors.fg },

    -- Neominimap:
    NeominimapBackground = { bg = colors.bg },
    NeominimapBorder = { fg = colors.lavender },
    NeominimapErrorLine = { bg = colors.transparent_red },
    NeominimapWarnLine = { bg = colors.transparent_yellow },
    NeominimapInfoLine = { bg = colors.transparent_blue },
    NeominimapHingLine = { bg = colors.transparent_blue },
    NeominimapErrorSign = { bg = colors.red },
    NeominimapWarnSign = { bg = colors.yellow },
    NeominimapInfoSign = { bg = colors.cyan },
    NeominimapHingSign = { bg = colors.cyan },
    NeominimapErrorIcon = { bg = colors.red },
    NeominimapWarnIcon = { bg = colors.yellow },
    NeominimapInfoIcon = { bg = colors.cyan },
    NeominimapHingIcon = { bg = colors.cyan },

    -- Completions:
    BlinkCmpKindClass = { link = '@type' },
    BlinkCmpKindColor = { link = 'DevIconCss' },
    BlinkCmpKindConstant = { link = '@constant' },
    BlinkCmpKindConstructor = { link = '@type' },
    BlinkCmpKindEnum = { link = '@variable.member' },
    BlinkCmpKindEnumMember = { link = '@variable.member' },
    BlinkCmpKindEvent = { link = '@constant' },
    BlinkCmpKindField = { link = '@variable.member' },
    BlinkCmpKindFile = { link = 'Directory' },
    BlinkCmpKindFolder = { link = 'Directory' },
    BlinkCmpKindFunction = { link = '@function' },
    BlinkCmpKindInterface = { link = '@type' },
    BlinkCmpKindKeyword = { link = '@keyword' },
    BlinkCmpKindMethod = { link = '@function.method' },
    BlinkCmpKindModule = { link = '@module' },
    BlinkCmpKindOperator = { link = '@operator' },
    BlinkCmpKindProperty = { link = '@property' },
    BlinkCmpKindReference = { link = '@parameter.reference' },
    BlinkCmpKindSnippet = { link = '@markup' },
    BlinkCmpKindStruct = { link = '@structure' },
    BlinkCmpKindText = { link = '@markup' },
    BlinkCmpKindTypeParameter = { link = '@variable.parameter' },
    BlinkCmpKindUnit = { link = '@variable.member' },
    BlinkCmpKindValue = { link = '@variable.member' },
    BlinkCmpKindVariable = { link = '@variable' },
    BlinkCmpLabelDeprecated = { link = 'DiagnosticDeprecated' },
    BlinkCmpLabelDescription = { fg = colors.grey, italic = true },
    BlinkCmpLabelDetail = { fg = colors.grey, bg = colors.bg_2 },
    BlinkCmpMenu = { bg = colors.bg_2 },
    BlinkCmpMenuBorder = { bg = colors.bg_2 },
    BlinkCmpMenuSelection = { bg = colors.bg_3 },

    -- Dap UI.
    DapStoppedLine = { default = true, link = 'Visual' },
    NvimDapVirtualText = { fg = colors.lavender, underline = true },

    -- Diffs.
    DiffAdd = { fg = colors.green, bg = colors.transparent_green },
    DiffChange = { fg = colors.white, bg = colors.transparent_yellow },
    DiffDelete = { fg = colors.red, bg = colors.transparent_red },
    DiffText = { fg = colors.orange, bg = colors.transparent_yellow, bold = true },
    DiffviewFolderSign = { fg = colors.cyan },
    DiffviewNonText = { fg = colors.lilac },
    diffAdded = { fg = colors.bright_green, bold = true },
    diffChanged = { fg = colors.bright_yellow, bold = true },
    diffRemoved = { fg = colors.bright_red, bold = true },

    -- Command line.
    MoreMsg = { fg = colors.bright_white, bold = true },
    MsgArea = { fg = colors.white },
    MsgSeparator = { fg = colors.lilac },

    -- Winbar styling.
    WinBar = { bg = colors.bg_2, fg = colors.fg, sp = colors.fg_2, underline = true },
    WinBarDir = { fg = colors.purple },
    WinBarDoc = { fg = colors.blue, italic = true, bold = true },
    WinBarCodeCompanion = { fg = colors.pink },
    WinBarTarget = { fg = colors.bright_purple, bold = true },
    WinBarTargetDirty = { fg = colors.yellow, bold = true },
    WinBarTargetModified = { fg = colors.orange, bold = true },
    WinBarTargetError = { fg = colors.red, bold = true },
    WinBarSeparator = { fg = colors.green },
    WinBarNC = { bg = colors.bg, fg = colors.fg_2, sp = colors.bg_3, underline = true },
    WinBarDirNC = { fg = colors.fg_2 },
    WinBarTargetNC = { fg = colors.purple, bold = false },
    WinBarModeHighlightNC = { fg = colors.bg_3 },

    -- Windows.
    WinSeparator = { bg = colors.bg, fg = colors.black },

    -- Quickfix window.
    QuickFixLine = { italic = true, bg = colors.transparent_red },

    -- Gitsigns.
    GitSignsAdd = { fg = colors.bright_green },
    GitSignsChange = { fg = colors.cyan },
    GitSignsCurrentLineBlame = { fg = colors.lavender },
    GitSignsDelete = { fg = colors.bright_red },
    GitSignsStagedAdd = { fg = colors.orange },
    GitSignsStagedChange = { fg = colors.orange },
    GitSignsStagedDelete = { fg = colors.orange },

    -- Gitlinker.
    NvimGitLinkerHighlightTextObject = { link = 'Visual' },
    IblIndent = { fg = colors.bg_3 },

    -- Bufferline.
    BufferLineBufferSelected = { bg = colors.bg_2, sp = colors.purple },
    BufferLineTabSelected = { bg = colors.bg_2, sp = colors.purple },
    BufferLineCloseButtonSelected = { bg = colors.bg_2, fg = colors.purple },
    BufferLineIndicatorSelected = { bg = colors.bg_2, fg = colors.purple },
    BufferLineDevIconLuaSelected = { bg = colors.bg_2, fg = colors.blue },
    BufferLineFileIcon = { bg = colors.bg },
    BufferLineFill = { bg = colors.bg, underline = true, sp = colors.black },
    TabLineSel = { bg = colors.purple },

    -- When triggering flash, use a white font and make everything in the backdrop italic.
    FlashBackdrop = { italic = false, fg = colors.fg_2 },
    FlashPrompt = { link = 'Normal' },
    FlashLabel = { link = 'IncSearch' },

    -- Make these titles more visible.
    MiniClueTitle = { bold = true, fg = colors.cyan },
    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

    -- Nicer yanky highlights.
    YankyPut = { link = 'Visual' },
    YankyYanked = { link = 'Visual' },

    -- Highlight for the Treesitter sticky context.
    TreesitterContextBottom = { underline = true, sp = colors.lilac },

    -- Fzf overrides.
    FzfLuaBorder = { fg = colors.comment },
    FzfLuaHeaderBind = { fg = colors.lavender },
    FzfLuaHeaderText = { fg = colors.pink },
    FzfLuaLivePrompt = { link = 'Normal' },
    FzfLuaLiveSym = { fg = colors.fuchsia },
    FzfLuaPreviewTitle = { fg = colors.fg },
    FzfLuaSearch = { bg = colors.transparent_red },

    -- Nicer sign column highlights for grug-far.
    GrugFarResultsChangeIndicator = { link = 'Changed' },
    GrugFarResultsRemoveIndicator = { link = 'Removed' },
    GrugFarResultsAddIndicator = { link = 'Added' },

    -- Overseeer.
    OverseerComponent = { link = '@keyword' },

    -- Rainbow Delimeters.
    RainbowDelimiterRed = { fg = colors.pink },
    RainbowDelimiterYellow = { fg = colors.yellow },
    RainbowDelimiterCyan = { fg = colors.cyan },
    RainbowDelimiterOrange = { fg = colors.orange },
    RainbowDelimiterGreen = { fg = colors.green },
    RainbowDelimiterViolet = { fg = colors.purple },
    RainbowDelimiterBlue = { fg = colors.blue },

    -- Links.
    HighlightUrl = { underline = true, fg = colors.bright_cyan, sp = colors.bright_cyan },

    -- CodeCompanion.
    CodeCompanionInlineDiffHint = { link = 'LspCodeLens' },

    -- Windsurf.
    CodeiumSuggestion = { fg = colors.fg_2 },

    -- Oil.
    OilHidden = { link = 'Conceal' },
    OilDirHidden = { link = 'OilHidden' },
    OilLinkTarget = { fg = colors.orange },

    -- Satellite.
    SatelliteBackground = { bg = colors.bg_2 },

    -- Neotree.
    NeoTreeTabActive = { bg = colors.bg_2, fg = colors.purple },
    NeoTreeTabSeparatorActive = { bg = colors.bg_2, fg = colors.black },
})

for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
end
