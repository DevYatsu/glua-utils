-- Commands are parsed with a simple pattern:
-- <commandStartPattern><commandName> [<arg>] [<arg>] "<arg with spaces>" ...

-- The allowed commands are listed inside of the `commandsTable` table.

-- The pattern defining the commands should start with / it can have a len != than 1
local commandStartPattern = "!"

-- Define commands here
local commandsTable = {
    ["kill"] = {
        argsNum = 1,
        requiresAdmin = true,
        action = function(ply, args, rest)
            local targetName = args[1]
            if targetName == nil then
                ply:Kill()
            else 
                local players = player.GetHumans()
                
                for i, plyer in ipairs(players) do
                    if plyer:GetName() == targetName then
                        plyer:Kill()
                        break 
                    end
                end
            end
        end
    },
    ["echo"] = {
        argsNum = 0,
        action = function(ply, args, rest)
            util.AddNetworkString("EchoCommand")
            // send to the client the message in order to echo it
            // then on the client side we should manage the connexion
            net.Start("EchoCommand")
            net.WriteString(rest)
            net.Send(ply)
        end
    }
}

-- hook to handle user chat message event
hook.Add("PlayerSay", "InterpretChatCommands", function(ply, msg,_b)
    msg = string.Trim(msg)

    if string.len(msg) <= 1 or not string.StartsWith(msg, commandStartPattern) then
        return
    end

    local commands = commands(commandsTable)

    commands:call(ply, msg)
end)

-- Setup Commands with an object as displayed up there
function commands(commandsObject)
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

                if command.requiresAdmin and not ply:IsAdmin() then
                    return
                end

                return command.action(ply, args, rest)
            end,
        }
    })

    return commandsObject
end

-- here chatMsg is sure to be a command starting with "!"
-- Returns a name String and arguments String
function splitCommand(chatMsg) 
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
function getArgs(argsString, number)
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
