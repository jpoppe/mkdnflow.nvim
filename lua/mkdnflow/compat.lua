-- mkdnflow.nvim (Tools for fluent markdown notebook navigation and management)
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

local utils = require('mkdnflow').utils
local silent = require('mkdnflow').config.silent
local warn = function(message)
    vim.api.nvim_echo({{message, 'WarningMsg'}}, true, {})
end
-- Show a warning message if nvim < 0.7.x
if require('mkdnflow').nvim_version < 7 and not silent then
    warn("⬇️  Not all Mkdnflow functionality will work for your current version of Neovim, including mappings. Please upgrade to Neovim >= 0.7 or make sure to set your mappings in your Neovim config.")
end
local M = {}

--[[
goBack() calls the version of goBack() in the buffers module. This is here so
that anyone calling goBack from the old files module will still have functiona-
lity. (The compat module is called as files in init.lua.)
TODO: Remove this function in June 2022
--]]
M.goBack = function()
    require('mkdnflow.buffers').goBack()
    warn("⬇️  References to files.lua will soon stop working. See :h mkdnflow-changes, commit 511e8e...")
end

--[[
goForward() calls the version of goForward() in the buffers module. This is
here so that anyone calling goForward from the old files module will still have
functionality. (The compat module is called as files in init.lua.)
TODO: Remove this function in June 2022
--]]
M.goForward = function()
    require('mkdnflow.buffers').goForward()
    warn("⬇️  References to files.lua will soon stop working. See :h mkdnflow-changes, commit 511e8e...")
end

--[[
followPath()
--]]
M.followPath = function(path)
    require('mkdnflow.links').followLink(path)
    warn('⬇️  The use of followPath() will soon stop working. Please use followLink() instead. See :h mkdnflow-changes, commit c1cf25...')
end

--[[
userConfigCheck() will check a user config for particular settings that have
since been migrated to another setting or another format. It returns an equiva-
lent user config that is upgraded to the new format.
--]]
M.userConfigCheck = function(user_config)
    -- Check if to-do symbols are being customized but no values were provided
    -- for not_started, in_progress, and complete
    if user_config.to_do then
        if user_config.to_do.symbols and not (
            user_config.to_do.not_started or
            user_config.to_do.in_progress or
            user_config.to_do.complete
        ) then
            if #user_config.to_do.symbols == 3 then
                user_config.to_do.not_started = user_config.to_do.symbols[1]
                user_config.to_do.in_progress = user_config.to_do.symbols[2]
                user_config.to_do.complete = user_config.to_do.symbols[3]
            elseif #user_config.to_do.symbols > 3 then
                local max = #user_config.to_do.symbols
                user_config.to_do.not_started = user_config.to_do.symbols[1]
                user_config.to_do.in_progress = user_config.to_do.symbols[2]
                user_config.to_do.complete = user_config.to_do.symbols[max]
            elseif #user_config.to_do.symbols == 2 then
                user_config.to_do.not_started = user_config.to_do.symbols[1]
                user_config.to_do.in_progress = user_config.to_do.symbols[1]
                user_config.to_do.complete = user_config.to_do.symbols[2]
            end
        end
        if user_config.to_do.symbols then
            local symbols = table.concat(user_config.to_do.symbols)
            if string.len(symbols) > #user_config.to_do.symbols and not utils.moduleAvailable('lua-utf8') then
                warn('⬇️  A to-do symbol is longer than one character or may be a utf8 symbol. To-do functionality may not work as expected. If you wish to use utf8 symbols, install the lua-utf8 luarocks dependency.')
            end
        end
    end
    -- Look for default bib path
    if user_config.default_bib_path then
        if user_config.default_bib_path == '' then
            user_config.bib.default_path = nil
        else
            user_config.bib.default_path = user_config.default_bib_path
        end
        warn('⬇️  The default_bib_path key has now been migrated into the bib key under the default_path option. Please update your config. See :h mkdnflow-changes, commit e9f7815...')
    end
    -- Look for link style
    if user_config.link_style then
        user_config.links.style = user_config.link_style
    end
    -- Look for implicit extension and remove periods
    if user_config.links then
        if user_config.links.implicit_extension then
            user_config.links.implicit_extension = string.gsub(user_config.links.implicit_extension, '%.', '')
        end
    end
    -- Look for oldest prefix settings
    if user_config.evaluate_prefix or user_config.new_file_prefix then
        user_config.prefix = {
            evaluate = user_config.evaluate_prefix,
            string = user_config.new_file_prefix
        }
    end
    -- Look for old prefix settings
    if user_config.prefix then
        if user_config.prefix.evaluate == nil then
            user_config.prefix.evaluate = true
        end
        if user_config.prefix.string == nil then
            user_config.prefix.string = [[os.date('%Y-%m-%d_')]]
        end
        warn('⬇️  The prefix key has now been migrated into the links key under the transform_explicit option. Please update your config. See :h mkdnflow-changes, commit f054440...')
    end
    -- Look for links_relative_to
    if user_config.links_relative_to then
        user_config.perspective = user_config.links_relative_to
        warn('⬇️  The links_relative_to key is now called "perspective". Please update your config. See :h mkdnflow-changes, commit e42290...')
    end
    -- Look for wrap preferences
    if user_config.wrap_to_beginning or user_config.wrap_to_end then
        user_config.wrap = true
        warn('⬇️  The wrap_to_beginning/end keys have been merged into a single "wrap" key. Please update your config. See :h mkdnflow-changes, commit 9068e1...')
    end
    -- Inspect perspective setting, if specified
    if user_config.perspective then
        if type(user_config.perspective) ~= 'table' then
            warn('⬇️  The perspective key (previously "links_relative_to") should now be associated with a table value. Please update your config. See :h mkdnflow-changes, commit 75c8ec...')
            if user_config.perspective == 'current' then
                local table = {
                    priority = 'current',
                    fallback = 'first'
                }
                user_config.perspective = table
            elseif user_config.perspective == 'first' then
                local table = {
                    priority = 'first',
                    fallback = 'current'
                }
                user_config.perspective = table
            end
        end
        if user_config.perspective.vimwd_heel ~= nil then
            user_config.perspective['nvim_wd_heel'] = user_config.perspective.vimwd_heel
        end
    end
    -- Inspect mappings
    if user_config.mappings then
        local string = false
        for _, value in pairs(user_config.mappings) do
            if type(value) == 'string' then
                string = true
            end
        end
        if string then
            warn('⬇️  In the mappings table, commands should now be associated with a table value instead of a string. See :h mkdnflow-changes, commit 436510...')
            local compatible_mappings = {}
            for key, value in pairs(user_config.mappings) do
                if key == 'MkdnFollowLink' then
                    compatible_mappings[key] = {{'n', 'v'}, value}
                else
                    compatible_mappings[key] = {'n', value}
                end
            end
            user_config.mappings = compatible_mappings
        end
    end
    return(user_config)
end

return M
