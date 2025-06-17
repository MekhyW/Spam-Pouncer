local antispam = {
	
}
local utf8 = dofile("utf8.lua")



local headRegexp = "([ \n^%w])"

local function printdbg(...)
	if antispam.DEBUG then 
		print(...)
	end
end



local emoji_pattern = "[\128-\255][\128-\255][\128-\255][\128-\255]?"  -- Basic UTF-8 emoji pattern

local function count_emojis(message)
    local emoji_count = 0
    for emoji in string.gmatch(message, emoji_pattern) do
        emoji_count = emoji_count + 1
    end
    return emoji_count
end

local function emoji_percentage(message)
    local total_chars = #message
    if total_chars == 0 then return 0 end
    
    local emoji_count = count_emojis(message)
    return (emoji_count / total_chars) 
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

local scammertld = {
	"com",
	"tk",
	"buzz",
	"xyz",
	"top",
	"ga",
	"ml",
	"info",
	"cf",
	"gq",
	"icu",
	"wang",
	"live",
	"net",
	"cn",
	"online",
	"host",
	"org",
	"us",
	"ru",
	"to",
	"one",
	"one1",
}
function antispam.contains_link(s)
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
    		if is_valid_url(url) then  
    			return true
    		end
    	end
    	for i,b in pairs(scammertld) do
	    	if s:match("([a-z0-9-])%."..b) then  
	    		return true
	    	end
	    end
        return false
    end
end


function antispam.hasPhoneNumber(str)
	if str:match("%+%d+") then 
		return 1
	end
	return 0
end

local furryCollections = {
	"ych", ""
}

function antispam.isNotFurry(str)
	local name1 = str:match("ych")
	if name1 then 
		return 0, name1
	end
	return 1
end

function antispam.hasUserMention(str)
	local name1 = str:match("@([a-zA-Z0-9_]+)")
	if name1 then 
		return 1, name1
	end
	return 0
end

function antispam.hasBotMention(str)
	local name1 = str:match("@([a-zA-Z0-9_]+)bot")
	if name1 then 
		return 1, name1
	end
	name1 = str:match("t%.me/([a-zA-Z0-9_]+)bot")
	if name1 then 
		return 1, name1
	end
	return 0, nil
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



function antispam.classifyMessageDanger(msg) 

	local original_str = (msg.text or msg.description or msg.caption) or ""

	local emojiPercent = antispam.getCustomEmojiPercentage(msg) 

	
	local str = antispam.remove_accents(original_str)

	local strLower = str:lower()

	local hasBotMention = antispam.hasBotMention(strLower)
	local hasCrypto, info = antispam.hasCryptoMention(str, strLower, emojiPercent, original_str)
	local hasIllegal = antispam.hasIllegalStuff(strLower)
	local hasScam, infos = antispam.hasActualScam(strLower, original_str, emojiPercent)

	local result = "Emoji percent: "..(emojiPercent*100).."\n"..
					"MentionBot: "..hasBotMention.."\n".. 
					"hasCrypto: "..hasCrypto..(info and (" "..info) or "").."\n".. 
					"hasIllegal: "..hasIllegal.."\n" ..
					"hasScam: "..hasScam..(infos and (" "..infos) or "").."\n"
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

function antispam.checkInnerElement(elem, strLower, original_str, dbg)
	local info = ""
	if type(elem) == 'string' then 
		if not strLower:find(elem) then
			return 0
		end
		info = info .. "Matched "..elem
	elseif type(elem) == 'table' then 
		if dbg then print("is tbl") end
		for _, orElem in pairs(elem) do  
			if type(orElem) == 'string' then 
				if strLower:find(orElem) or original_str:find(orElem) then 
					return 1, orElem
				end
			else 
				local useStr = strLower
				if orElem == antispam.contains_link  or orElem == antispam.hasPriceMention  then  
					useStr = original_str
					if dbg then print("original pls or") end
				end
				if dbg then print("validate or") end
				local res = orElem(useStr)
				if dbg then print("is tbl"..tostring(res)) end
				if res == 1 or res == true then  
					return 1, orElem
				end
			end
		end
		return 0
	else 
		local useStr = strLower
		if elem == antispam.contains_link or elem == antispam.hasPriceMention then  
			useStr = original_str
		end
		local res = elem(useStr)
		if res ~= 1 and res ~= true then   
			return 0
		end
	end
	return 1, elem
end



local cryptoCollection = { 
		{"investment", antispam.hasPriceMention, antispam.contains_link},
		{"[^%w]airdrop", "[^%w]crypto"},
		{"airdrop", antispam.contains_link},
		{{"[^%w]bitcoin", "[^%w]btc"}, "cashout"},
		{"[^%w]nft", "[^%w]reward", antispam.hasPriceMention},
		{{"[^%w]bitcoin", "[^%w]btc"}, "[^%w]usdt", antispam.contains_link},
		{"[^%w]crypto", {"[^%w]free", "[^%w]buy", "transaction", "coin"}, {antispam.contains_link}},
		{{"opensea", "claim"}, {"fast", "hurry", "snag"},  antispam.contains_link, antispam.isNotFurry},
		{{"crypto","claim"}, {"nft", "[^%w]eth[^%w]", "ethereum", "hurry", "usdt", "btc"}, {antispam.contains_link, "fast", "free", "success", "whale"}, antispam.isNotFurry},
		{"[^%w]crypto", {"[^%w]coin", antispam.hasPriceMention,  "usdt", "wallet", "profit"}, {"[^%w]channel", antispam.hasUserMention, antispam.contains_link, "success"}}
	}


local scamCollection = { 
		{"xorbxbot"},
		{{"[^%w]santander", "[^%w]bradesco", "[^%w]nubank"}, {antispam.contains_link}, "credito"},
		{"[^%w]girl", "[^%w]fuck", "[^%w]click", {antispam.contains_link}},
		{"[^%w]fuck", "[^%w]pussy", {antispam.contains_link}},
		{"[^%w]profit[^%w]", "[^%w]contact[^%w]", antispam.hasPriceMention},
		{"[^%w]earning[^%w]", "[^%w]effortless", antispam.hasPriceMention},
		{"[^%w]invest[^%w]",  antispam.hasPriceMention},
		{"[^%w]invest[^%w]", {"[^%w]profit[^%w]", "[^%w]earn[^%w]", "trading"}, antispam.hasPriceMention},
		{"[^%w]retorno[^%w]", "[^%w]dinheiro[^%w]", antispam.hasPriceMention},
		{"[^%w]retorno[^%w]", "[^%w]verificado[^%w]", "[^%w]investidor", antispam.hasPriceMention},
		{"[^%w]day trade[^%w]", "[^%w]transfiro[^%w]", antispam.hasPriceMention},
		{"[^%w]honest", "[^%w]invest", {antispam.hasPriceMention, antispam.contains_link}},
		{"[^%w]honest", "[^%w]invest", {antispam.hasPriceMention, antispam.contains_link}},
		{"[^%w]social media", {"[^%w]crypto", "[^%w]paypal"}, {antispam.hasPriceMention}},
		{"[^%w]instagram", {"[^%w]verified", "[^%w]follower"}, "instant", {antispam.hasPriceMention}},
		{"[^%w]fuck", "[^%w]hot", {"[^%w]join", "[^%w]link"}, {antispam.contains_link}},
		{{"[^%w]dinheiro", antispam.hasPriceMention}, "[^%w]plataforma", {"[^%w]ganhe", "[^%w]ganhei"}, {antispam.contains_link}},
		{"[^%w]seguidor", "[^%w]instagram", {"venda", "venta"}, {antispam.hasPriceMention}},
		{"[^%w]saque", "[^%w]trade", antispam.hasPriceMention},
		{{antispam.hasPriceMention, antispam.contains_link}, {"netflix", "prime"}, {"premium", "sell", "crack"}},
		{"[a-z0-9]bet[a-z0-9]", "download", antispam.contains_link},
		{"free", antispam.hasPriceMention, antispam.hasBotMention, {"deposit", "simple"} },
		{antispam.hasPriceMention, antispam.hasBotMention, {"grab", "rich", "coin", "lux"}, {"slot", "pocket", "wallet", "slow"}, {"fate", "flip", "luck", "🍀", "💵", "🚀", "🔥"} }
	}



function antispam.checkCollection(setList, strLower, original_str, emojiPercent, dbg)
	strLower = " "..strLower.." "
	if dbg then print("scam coll: ") end
	for a, set in pairs(setList) do 
		local ok = 1
		local info = "Matched collection "..a..": ["
		for _, elem in pairs(set) do  
			
			ok , match = antispam.checkInnerElement(elem, strLower, original_str, dbg)
			if dbg then print("Inner element "..ok..' is '..tostring(elem).." on") end
			info = info..tostring(match)..','
			if ok == 0 then  
				if dbg then print("NOOO :9", original_str)  end
				break
			end
		end
		if ok == 1 then
			return 1, info..']'
		end
	end

	if emojiPercent > 0.65 and antispam.contains_link(original_str) and original_str:find("🫰") then 
		return 1, "Emoji percent, found emoji and has link"
	end
	return 0, ""
end

function antispam.hasActualScam(strLower, original_str, emojiPercent)
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
		"social media",
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
		"trump",
	}

	strLower = " "..strLower.." "
	local reason = ""
	local scamCount = 0
	for a, kw in pairs(scamMentions) do  
		if strLower:find("[^%w]"..kw.."[^%w]") then  
			reason = reason .. "Found '"..kw.."' "
			scamCount = scamCount +1
		end
	end

	local hasBot, botname =  antispam.hasBotMention(strLower)
	if emojiPercent > 0.5 and hasBot then  
		return 1, "too much emojis,  and has bot: "..scamCount
	end
 
	if scamCount <= 3 then  
		return antispam.checkCollection(scamCollection, strLower, original_str, emojiPercent)
	end
	if money and phone then  
		return 1, reason
	else 
		if scamCount >= 6 then  
			return 1, reason
		end
		return antispam.checkCollection(scamCollection,strLower, original_str, emojiPercent)
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
-- Standard accented characters
    ['áàãâä'] = 'a', ['ÁÀÃÂÄ'] = 'A',
    ['éèêë'] = 'e', ['ÉÈÊË'] = 'E',
    ['íìîï'] = 'i', ['ÍÌÎÏ'] = 'I',
    ['óòõôö'] = 'o', ['ÓÒÕÔÖ'] = 'O',
    ['úùûü'] = 'u', ['ÚÙÛÜ'] = 'U',
    ['ç'] = 'c', ['Ç'] = 'C',
    ['ñ'] = 'n', ['Ñ'] = 'N',
    
    -- Cyrillic characters that look like Latin (common in spam)
    ['е'] = 'e', ['Е'] = 'E',  -- Cyrillic 'е' (U+0435) vs Latin 'e'
    ['а'] = 'a', ['А'] = 'A',  -- Cyrillic 'а' (U+0430)
    ['о'] = 'o', ['О'] = 'O',  -- Cyrillic 'о' (U+043E)
    ['с'] = 'c', ['С'] = 'C',  -- Cyrillic 'с' (U+0441)
    ['р'] = 'p', ['Р'] = 'P',  -- Cyrillic 'р' (U+0440)
    ['х'] = 'x', ['Х'] = 'X',  -- Cyrillic 'х' (U+0445)
    ['у'] = 'y', ['У'] = 'Y',  -- Cyrillic 'у' (U+0443)
    ['м'] = 'm', ['М'] = 'M',  -- Cyrillic 'м' (U+043C)
    ['т'] = 't', ['Т'] = 'T',  -- Cyrillic 'т' (U+0442)
    ['в'] = 'b', ['В'] = 'B',  -- Cyrillic 'в' (U+0432) - often looks like B
    
    -- Mathematical bold script characters
    ["𝘄"] = "w", ["𝗮"] = "a", ["𝘀"] = "s", ["𝗼"] = "o", ["𝗳"] = "f", 
    ["𝗿"] = "r", ["𝗶"] = "i", ["𝗱"] = "d", ["𝘁"] = "t", ["𝗻"] = "n",
    ["𝘃"] = "v", ["𝗲"] = "e", ["𝗯"] = "b", ["𝗰"] = "c", ["𝗸"] = "k",
    ["𝗽"] = "p", ["𝘆"] = "y", ["𝗹"] = "l", ["𝗺"] = "m", ["𝘂"] = "u",
    
    -- Punctuation normalization
    ["，"] = ",", ["．"] = ".", ["；"] = ";", ["："] = ":", 
    ["？"] = "?", ["！"] = "!", ["（"] = "(", ["）"] = ")",
    ["“"] = '"', ["”"] = '"', ["‘"] = "'", ["’"] = "'",
    
    -- Zero-width spaces and other invisibles
    ["\226\128\139"] = "", -- Zero-width space
    ["\226\128\140"] = "", -- Other zero-width characters
    ["\194\160"] = " ",    -- Non-breaking space
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

function antispam.hasCryptoMention(str, strLower, emojiPercent, original_str)
	local cryptoKeywords = {
		"airdrop",
		"btc",
		"ton",
		"usdt",
		"opensea",
		"crypto",
	}
	strLower = " "..strLower.." "
	str = " "..str.." "
	local hasMentionOf = ""
	local hasAnuncio = false
	for a, kw in pairs(cryptoKeywords) do  
		local e,b = strLower:find(headRegexp..kw..headRegexp)
		
		if e then  
			hasAnuncio = true
			hasMentionOf = "Has mention of '"..kw.."'"
			break
		end
	end

	if str:match("[^%w]%$([A-Z]+)[^%w]") then 
		return 1, hasMentionOf.." and mentions directly an crypto currency"
	end

	local hasBot, botname =  antispam.hasBotMention(strLower)
	if hasBot == 1 and botname:match("ton") then  
		return 1
	end

	if not hasAnuncio then  

		if emojiPercent > 0.65 and antispam.hasBotMention(strLower) == 1 and strLower:match("ton") then  
			return 1, hasMentionOf.." and has emoji or bot mention"
		end
		return antispam.checkCollection(cryptoCollection, strLower, original_str, emojiPercent)
	end

	if emojiPercent > 0.7 and antispam.hasBotMention(strLower) == 1 and strLower:match("ton") then  
		return 1, hasMentionOf.." and has emoji or bot mention"
	end
	return antispam.checkCollection(cryptoCollection, strLower, original_str, emojiPercent)
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
	str = antispam.remove_accents(str)
	str = str:gsub("%s"," ")
	local emojiLen = 0
	for a, entity in pairs(msg.entities or msg.caption_entities or msg.description_entities) do 
		if entity.type == 'custom_emoji' then  
			if not entity.length then  
				entity.length = entity.text:len()
			end
			emojiLen = emojiLen + entity.length
		end
	end
	return emojiLen/(str:len()+emojiLen)
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

			local keyb = {}
		    keyb[1] = {}
		    keyb[2] = {}
		    keyb[1][1] = { text = "Falso positivo", callback_data = "delpls"} 
		    keyb[2][1] = { text = "Apagar spam e banir", callback_data = "banspam:"..msg.message_id..":"..msg.from.id} 
		    local kb = cjson.encode({inline_keyboard = keyb })
			bot.sendMessage(chatid, "Encontrado spam do tipo "..class.."\n"..breakdown, "HTML", true, false, msg.message_id, kb)

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

			local keyb = {}
		    keyb[1] = {}
		    keyb[2] = {}
		    keyb[1][1] = { text = "Falso positivo", callback_data = "delpls"} 
		    keyb[2][1] = { text = "Apagar spam e banir", callback_data = "banspam:"..msg.message_id..":"..msg.from.id} 
		    local kb = cjson.encode({inline_keyboard = keyb })
			bot.sendMessage(chatid, "Encontrado spam do tipo "..class.."\n"..breakdown, "HTML", true, false, msg.message_id, kb)

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

			local keyb = {}
		    keyb[1] = {}
		    keyb[2] = {}
		    keyb[1][1] = { text = "Falso positivo", callback_data = "delplsno"} 
		    keyb[2][1] = { text = "Apagar spam e banir", callback_data = "banspam:"..msg.message_id..":"..msg.from.id} 
		    local kb = cjson.encode({inline_keyboard = keyb })
			bot.sendMessage(chatid, "Encontrado spam do tipo "..class.."\n"..breakdown, "HTML", true, false, msg.message_id, kb)

			bot.sendMessage(5146565303, "Encontrado spam do tipo "..class.."\n"..breakdown..'\nNo chat: '..chatid)
			local res = bot.forwardMessage(5146565303, msg.from.id, false, msg.message_id)
			if not res.ok then  
				bot.sendMessage(5146565303, "Spam found: \n"..str)
			end
		end
	end
end

function antispam.onCallbackQueryReceive(msg)
	if msg.message then
		if msg.data:match("banspam:(.-):(.-)") then
			local msgid, usr =  msg.data:match("banspam:(.-):(.-)")
			deploy_deleteMessage(msg.message.chat.id, tonumber(msgid))
			deploy_deleteMessage(msg.message.chat.id, msg.message.message_id)
			deploy_answerCallbackQuery(msg.id, "Please solve the captcha :D", "true")
			bot.banChatMember(msg.chat.id, tonumber(usr), 0, true)
		elseif msg.data == "delplsno" then  
			deploy_deleteMessage(msg.message.chat.id, msg.message.message_id)
			deploy_answerCallbackQuery(msg.id, "Foi mal ae", "true")
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


return antispam