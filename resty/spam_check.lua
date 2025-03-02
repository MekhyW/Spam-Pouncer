
local cjson = require "cjson"
local antispam = require "antispam"
if ngx.req.get_method() ~= "POST" then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say('{"error": "Only POST requests are allowed"}')
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

ngx.req.read_body()
local body = ngx.req.get_body_data()

local ok, json_data = pcall(cjson.decode, body)
if not ok or not json_data then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say('{"error": "Invalid JSON"}')
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local isDanger, class, breakdown = antispam.classifyMessageDanger(json_data)
if isDanger then  
    ngx.status = ngx.HTTP_OK
    ngx.say(cjson.encode(({
        spam=true,
        class=class,
        breakdown=breakdown
    })))
end

ngx.status = ngx.HTTP_OK
ngx.say(cjson.encode(({spam=false})))