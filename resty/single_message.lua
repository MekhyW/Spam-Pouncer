
local antispam = dofile("antispam.lua")

local tgMsg = {
    text = [[
Spam found: 
🌙100 SUB ART RAFFLE! 🌙
- Follow me in all social media (Bluesky and Twitter).
- Comment (SFW ref).
- Share this Post with another group or channel

🥇 The PRIZE will be an Icon, preferably in the style indicated
(ends within 24hrs) 
GOOD LUCK!

🌙SORTEIO DE 100 INSCRITOS! 🌙
- Me siga em todas as redes sociais (Twiiter e Bluesky).
- Comente seu Ref Sheet (SFW ref).
- Compartilhe esse post em outro grupo ou canal

🥇 A RECOMPENSA será um Icon, no estilo indicado de preferência
(fecha em 24hrs) 
BOA SORTE!
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