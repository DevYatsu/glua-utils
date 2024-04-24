print("hello  from server")

local commandStartPattern = "!"

-- it is the max number of args
local commandsArgumentsNumber = {    
    ["kill"] = 1
}

setmetatable(commandsArgumentsNumber, 
{
    __index = function()
        return 0
    end
})

hook.Add("PlayerSay", "InterpretChatCommands", function(ply, msg,c)
    msg = string.Trim(msg)
    
    print("msg="..msg)
    if string.len(msg) <= 1 or not string.StartsWith(msg, commandStartPattern) then
        return
    end

    local isPlayerAdmin = ply:IsAdmin()
    print("isadmin=".. tostring(isPlayerAdmin))

    local name, argsString = splitCommand(msg)
    local numberOfArgs = commandsArgumentsNumber[name]
    local args, rest = getArgs(argsString, numberOfArgs)
    
    if name == "kill" then
        local targetName = args[1]
        if targetName == nil then
            ply:Kill()
        else 
            local players = player.GetHumans()
            
            for i, plyer in ipairs(players) do
                if plyer:GetName() == targetName then
                    plyer:Kill()
                end
            end
        end
    end
end)

-- here chatMsg is sure to be a command starting with "!"
-- Returns a name String and arguments String
function splitCommand(chatMsg) 
    local chatMsg = string.Trim(chatMsg)

    local posSpace = string.find(chatMsg, " ")
    local command_name = nil 
    local argsString = nil

    if posSpace == nil then
        command_name = string.sub(chatMsg, 2)
        argsString = ""
    else
        command_name = string.sub(chatMsg, 2, posSpace - 1)
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
