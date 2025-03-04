
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
        if not isDanger then  
            antispam.DEBUG = true
            isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
            print("MESSAGE TYPE="..class)
            print("ID="..i)
            print(real)
            print(breakdown)
            print('----------------------------------------------')
            error("Safe message~")
        end
    end

        if i > 50 then  
            break
        end
    end
end