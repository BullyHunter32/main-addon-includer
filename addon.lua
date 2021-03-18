bLib = {}
bLib.MainDirectory = "blib" -- myaddon/lua/blib
bLib.Font = "DermaLarge" -- pog
bLib.SubDirectories = { -- Include order
    {"settings","shared"}, -- all files are downloaded to both realms
    {"sql","shared"}, -- all files are downloaded to both realms
    "functions", -- all files are included by file name i.e 'cl_init' or 'sv_init' etc
    {"elements","client"}, -- all files are downloaded by the client
}

function bLib:IncludeServer(strDirectory)
    if not strDirectory:match( "[\\/]([^/\\]+)$" ) then
        strDirectory = strDirectory..".lua"
    end
    return SERVER and include(strDirectory)
end

function bLib:IncludeClient(strDirectory)
    if not strDirectory:match( "[\\/]([^/\\]+)$" ) then
        strDirectory = strDirectory..".lua"
    end
    if SERVER then AddCSLuaFile(strDirectory) return end
    return include(strDirectory)
end

function bLib:IncludeShared(strDirectory)
    if not strDirectory:match( "[\\/]([^/\\]+)$" ) then
        strDirectory = strDirectory..".lua"
    end
    self:IncludeClient(strDirectory)
    self:IncludeServer(strDirectory)
end

local sF = string.find
function bLib:IncludeUnknown(strDirectory)
    local strFile = strDirectory:match( "[\\/]([^/\\]+)$" )
    local strPrefix = string.sub(strFile,1,2)
	print( strDirectory, strPrefix ,strFile )
    if strPrefix == "cl" then
        return self:IncludeClient(strDirectory)
    elseif strPrefix == "sv"  then
        return self:IncludeServer(strDirectory)
    elseif strPrefix == "sh" then
        return self:IncludeShared(strDirectory)
    end
    local server,client,shared = sF(strFile,"server"),sF(strFile,"client"),sF(strFile,"shared")
    if server then
        self:IncludeServer(strDirectory)
    elseif client then
        self:IncludeServer(strDirectory)
    elseif shared then
        self:IncludeServer(strDirectory)
    end
end

function bLib:IncludeFolder(strFolderDirectory, strRealm)
    local tFiles,tFolders = file.Find(strFolderDirectory.."/*","LUA")
    if !strRealm then
        for _,strFileName in ipairs(tFiles) do
            self:IncludeUnknown(strFolderDirectory.."/"..strFileName)
        end
        for _,strFolderName in ipairs(tFolders) do
            self:IncludeFolder(strFolderDirectory.."/"..strFolderName, strRealm)
        end
        return
    end
    if strRealm == "client" then
        for _,strFileName in ipairs(tFiles) do
            self:IncludeClient(strFolderDirectory.."/"..strFileName)
        end
        for _,strFolderName in ipairs(tFolders) do
            self:IncludeFolder(strFolderDirectory.."/"..strFolderName, strRealm)
        end
    elseif strRealm == "shared" then
        for _,strFileName in ipairs(tFiles) do
            self:IncludeShared(strFolderDirectory.."/"..strFileName)
        end
        for _,strFolderName in ipairs(tFolders) do
            self:IncludeFolder(strFolderDirectory.."/"..strFolderName, strRealm)
        end
    elseif strRealm == "server" then
        for _,strFileName in ipairs(tFiles) do
            self:IncludeShared(strFolderDirectory.."/"..strFileName)
        end
        for _,strFolderName in ipairs(tFolders) do
            self:IncludeFolder(strFolderDirectory.."/"..strFolderName, strRealm)
        end
    end
end

for _,anyFolder in ipairs(bLib.SubDirectories) do
    if type(anyFolder) == "table" then
        bLib:IncludeFolder(bLib.MainDirectory.."/"..anyFolder[1],anyFolder[2])
    elseif type(anyFolder) == "string" then
        bLib:IncludeFolder(bLib.MainDirectory.."/"..anyFolder)
    end
end
