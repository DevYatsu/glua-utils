print("hello  from server")

-- The pattern the commands should start with / it can have a len != than 1
local commandStartPattern = "!"

-- Define commands here
local commandsTable = {
    ["kill"] = {
        argsNum = 1,
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
    }
}

-- hook to handle user chat message event
hook.Add("PlayerSay", "InterpretChatCommands", function(ply, msg,_b)
    msg = string.Trim(msg)

    if string.len(msg) <= 1 or not string.StartsWith(msg, commandStartPattern) then
        return
    end

    local isPlayerAdmin = ply:IsAdmin()
    local commands = commands(commandsTable)
    local command, argsString = commands:fromMsg(msg)
    
    command.action(ply, ...command:getArgs(argsString))
end)

-- Setup Commands with an object as displayed up there
function commands(commandsObject)
    setmetatable(commandsObject, 
    {
        __index = {
            argsNum = 0,
            action = function(ply, args, rest) end,
            getArgumentsNumber = function(self)
                return self.argsNum
            end, 
            getArgs = function(self, argsString)
                return getArgs(argsString, self:getArgumentsNumber())
            end,
        },
        fromMsg = function(self, msg)
            local name, argsString = splitCommand(msg)

            return self[name], argsString
        end
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
