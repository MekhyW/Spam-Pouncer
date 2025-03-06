
local antispam = dofile("antispam.lua")

local tgMsg = {
    text = [[
✨YCH AUCTION✨

👅Pred-
SB: $50
AB: -

💦Prey-
SB: $35
AB: -

🤍Min: $5

-Any species.
-Custom expression.
-Lineart Fullcolor.
-Payment via Paypal.

END IN 48 HOURS!

Claim in the comments of My channel https://t.me/surymaws⤵️⤵️
]],
    entities = {}
}
        
       
      local isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
        if isDanger then  
            antispam.DEBUG = true
            isDanger, class, breakdown = antispam.classifyMessageDanger(tgMsg)
            print("MESSAGE TYPE="..class)
            print(real)
            print(breakdown)
            print('----------------------------------------------')
            error("Danger message~")
        end