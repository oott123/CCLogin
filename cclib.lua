local json = require("json")
local http = require("socket.http")
local socket = require("socket")
local ltn12 = require("ltn12")
local global = _G
module("cclib")
local print = global.print
local string = global.string
local io = global.io
local table = global.table
local error = global.error

function saveJson(filename, table)
    local str = json.encode(table)
    local f, err = io.open(filename, 'w')
    if f == nil then
        error("Unable to open file: " .. err)
    end
    f:write(str)
    f:close()
end

function readJson(filename)
    local f, err = io.open(filename, 'r')
    if f == nil then
        error("Unable to open file: " .. err)
    end
    local str = f:read("*all")
    return json.decode(str)
end

-- return: loggedIn?, error?, wlanUserIp
function checkIfLogin()
    local url = "http://119.29.29.29/d?dn=www.csu.edu.cn" -- DnsPod D+ 解析服务
    local result, code, headers = http.request{
        url = url,
        redirect = false
    }
    if result == nil then
        return nil, code
    elseif code == 200 then
        return true
    else
        -- 尚未登录
        local location = headers.location
        local wlanUserIp = string.gmatch(location, "wlanuserip=([^&]+)")()
        return false, false, wlanUserIp
    end
end

function request(method, postData)
    local url = "http://61.137.86.87:8080/portalNat444/AccessServices/" .. method
    local source = ltn12.source.string(postData)
    local sinkTable = {}
    local result, code, headers = http.request{
        url = url,
        method = "POST",
        headers = {
            ["Host"] = "61.137.86.87",
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20100101 Firefox/21.0",
            ["Referer"] = "http://61.137.86.87:8080/portalNat444/index.jsp",
            ["Content-Length"] = string.len(postData),
            ["Accept"] = "application/json",
            ["Content-Type"] = "application/x-www-form-urlencoded;charset=utf-8",
            ["X-Requested-With"] = "XMLHttpRequest"
        },
        sink = ltn12.sink.table(sinkTable),
        source = source
    }
    if result == 1 then
        -- 获取 json 成功
        local resultStr = table.concat(sinkTable)
        local resultJson = json.decode(resultStr)
        local resultCode = resultJson.resultCode
        return resultCode, resultJson, resultStr
    else
        -- 获取 json 失败
        return 9999, code
    end
end

function login(username, password, wlanUserIp)
    local postData = "accountID=" .. username
        .."%40zndx.inter&password=" .. password
        .. "&brasAddress=59df7586&userIntranetAddress=" .. wlanUserIp
    return request('login', postData)
end

function logout(wlanUserIp)
    local postData = "brasAddress=59df7586&userIntranetAddress=" .. wlanUserIp
    return request('logout', postData)
end

function getLocalIp()
    local s = socket.udp()
    s:setpeername("10.96.0.1", 53)
    local ip = s:getsockname()
    if ip.gmatch(ip, "^10.")() == "10." then
        return ip
    else
        error("Cannot get internat ip address: " .. ip .. " is not local address.")
    end
end

function printErr(message)
    io.stderr:write(message)
    io.stderr:write("\n")
end

loginCodes = {
    [1] = 'Unknown error.',
    [2] = 'Already logged in.',
    [3] = 'Service temporarily unavailable.',
    [4] = 'Unknown error.',
    [6] = 'Timeout.',
    [7] = 'User LAN address error.',
    [8] = 'Connection error.',
    [9] = 'Authentication script error.',
    [10] = 'Captcha error.',
    [11] = 'Password too simple.',
    [12] = 'Unknown LAN address.',
    [13] = 'Unknown bras address.',
    [14] = 'Unknown subscription.',
    [16] = 'LAN address or bras error.',
    [17] = 'LAN address expired.',
}

logoutCodes = {
    [1] = 'Access Denied.',
    [2] = 'Error while logging out.',
    [3] = 'Already logged out.',
    [4] = 'Timeout.',
    [5] = 'Network error.',
    [6] = 'Authentication script error.',
    [7] = 'Unknown LAN address.',
    [8] = 'Unknown bras address.',
    [9] = 'LAN address or bras error.',
}