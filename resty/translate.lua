local json = require('json')

function httpsRequest(uri, mthd, body, headers)
    local httpcon = require("resty.http").new()
    local res, err = httpcon:request_uri(uri, {
        method = mthd or 'GET',
        ssl_verify=false,
        body=body,
        headers=headers
    })
    httpcon:close()
    if not res then
        ngx.log(ngx.ERR, "request failed: ", err)
        return nil
    end
    return res.body, res.status
end

function translateToEnglish(text)
    local url = 'https://clients5.google.com/translate_a/t'
    local params = {
        ['client'] = 'dict-chrome-ex',
        ['sl'] = 'auto',
        ['tl'] = 'en',
        ['q'] = text,
    }
    local param_str = '?'
    for k, v in pairs(params) do
        param_str = param_str .. k .. '=' .. v .. '&'
    end
    url = url .. param_str
    local body, status = httpsRequest(url, "GET", nil, {})
    if (status == 200) then
        local data = json.decode(body)
        return data[1][1]
    else
        print('HTTP request failed with status: ' .. status)
    end
    return nil
end

return translateToEnglish
