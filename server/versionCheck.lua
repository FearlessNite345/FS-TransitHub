local authorName = 'CHANGEME' -- Your author name
local resourceName = 'CHANGEME' -- The name of your FiveM resource
local fullName = '^3[' .. authorName .. '-' .. resourceName .. '] '

-- Github info to check the version
local githubUsername = 'CHANGEME' -- Your GitHub username
local githubRepo = 'CHANGEME' -- Your GitHub repository name
local githubVersionFilename = 'CHANGEME' -- The filename on GitHub containing the version information

local function printVersion(cur, late, status)
    print('^7----------------------------------------------------------')
    print(fullName .. '^4Checking for update...')
    print(fullName .. '^4' .. cur)
    print(fullName .. '^4' .. late)
    print(fullName .. status)
    print('^7----------------------------------------------------------')
end

local function checkVersion()
    local cur = ''
    local late = ''
    local status = ''

    local current = GetResourceMetadata(GetCurrentResourceName(), "version", 0);
    cur = "Current version: " .. current

    PerformHttpRequest(
        'https://raw.githubusercontent.com/' .. githubUsername .. '/' ..
            githubRepo .. '/main/' .. githubVersionFilename,
        function(Error, Version, Header)
            if Error ~= 200 then
                printVersion(cur, 'Latest version: ^8Failed to fetch',
                             '^8' .. Error)
                return
            end

            late = "Latest version: " .. Version

            if Version ~= current then
                status = "^8Your" .. resourceName ..
                             " version is outdated, Go to the download page to update to the latest."
            else
                status = "^2" .. resourceName .. " is up to date!"
            end

            printVersion(cur, late, status)
        end)
end

if Config.checkForUpdate then 
    checkVersion()
end
