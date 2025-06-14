
local res = io.open("test_data.json", "r")
local dt = res:read("*a")
res:close()

local json = dofile("json.lua")
local data = json.decode(dt)
local antispam = dofile("antispam.lua")

local skipped = {
    [18] = true, --lingua nao suportada
    [19] = true, --lingua nao suportada
    [45] = true, --No text
    [46] = true, --No text
    [73] = true, --No text
    [74] = true, --No text
    [74] = true, --No text
    [78] = true, --No text
    [82] = true, --No text
    [86] = true, -- cyka
    [89] = true, -- idk man
    [92] = true, -- sounds generic
    [102] = true, -- sus
    [106] = true, -- sus
    [110] = true, -- sus

}

local safe = {
    [114] = true
}
for i,msg in pairs(data.messages) do  
    if msg.type == "message" then 
        local real = ""
        if type(msg.text) == 'table' then
            local aux = {}
            for _, txt in pairs(msg.text) do  
                if type(txt) == 'string' then  
                    real = real..txt
                else
                    real = real..txt.text
                    if txt.type == "custom_emoji" then  
                        aux[#aux+1] = txt
                    end 
                end

            end
        else 
            real = msg.text
        end
        local tgMsg = {
            text = real,
            entities = msg.text_entities or aux
        }
        
        if not skipped[i] then

        local isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
        if (not safe[i] and not isDanger) or (safe[i] and isDanger) then  
            antispam.DEBUG = true
            isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
            print("MESSAGE TYPE="..class)
            print("ID="..i)
            print('----------------------------------------------')
            print(real)
            print('----------------------------------------------')
            print(antispam.remove_accents(real))
            print('----------------------------------------------')
            print(breakdown)
            print('----------------------------------------------')
            error("Safe message~")
        else  
            print("ok: "..i)
        end
    end

        if i > 229 then  
            break
        end
    end
end