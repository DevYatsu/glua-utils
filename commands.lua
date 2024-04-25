-- Commands are parsed with a simple pattern:
-- <commandStartPattern><commandName> [<arg>] [<arg>] "<arg with spaces>" ...

-- The allowed commands are listed inside of the `commandsTable` table.

-- The pattern defining the commands should start with / it can have a len != than 1
local commandStartPattern = "!"

-- if a player has the exact argument name then it is returned alone
-- otherwise a list of players with the name starting by the argument is returned
-- if no player is matched an empty list is returned
local function getPlayersByName(name)
    name = string.lower(name)
    local allPlayers = player.GetHumans()

    local plyers = {}

    for i, plyer in ipairs(allPlayers) do
        local currentPlayerName = string.lower(plyer:Name())
        if string.StartsWith(currentPlayerName, name)  then
            table.insert(plyers, plyer)
        end

        if currentPlayerName == name then
            return {plyer}
        end
    end

    return plyers
end

-- Define commands here
local commandsTable = {
    ["kill"] = {
        argsNum = 1,
        isAdmin = true,
        hideMsg = true,
        action = function(ply, args, rest)
            local targetName = args[1]
            if ( !targetName ) then ply:Kill() end

            local plyers = getPlayersByName(targetName)

            if #plyers == 1 then return plyers[1]:Kill() end
            if #plyers == 0 then return ply:ChatPrint("Could not kill `"..targetName.."`: player not found.") end
            
            ply:ChatPrint("Could not kill `"..targetName.."`: several players have a name starting with this prefix.")
        end
    },
    -- a command to echo a msg
    ["echo"] = {
        -- argsNum = 0 -> it's the default, 
        -- it means all the content of the message will be in 'rest'
        hideMsg = true,
        action = function(ply, args, rest)
            if #rest == 0 then return ply:ChatPrint("Cannot echo emptiness.") end
            ply:ChatPrint("echo: "..rest)
        end
    },
    -- a command to send a msg to all players
    ["all"] = {
        hideMsg = true,
        isAdmin = true,
        action = function(ply, args, rest)
            if #rest == 0 then return ply:ChatPrint("Cannot send an empty world message.") end
            PrintMessage(HUD_PRINTTALK, "-- WORLD MESSAGE -- "..rest)
        end
    },
    -- a command to send a given player
    ["pm"] = {
        argsNum = 1,
        hideMsg = true,
        action = function(ply, args, rest)
            local targetName = args[1]
            if ( !targetName ) then return end

            if targetName == ply:Name() then return ply:ChatPrint("You can't send a pm to yourself.") end
            if #rest == 0 then return ply:ChatPrint("Cannot send an empty message.") end

            local plyers = getPlayersByName(targetName)

            if #plyers == 1 then
                local plyer = plyers[1]
                ply:ChatPrint("PM sent to "..ply:GetName()..": "..rest)
                plyer:ChatPrint("PM from "..ply:GetName()..": "..rest)
                return
            end

            if #plyers == 0 then return ply:ChatPrint("Could not send a pm to `"..targetName.."`: player not found.") end
            
            ply:ChatPrint("Could not send a pm to `"..targetName.."`: several players have a name starting with this prefix.")
        end
    }
}

-- hook to handle user chat message event
hook.Add("PlayerSay", "InterpretChatCommands", function(ply, msg,_b)
    msg = string.Trim(msg)

    -- if there is a not for several commands with different start patterns
    -- you should call each commandlist down there

    if string.len(msg) <= 1 or not string.StartsWith(msg, commandStartPattern) then
        return
    end

    local commands = commands(commandsTable)

    -- it's important to return the value if::
    -- + you want to make use of hideMsg prop
    -- + you want to make use of the return value of 'action' function
    -- precision: hideMsg takes priority over action
    return commands:call(ply, msg)
end)

-- Setup Commands with an object as displayed up there
local function commands(commandsObject)
    setmetatable(commandsObject, 
    {
        __index = {
            commandFromMsg = function(self, msg)
                local name, argsString = splitCommand(msg)

                return self[name], argsString
            end,
            call = function(self, ply, msg)
                local command, argsString = self:commandFromMsg(msg)

                if not command then
                    return
                end

                local numberOfArgs = command.argsNum and command.argsNum or 0
                local args, rest = getArgs(argsString, numberOfArgs)

                if command.isAdmin and not ply:IsAdmin() then
                    return
                end

                local result = command.action(ply, args, rest)

                if command.hideMsg then
                    return ""
                end 

                return result
            end,
        }
    })

    return commandsObject
end

-- here chatMsg is sure to be a command starting with "!"
-- Returns a name String and arguments String
local function splitCommand(chatMsg) 
    local chatMsg = string.Trim(chatMsg)

    local posSpace = string.find(chatMsg, " ")
    local command_name = nil 
    local argsString = nil

    if posSpace == nil then
        command_name = string.sub(chatMsg, string.len(commandStartPattern) + 1)
        argsString = ""
    else
        command_name = string.sub(chatMsg, string.len(commandStartPattern) + 1, posSpace - 1)
        argsString = string.TrimLeft(string.sub(chatMsg, posSpace, string.len(chatMsg)), " ")
    end


    return command_name, argsString
end

-- Extract a given number of arguments from an arguments string
-- Returns the args as an Array and the last argument is the rest of the string
local function getArgs(argsString, number)
    local args = {}
    local rest = argsString

    if string.len(string.Trim(argsString)) == 0 then
        return args, rest
    end

    for i = 1, number do
        local quotedArg = rest:match("^%b\"\"")
        local unquotedArg = rest:match("^%S+")

        if quotedArg then
            rest = rest:sub(#quotedArg + 1):gsub("^%s+", "")
            table.insert(args, quotedArg:sub(2, -2)) -- Remove quotes
        elseif unquotedArg then
            rest = rest:sub(#unquotedArg + 1):gsub("^%s+", "")
            table.insert(args, unquotedArg)
        else
            break
        end
    end

    return args, rest
end
