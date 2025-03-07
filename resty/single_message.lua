
local antispam = dofile("antispam.lua")

local tgMsg = {
    text = [[
🔹Venta de Seguidores Instagram. 📷


5.000 = $10000 / 10 usdt✅
10.000 = $18000 / 18 usdt✅
15.000 = $24000 / 24 usdt✅
20.000 = $30000 / 30 usdt✅

🔴 Instagram Likes. 📷

 5.000 = $5000 / 5 usdt✅
10.000 = $ 7000 / 7 usdt✅
20.000 = $13000 / 13 usdt✅
30.000 = $18000 / 18 usdt✅
40.000 = $27000 / 27 usdt✅
50.000 = $35000 / 35 usdt✅

💰Payment : ARS, BTC, LTC, UDST, PIX 🧩🧩🧩

Consultar por otras redes sociales como tiktok, Twitter y más. 📱📱📱📱📱

Tiempo de llegada | 1min - 24h. 

CONTACTO/REFERENCIAS
]],
    entities = {}
}
        
       
      local isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
        if not isDanger then  
            antispam.DEBUG = true
            isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
            print("MESSAGE TYPE="..class)
            print(real)
            print(breakdown)
            print('----------------------------------------------')
            error("Danger message~")
        end