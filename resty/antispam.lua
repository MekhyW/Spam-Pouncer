local antispam = {
	
}

local utf8 = require("utf8")

function antispam.classifyMessageDanger(msg) 
	local emojiPercent = antispam.getCustomEmojiPercentage(msg)

	local original_str = (msg.text or msg.description or msg.caption) or ""
	local str = antispam.remove_accents(original_str)

	local strLower = str:lower()

	local hasBotMention = antispam.hasBotMention(strLower)
	local hasCrypto, info = antispam.hasCryptoMention(str, strLower, emojiPercent, original_str)
	local hasIllegal = antispam.hasIllegalStuff(strLower)
	local hasScam = antispam.hasActualScam(strLower, original_str)

	local result = "Emoji percent: "..(emojiPercent*100).."\n"..
					"MentionBot: "..hasBotMention.."\n".. 
					"hasCrypto: "..hasCrypto..(info and (" "..info) or "").."\n".. 
					"hasIllegal: "..hasIllegal.."\n" ..
					"hasScam: "..hasScam.."\n" 
	if hasCrypto == 1 then 
		return true, "Cripto shit", result
	end

	if hasIllegal == 1 then 
		return true, "Drug selling", result
	end

	if hasScam == 1 then 
		return true, "Money scam", result
	end

	return false, "safe", result
end

function antispam.checkInnerElement(elem, strLower)
	if type(elem) == 'string' then 
		if not strLower:find(elem) then
			return 0
		end
	elseif type(elem) == 'table' then 
		for _, orElem in pairs(elem) do  
			if type(orElem) == 'string' then 
				if strLower:find(orElem) then 
					return 1
				end
			else 
				local useStr = strLower
				if orElem == contains_link then  
					useStr = strLower
				end
				if orElem(strLower) then  
					return 1
				end
			end
		end
	else 
		local useStr = strLower
		if elem == contains_link then  
			useStr = strLower
		end
		local res = elem(strLower)
		if not res or res == 0 then   
			return 0
		end
	end
	return 1
end

function antispam.checkScamSetList(strLower, original_str)
	local setList = {
		{"[^%w]profit[^%w]", "[^%w]contact[^%w]", antispam.hasPriceMention},
		{"[^%w]earning[^%w]", "[^%w]effortless", antispam.hasPriceMention},
		{"[^%w]invest[^%w]", "[^%w]earn[^%w]", antispam.hasPriceMention},
		{"[^%w]invest[^%w]", "[^%w]profit[^%w]", antispam.hasPriceMention},
		{"[^%w]retorno[^%w]", "[^%w]dinheiro[^%w]", antispam.hasPriceMention},
		{"[^%w]retorno[^%w]", "[^%w]verificado[^%w]", "[^%w]investidor", antispam.hasPriceMention},
		{"[^%w]day trade[^%w]", "[^%w]transfiro[^%w]", antispam.hasPriceMention},
		{"[^%w]honest", "[^%w]invest", {antispam.hasPriceMention, contains_link}},
	}
	strLower = " "..strLower.." "
	for a, set in pairs(setList) do  
		local ok = 1
		for _, elem in pairs(set) do  
			ok = antispam.checkInnerElement(elem, strLower)
			if ok == 0 then  
				break
			end
		end
		if ok == 1 then
			return 1
		end
	end
	return 0
end

function antispam.hasActualScam(strLower, original_str)
	local phone = antispam.hasPhoneNumber(strLower)
	local money = antispam.hasPriceMention(strLower)
	local scamMentions = {
		"apple pay",
		"cash app",
		"bank",
		"crypto",
		"transfer",
		"cloned card",
		"cartao clonado",
		"pix",
		"paypal",
		"whatsapp",
		"gift card",
		"gift cards",
		"seguidores",
		"seguidor",
		"trading",
		"invest",
		"investidora",
	}

	strLower = " "..strLower.." "
	local scamCount = 0
	for a, kw in pairs(scamMentions) do  
		if strLower:find("[^%w]"..kw.."[^%w]") then  
			scamCount = scamCount +1
		end
	end

	if scamCount <= 3 then  
		return antispam.checkScamSetList(strLower, original_str)
	end
	if money and phone then  
		return 1
	else 
		return scamCount > 6 and 1 or antispam.checkScamSetList(strLower, original_str)
	end
end
function antispam.hasIllegalStuff(strLower)
	local drugStuff = {
		"lsd",
		"heroine",
		"cannabis",
		"meth",
		"medelin",
		"cocaine",
		"cocaina",
		"cogumelo",
		"mushroom",
		"thc",
		"mdma",
		"xanax",
		"oxycodone",
		"ketamine",
		"cdb",
	}
	strLower = " "..strLower.." "
	local drugCount = 0
	for a, kw in pairs(drugStuff) do  
		if strLower:find("[^%w]"..kw.."[^%w]") then  
			drugCount = drugCount +1
		end
	end

	if drugCount <= 2 then  
		return 0
	end
	local hasPriceMention = antispam.hasPriceMention(strLower)
	if hasPriceMention then  
		return 1
	end

	return drugCount >= 4 and 1 or 0
end

function antispam.fancyReplacer(txt)
	txt = txt:gsub("𝐑", "r")
	txt = txt:gsub("𝐄", "e")
	txt = txt:gsub("𝐀", "a")
	txt = txt:gsub("𝐈", "i")
	txt = txt:gsub("𝐒", "s")
	txt = txt:gsub("𝐓", "t")
	txt = txt:gsub("𝐍", "n")
	txt = txt:gsub("𝐅", "f")
	txt = txt:gsub("𝐎", "o")
	txt = txt:gsub("𝑴", "m")
	txt = txt:gsub("𝑵", "n")
	txt = txt:gsub("𝑼", "u")
	txt = txt:gsub("𝑪", "c")
	return txt

end
local accent_map = {
        ['áàãâä'] = 'a', ['ÁÀÃÂÄ'] = 'A',
        ['éèêë'] = 'e', ['ÉÈÊË'] = 'E',
        ['íìîï'] = 'i', ['ÍÌÎÏ'] = 'I',
        ['óòõôö'] = 'o', ['ÓÒÕÔÖ'] = 'O',
        ['úùûü'] = 'u', ['ÚÙÛÜ'] = 'U',
        ['ç'] = 'c', ['Ç'] = 'C',
        ['ñ'] = 'n', ['Ñ'] = 'N',
        [".,;/\\|?!~*"] = " ",
}

function antispam.remove_accents(str)
    local normalized_str = ""
    for p, c in utf8.chars(str) do
        local char = c
        for accents, replacement in pairs(accent_map) do
            if accents:find(char, 1, true) then
                char = replacement
                break
            end
        end
        normalized_str = normalized_str .. char
    end
    normalized_str = antispam.fancyReplacer(normalized_str)
    local a = normalized_str:gsub("[\1-\8\11\12\14-\31\127-\255]", "") 
    return a
end

function is_valid_url(url)
    -- Pattern to match URLs with or without protocol
    local pattern = "^((https?://)?[%w-_%.]+%.[%w-_%.]+[%w-_%./?%%&=]*)$"
    
    -- Check if the string matches the URL pattern
    if url:match(pattern) then
        return true
    else
        return false
    end
end

local function contains_link(s)
    -- Pattern to match URLs with http/https
    local pattern1 = "https?://[%w-_%.%?%.:/%+=&]+"
    -- Pattern to match URLs without http/https (e.g., example.com)
    local pattern2 = "[%w-_]+%.[%a]+[%w-_%.%?%.:/%+=&]*"
    

    if string.find(s, pattern1) then
        return true
    else
    	local from,to = string.find(s, pattern2)
    	if from then   
    		local url = s:sub(from, to)
    		return is_valid_url(url)
    	end
        return false
    end
end


function antispam.hasPriceMention(strLower)
    local conditions = {
        "([%d,%.]+)[%$€]",
        "([%d,%.]+).?[%$€]",
        "[%$€]([%d,%.]+)",
        "[%$€]%s*([%d,%.]+)",
        "([%d,%.]+)[%$€]",
        "([%d,%.]+)%s*brl",
        "([%d,%.]+)%s*r",

        "[%$€]([%d,%.]+)",
        "brl%s*([%d,%.]+)",
        "r%$%s*([%d,%.]+)",
        "r%s*([%d,%.]+)",


        "usd%s*([%d,%.]+)",
        "euro?%s*([%d,%.]+)",
        "([%d,%.]+)%s*usd",
        "([%d,%.]+)%s*euro?",
        "%-%s([%d,%.]+)",
        "$:%s*([%d,%.]+)",
    
    }

    for a,c in pairs(conditions) do 
        if strLower:match(c) and strLower:match("%d") then 
            return true, c
        end
    end
    
    return false
end

function antispam.hasCryptoMention(str, strLower, emojiPercent, original_str)
	local cryptoKeywords = {
		"claim",
		"airdrop",
		"btc",
		"ton"
	}

	strLower = " "..strLower.." "
	str = " "..str.." "
	local hasMentionOf = ""
	local hasAnuncio = false
	for a, kw in pairs(cryptoKeywords) do  
		local e,b = strLower:find("([^%w ])"..kw.."([^%w ])")
		if e then  
			hasAnuncio = true
			hasMentionOf = "Has mention of '"..kw.."'"
			
			print('['..strLower:sub(e-5, b+5)..']')
			break
		end
	end

	if not hasAnuncio then  
		return 0
	end

	if str:match("[^%w]%$([A-Z]-)[^%w]") then 
		return 1, hasMentionOf.." and mentions directly an crypto currency"
	end

	local btcstuff = {
		"btc",
		"bitcoin",
		"eth",
		"crypto",
		"wallet",
		"ton",
		"nft",
		"token",
		"tokens",
		"usdt"
	}
	
	for a, kw in pairs(btcstuff) do  
		if strLower:find("[^%w]"..kw.."[^%w]") then  
			return hasMentionOf.." and mentions '"..kw.."'"
		end
	end

	if emojiPercent > 0.7 and antispam.hasBotMention(strLower) == 1 and strLower:match("ton") then  
		return 1, hasMentionOf.." and has emoji or bot mention"
	end

	if contains_link(original_str) then  
		
		return 1,  hasMentionOf.." and Has link"
	end

	return 0
end

function antispam.hasPhoneNumber(str)
	if str:match("%+%d+") then 
		return 1
	end
	return 0
end

function antispam.hasBotMention(str)
	if str:match("@([a-zA-Z0-9_]+)bot") or str:match("t%.me/([a-zA-Z0-9_]+)bot") then 
		return 1
	end
	return 0
end

function antispam.classifyText(str)

end

function antispam.getCustomEmojiPercentage(msg)
	if not msg.entities then  
		return 0
	end
	local str = (msg.text or msg.description) or ""
	if str == "" then 
		return 0
	end
	local emojiLen = 0
	for a, entity in pairs(msg.entities) do 
		if entity.type == 'custom_emoji' then  
			if not entity.length then  
				entity.length = entity.text:len()
			end
			emojiLen = emojiLen + entity.length
		end
	end
	return emojiLen/str:len()
end

function antispam.onNewChatParticipant(msg)
end

function antispam.onTextReceive(msg)
	if msg.from then
		local isSpam, class, breakdown = antispam.classifyMessageDanger(msg)
		if isSpam then
			print("Encontrado spam do tipo "..class.."\n"..breakdown)
			local str = (msg.text or msg.description or msg.caption)
			print(str)
			local chatid = msg.chat and msg.chat.id or msg.from.id
			bot.sendMessage(5146565303, "Encontrado spam do tipo "..class.."\n"..breakdown..'\nNo chat: '..chatid)
			local res = bot.forwardMessage(5146565303, msg.from.id, false, msg.message_id)
			if not res.ok then  
				bot.sendMessage(5146565303, "Spam found: \n"..str)
			end
		end
	end
end

function antispam.onPhotoReceive(msg)
	if msg.from then
		local isSpam, class, breakdown = antispam.classifyMessageDanger(msg)
		if isSpam then
			print("Encontrado spam do tipo "..class.."\n"..breakdown)
			local str = (msg.text or msg.description or msg.caption)
			print(str)
			local chatid = msg.chat and msg.chat.id or msg.from.id
			bot.sendMessage(5146565303, "Encontrado spam do tipo "..class.."\n"..breakdown..'\nNo chat: '..chatid )
			local res = bot.forwardMessage(5146565303, msg.from.id, false, msg.message_id)
			if not res.ok then  
				bot.sendMessage(5146565303, "Spam found: \n"..str)
			end
		end
	end
end

function antispam.onDocumentReceive(msg)
	if msg.from then
		local isSpam, class, breakdown = antispam.classifyMessageDanger(msg)
		if isSpam then
			print("Encontrado spam do tipo "..class.."\n"..breakdown)
			local str = (msg.text or msg.description or msg.caption)
			print(str)
			local chatid = msg.chat and msg.chat.id or msg.from.id
			bot.sendMessage(5146565303, "Encontrado spam do tipo "..class.."\n"..breakdown..'\nNo chat: '..chatid)
			local res = bot.forwardMessage(5146565303, msg.from.id, false, msg.message_id)
			if not res.ok then  
				bot.sendMessage(5146565303, "Spam found: \n"..str)
			end
		end
	end
end

function antispam.loadCommands()
end




function antispam.loadTranslation()
end


function antispam.load()
end 

function antispam.save()
end

function antispam.ready()
end

function antispam.frame()

end

local isDanger, class, breakdown = antispam.classifyMessageDanger({text=[[3 de março na história

Mitologia nórdica
dia de Aegir, deus teutônico dos mares

Internacional 
Dia Mundial da Vida Selvagem (2014)

Japão 
Hinamatsuri ou "Dia das Meninas" 

Austrália
Dia do Trabalho
 
Bulgária
Dia da Independência

Malawi 
Dia dos Mártires 
 
Brasil 
Aniversário da fundação de:
Alagoa - MG 
Autazes - AM 
Bandeira - MG 
Canaã - MG 
Carbonita - MG 
Chapada do Norte - MG 
Claro dos Poções - MG 
Mirabela - MG 
Nova União - MG 
Pão de Açúcar - AL 
Ribeirão do Largo - BA 
Santa Rita de Ibitipoca - MG 
Varzelândia - MG 

1872 — Império do Brasil: A questão religiosa foi um conflito e enfrentamento entre a Igreja Católica, o Imperador e a Maçonaria, acabou se tornando uma questão de Estado, gerando a decisão do estado à parte das religiões.
1891 — Criada a Floresta Nacional de Shoshone como a primeira floresta nacional dos Estados Unidos e do mundo.
1904 — Kaiser Guilherme II da Alemanha torna-se a primeira pessoa a fazer uma gravação sonora de um documento político, usando o cilindro fonográfico de Thomas Edison.
1910 — Fundação Rockefeller: John D. Rockefeller, Jr. anuncia sua aposentadoria da administração de seus negócios para que possa dedicar todo seu tempo à filantropia.
1913 — Milhares de mulheres marcham, entre 5 000 e 10 000 manifestantes, na Procissão do Sufrágio Feminino em Washington, D.C.
1923 – A revista Time é publicada pela primeira vez.
1938 — Descoberta de petróleo na Arábia Saudita.
1969 — Programa Apollo: a NASA lança a Apollo 9 para testar o módulo lunar.
1997 — Inaugurada a mais alta estrutura do Hemisfério sul (328 metros), Sky Tower, no centro de Auckland, Nova Zelândia, após dois anos e meio de construção.
2005 — Steve Fossett torna-se a primeira pessoa a realizar uma circum-navegação aérea solo ao redor do mundo sem paradas ou reabastecimento.
2017 — Nintendo lança em todo o mundo o console de videogame híbrido Nintendo Switch.

Nasceram neste dia…

1847 — Alexander Graham Bell, engenheiro e acadêmico anglo-americano (m. 1922).
1974 — Juliana Martins, atriz brasileira. 
2003 — Thomas Barbusca, ator estadunidense.

Morreram neste dia…

1883 — Antônio Joaquim Franco Velasco, pintor brasileiro (n. 1780).
1964 — Mario Gatti, médico brasileiro (n. 1879).
2023 — Emílio Pitta, ator brasileiro (n. 1943).





https://www.facebook.com/100031795313593/posts/pfbid031U4JuS5dewtDDho3phGa3fbxggqtePDWgVw6xH95ecCCQCgAEdpotJZSNNCeq6PLl/3 de março na história

Mitologia nórdica
dia de Aegir, deus teutônico dos mares

Internacional 
Dia Mundial da Vida Selvagem (2014)

Japão 
Hinamatsuri ou "Dia das Meninas" 

Austrália
Dia do Trabalho
 
Bulgária
Dia da Independência

Malawi 
Dia dos Mártires 
 
Brasil 
Aniversário da fundação de:
Alagoa - MG 
Autazes - AM 
Bandeira - MG 
Canaã - MG 
Carbonita - MG 
Chapada do Norte - MG 
Claro dos Poções - MG 
Mirabela - MG 
Nova União - MG 
Pão de Açúcar - AL 
Ribeirão do Largo - BA 
Santa Rita de Ibitipoca - MG 
Varzelândia - MG 

1872 — Império do Brasil: A questão religiosa foi um conflito e enfrentamento entre a Igreja Católica, o Imperador e a Maçonaria, acabou se tornando uma questão de Estado, gerando a decisão do estado à parte das religiões.
1891 — Criada a Floresta Nacional de Shoshone como a primeira floresta nacional dos Estados Unidos e do mundo.
1904 — Kaiser Guilherme II da Alemanha torna-se a primeira pessoa a fazer uma gravação sonora de um documento político, usando o cilindro fonográfico de Thomas Edison.
1910 — Fundação Rockefeller: John D. Rockefeller, Jr. anuncia sua aposentadoria da administração de seus negócios para que possa dedicar todo seu tempo à filantropia.
1913 — Milhares de mulheres marcham, entre 5 000 e 10 000 manifestantes, na Procissão do Sufrágio Feminino em Washington, D.C.
1923 – A revista Time é publicada pela primeira vez.
1938 — Descoberta de petróleo na Arábia Saudita.
1969 — Programa Apollo: a NASA lança a Apollo 9 para testar o módulo lunar.
1997 — Inaugurada a mais alta estrutura do Hemisfério sul (328 metros), Sky Tower, no centro de Auckland, Nova Zelândia, após dois anos e meio de construção.
2005 — Steve Fossett torna-se a primeira pessoa a realizar uma circum-navegação aérea solo ao redor do mundo sem paradas ou reabastecimento.
2017 — Nintendo lança em todo o mundo o console de videogame híbrido Nintendo Switch.

Nasceram neste dia…

1847 — Alexander Graham Bell, engenheiro e acadêmico anglo-americano (m. 1922).
1974 — Juliana Martins, atriz brasileira. 
2003 — Thomas Barbusca, ator estadunidense.

Morreram neste dia…

1883 — Antônio Joaquim Franco Velasco, pintor brasileiro (n. 1780).
1964 — Mario Gatti, médico brasileiro (n. 1879).
2023 — Emílio Pitta, ator brasileiro (n. 1943).





https://www.facebook.com/100031795313593/posts/pfbid031U4JuS5dewtDDho3phGa3fbxggqtePDWgVw6xH95ecCCQCgAEdpotJZSNNCeq6PLl/]]})
		if isDanger then  
			print("MESSAGE TYPE="..class)
			print(breakdown)
			print('----------------------------------------------')
		end

--[[

local res = io.open("result.json", "r")
local dt = res:read("*a")
res:close()

local json = require("json")
local data = json.decode(dt)


for i,msg in pairs(data.messages) do  
	if msg.type == "message" then 
		local real = ""
		if type(msg.text) == 'table' then
			for _, txt in pairs(msg.text) do  
				if type(txt) == 'string' then  
					real = real..txt
				else
					real = real..txt.text
				end
			end
		else 
			real = msg.text
		end
		local tgMsg = {
			text = real,
			entities = msg.text_entities
		}
		
		if i ~= -1 then

		local isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
		if not isDanger then  
			print("MESSAGE TYPE="..class)
			print(i)
			print(real)
			print(breakdown)
			print('----------------------------------------------')
		end
	end

		if i > 50 then  
			break
		end
	end
end
]]
return antispam