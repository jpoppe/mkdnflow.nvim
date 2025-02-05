-- mkdnflow.nvim (Tools for personal markdown notebook navigation and management)
-- Copyright (C) 2022 Jake W. Vincent <https://github.com/jakewvincent>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local M = {}

-- Wrapper function for new list items in lists or going to the same cell/next row in a table
M.newListItemOrNextTableRow = function()
    -- Get the current line
    local line = vim.api.nvim_get_current_line()
    if require('mkdnflow').lists.hasListType(line) then
        require('mkdnflow').lists.newListItem('fancy', line)
    elseif require('mkdnflow').tables.isPartOfTable(line) then
        require('mkdnflow').tables.moveToCell(1, 0)
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), 'n', true)
    end
end

M.indentListItemOrJumpTableCell = function(direction)
    -- Get the current line
    local line = vim.api.nvim_get_current_line()
    local list_type = require('mkdnflow').lists.hasListType(line)
    if list_type and line:match(require('mkdnflow').lists.patterns[list_type].empty) then
        if direction == -1 then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-D>", true, false, true), 'n', true)
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-T>", true, false, true), 'n', true)
        end
    elseif require('mkdnflow').tables.isPartOfTable(line) then
        if direction == -1 then
            require('mkdnflow').tables.moveToCell(0, -1)
        else
            require('mkdnflow').tables.moveToCell(0, 1)
        end
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-I>", true, false, true), 'n', true)
    end
end

return M
