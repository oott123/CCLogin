require "cclib"
local _print = print
local print = cclib.printErr

-- 检查模式
local mode = ''
if arg[1] == 'login' then
    mode = 'login'
elseif arg[1] == 'logout' then
    mode = 'logout'
else
    print("ChinaNet-CSU Login (CCLogin) v1.0.0 for OpenWrt")
    print("Usage: " .. arg[0] .. " login|logout")
    os.exit(0)
end

-- 读取用户配置
local success, user = pcall(cclib.readJson, "user.json")
if not success then
    print("Error when reading user.json; please create it before continue.")
    print([[echo '{"username": "010203040506", "password": "your secret here"}' > user.json]])
    print("Get your secret in browser:")
    print([[javascript:alert(RSAUtils.encryptedString(publickey, encodeURIComponent($("#userPassword").val())));void(0);]])
    print("----------------------------")
    print(user)
    os.exit(30)
end

-- 读取网络配置
local success, network = pcall(cclib.readJson, "network.json")
if not success or network.wlanUserIp == nil then
    -- 尝试读取本地 ip
    local success, wlanUserIp = pcall(cclib.getLocalIp)
    if success then
        network = {wlanUserIp = wlanUserIp}
    else
        -- 尝试检查登录
        local loggedIn, err, wlanUserIp = cclib.checkIfLogin()
        if wlanUserIp then
            network = {wlanUserIp = wlanUserIp}
        else
            network = {}
        end
    end
end

-- 开始运行
if mode == 'login' then
    if network.wlanUserIp == nil then
        print("Cannot get wlanUserIp, please run this script on your router.")
        os.exit(32)
    end
    local resultCode, result = cclib.login(user.username, user.password, network.wlanUserIp)
    if resultCode == "0" then
        network.usedFlow = result.usedflow
        network.totalFlow = result.totalflow
        network.balance = result.surplusmoney
        cclib.saveJson("network.json", network)
        os.exit(0)
    elseif result.resultDescribe ~= nil and result.resultDescribe ~= "" then
        print(result.resultDescribe)
        os.exit(resultCode)
    else
        local errMessage = cclib.loginCodes[resultCode]
        if errMessage == nil then
            errMessage = "Unknown error #" .. resultCode
        end
        print(errMessage)
        os.exit(resultCode)
    end
elseif mode == 'logout' then
    if network.wlanUserIp == nil then
        print("Cannot get wlanUserIp, please run this script on your router.")
        os.exit(32)
    end
    local resultCode = cclib.logout(network.wlanUserIp)
    if resultCode == "0" then
        os.exit(0)
    else
        local errMessage = cclib.logoutCodes[resultCode]
        if errMessage == nil then
            errMessage = "Unknown error #" .. resultCode
        end
        print(errMessage)
        os.exit(resultCode)
    end
end
