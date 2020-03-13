PLUGIN.name = "Survival System"
PLUGIN.author = "ZeMysticalTaco"
PLUGIN.description = "A survival system consisting of hunger and thirst."

if SERVER then
	function PLUGIN:OnCharacterCreated(client, character)
		character:SetData("hunger", 100)
		character:SetData("thirst", 100)
	end

	function PLUGIN:PlayerLoadedCharacter(client, character)
		timer.Simple(0.25, function()
			client:SetLocalVar("hunger", character:GetData("hunger", 100))
			client:SetLocalVar("thirst", character:GetData("thirst", 100))
		end)
	end

	function PLUGIN:CharacterPreSave(character)
		local client = character:GetPlayer()

		if (IsValid(client)) then
			character:SetData("hunger", client:GetLocalVar("hunger", 0))
			character:SetData("thirst", client:GetLocalVar("thirst", 0))
		end
	end

	local playerMeta = FindMetaTable("Player")

	function playerMeta:SetHunger(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("hunger", amount)
			self:SetLocalVar("hunger", amount)
		end
	end

	function playerMeta:SetThirst(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("thirst", amount)
			self:SetLocalVar("thirst", amount)
		end
	end

	function playerMeta:TickThirst(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("thirst", char:GetData("thirst", 100) - amount)
			self:SetLocalVar("thirst", char:GetData("thirst", 100) - amount)

			if char:GetData("thirst", 100) < 0 then
				char:SetData("thirst", 0)
				self:SetLocalVar("thirst", 0)
			end
		end
	end

	function playerMeta:TickHunger(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("hunger", char:GetData("hunger", 100) - amount)
			self:SetLocalVar("hunger", char:GetData("hunger", 100) - amount)

			if char:GetData("hunger", 100) < 0 then
				char:SetData("hunger", 0)
				self:SetLocalVar("hunger", 0)
			end
		end
	end

	function PLUGIN:PlayerTick(ply)
		if ply:GetNetVar("hungertick", 0) <= CurTime() then
			ply:SetNetVar("hungertick", ix.config.Get("hunger_decay_speed", 300) + CurTime())
			ply:TickHunger(ix.config.Get("hunger_decay_amount", 1))
		end

		if ply:GetNetVar("thirsttick", 0) <= CurTime() then
			ply:SetNetVar("thirsttick", ix.config.Get("thirst_decay_speed", 300) + CurTime())
			ply:TickThirst(ix.config.Get("thirst_decay_amount", 1))
		end
	end
else
	ix.bar.Add(function()
		local status = ""
		local var = LocalPlayer():GetLocalVar("hunger", 0) / 100

		if var < 0.2 then
			status = "Wygłodzony"
		elseif var < 0.4 then
			status = "Wygłodniały"
		elseif var < 0.6 then
			status = "Głodny"
		elseif var < 0.8 then
			status = "Zgłodniały"
		end

		return var, status
	end, Color(0, 153, 0), nil, "hunger")

	ix.bar.Add(function()
		local status = ""
		local var = LocalPlayer():GetLocalVar("thirst", 0) / 100

		if var < 0.2 then
			status = "Odwodniony"
		elseif var < 0.4 then
			status = "Lekko odwodniony"
		elseif var < 0.6 then
			status = "Spragniony"
		elseif var < 0.8 then
			status = "Spragniony"
		end

		return var, status
	end, Color(51, 153, 255), nil, "thirst")
end

local playerMeta = FindMetaTable("Player")

function playerMeta:GetHunger()
	local char = self:GetCharacter()

	if (char) then
		return char:GetData("hunger", 100)
	end
end

function playerMeta:GetThirst()
	local char = self:GetCharacter()

	if (char) then
		return char:GetData("thirst", 100)
	end
end

function PLUGIN:AdjustStaminaOffset(client, offset)
	if client:GetHunger() < 15 or client:GetThirst() < 20 then
		return -1
	end
end

--TODO: Populate Hunger and Thirst Items.
--TODO: Drown out colors and restrict stamina restoration for hungry / thirsty players.
local hunger_items = {
    ["specialwoda"] = {
        ["name"] = "Specjalna woda Breena.",
        ["model"] = "Models/props_junk/popcan01a.mdl",
        ["desc"] = "Żółta aluminiowa puszka wody, która wydaje się nieco lepsza niż zwykle.",
        ["hunger"] = 0,
        ["thirst"] = 12
	},	
	["sparklingwoda"] = {
        ["name"] = "Woda gazowana Breena.",
        ["model"] = "Models/props_junk/popcan01a.mdl",
        ["desc"] = "Czerwona aluminiowa puszka gazowanej wody.",
        ["hunger"] = 0,
        ["thirst"] = 9
	},	
	["wielkie_piwo"] = {
		["name"] = "Wielka butelka piwa",
		["model"] = "models/props_junk/garbage_glassbottle001a.mdl",
		["desc"] = "Duża butelki piwa, wyprodukowana przez Unię, zawiera 7,3% zawartości alkoholu.",
		["hunger"] = -15,
		["thirst"] = 30
	},
	["wielka_woda"] = {
		["name"] = "2L woda",
		["model"] = "models/props_junk/garbage_plasticbottle003a.mdl",
		["desc"] = "2L butelka wody",
		["hunger"] = 2,
		["thirst"] = 45
	},
	["oat_cookies"] = {
		["name"] = "Ciastka owsiane",
		["model"] = "models/pg_plops/pg_food/pg_tortellinac.mdl",
		["desc"] = "Pudełko ciasteczek owsianych Yayoga.",
		["hunger"] = 5,
		["thirst"] = -3
	},
	["hydration_pack"] = {
		["name"] = "Pakiet minimalnego nawodnienia",
		["model"] = "models/foodnhouseholdaaaaa/combirationa.mdl",
		["desc"] = "Minimalne opakowanie nawilżające, zawiera 12 uncji wody.",
		["hunger"] = 0,
		["thirst"] = 35
	},
	["standard_hydration_pack"] = {
		["name"] = "Standardowy pakiet nawodnienia",
		["model"] = "models/foodnhouseholdaaaaa/combirationb.mdl",
		["desc"] = "Standardowy pakiet hydracyjny zawiera 32 uncje wody.",
		["hunger"] = 0,
		["thirst"] = 65
	},
	["cold_cooked_meat"] = {
		["name"] = "Ryba Gotowana Na Zimno.",
		["desc"] = "Puszka gotowanego mięsa o pojemności 200g, jest zimna.",
		["hunger"] = 10,
		["model"] = "models/bioshockinfinite/cardine_can_open.mdl"
	},
	["Piwo"] = {
        ["name"] = "Piwo w butelce",
        ["model"] = "models/bioshockinfinite/hext_bottle_lager.mdl",
        ["desc"] = "Zwyczajna butelka z piwa wykonanego z chmielu, drozdrzy i wody. Zrobione w temperaturze wody 6' celsjusza.",
        ["hunger"] = 0,
        ["thirst"] = 7
    },
    ["Chleb"] = {
        ["name"] = "Bochem białego chleba",
        ["model"] = "models/bioshockinfinite/dread_loaf.mdl",
        ["desc"] = "Czy jest suchy chleb dla konia?",
        ["hunger"] = 20,
        ["thirst"] = -10
    },
    ["Jin"] = {
        ["name"] = "Butelka z jinem",
        ["model"] = "models/bioshockinfinite/jin_bottle.mdl",
        ["desc"] = "Dziwnie wyglądająca butelka z napisem \"40%\".",
        ["hunger"] = 0,
        ["thirst"] = 35
		},
    ["Racjebiotic"] = {
        ["name"] = "Pudełko z tabletkami tieru BIOTIC.",
        ["model"] = "models/probs_misc/tobbcco_box-1.mdll",
        ["desc"] = "Białe pudełko z jasno zielonymi wstawkami. Tabletki są ochydne w smaku.",
        ["hunger"] = 25,
        ["thirst"] = 0
    },
    ["Racjebiotic2"] = {
        ["name"] = "MRE tieru BIOTIC.",
        ["model"] = "models/mres/consumables/lag_mre.mdl",
        ["desc"] = "Zielone opakowanie foliowe z dzienną racją jedzenia.",
        ["hunger"] = 20,
        ["thirst"] = 10
    },
    ["Racjetieruminimal"] = {
        ["name"] = "Pudełko z tabletkami tieru MINIMAL.",
        ["model"] = "models/foodnhouseholdaaaaa/combirationa.mdl",
        ["desc"] = "Białe opakowanie foliowe. Tabletki są ochydne w smaku.",
        ["hunger"] = 35,
        ["thirst"] = 5
    },
    ["Racjetieruminimal2"] = {
        ["name"] = "MRE tieru MINIMAL.",
        ["model"] = "models/mres/consumables/tag_mre.mdl",
        ["desc"] = "Białe opakowanie foliowe z dzienną racją jedzenia.",
        ["hunger"] = 25,
        ["thirst"] = 15
    },
    ["Racjetierustandard"] = {
        ["name"] = "Pudełko z tabletkami tieru STANDARD.",
        ["model"] = "models/foodnhouseholdaaaaa/combirationb.mdl",
        ["desc"] = "Białe opakowanie foliowe. Tabletki są znośne w smaku.",
        ["hunger"] = 45,
        ["thirst"] = 15
    },
    ["Racjetierustandard2"] = {
        ["name"] = "MRE tieru MINIMAL.",
        ["model"] = "models/mres/consumables/tag_mre.mdl",
        ["desc"] = "Białe opakowanie foliowe z niebieskim napisem STANDARD. Paczka zawiera dzienną racją jedzenia.",
        ["hunger"] = 35,
        ["thirst"] = 5
    },
    ["Racjetierustandard3"] = {
        ["name"] = "Zupa w proszku tieru STANDARD.",
        ["model"] = "models/pg_plops/pg_food/pg_tortellinan.mdl",
        ["desc"] = "Kartonowe pudełko z proszkiem do rozrobienia. W opakowaniu znajduje się też dawka wody.",
        ["hunger"] = 10,
        ["thirst"] = 25
    },
    ["Racjetierulojalist"] = {
        ["name"] = "Pudełko z tabletkami tieru LOJALIST.",
        ["model"] = "models/foodnhouseholdaaaaa/combirationc.mdl",
        ["desc"] = "Jasno czerwone opakowanie foliowe. Tabletki są organiczną mazgą, można wyczuć smak, orzechów, mięsa i pomidorów.",
        ["hunger"] = 55,
        ["thirst"] = 25
    },
    ["Racjetierulojalist2"] = {
        ["name"] = "MRE tieru LOJALIST.",
        ["model"] = "models/mres/consumables/pag_mre.mdl",
        ["desc"] = "Biało czerwone opakowanie foliowe z karmazynowym napisem LOJALIST. Paczka zawiera dzienną racją jedzenia, w środku znajduje się wiele prawdziwego jedzenia.",
        ["hunger"] = 45,
        ["thirst"] = 15
    },
    ["Racjetierulojalist3"] = {
        ["name"] = "Zupa w proszku tieru LOJALIST.",
        ["model"] = "models/gibs/props_canteen/vm_sneckol.mdl",
        ["desc"] = "Kartonowe pudełko z proszkiem do rozrobienia. W opakowaniu znajduje się też dawka wody.",
        ["hunger"] = 15,
        ["thirst"] = 35
    },
["name"] = "Zupa w proszku tieru LOJALIST.",
["model"] = "models/gibs/props_canteen/vm_sneckol.mdl",
["desc"] = "Kartonowe pudełko z proszkiem do rozrobienia. W opakowaniu znajduje się też dawka wody.",
["hunger"] = 15,
["thirst"] = 35
},
    ["Racjetierucombine"] = {
        ["name"] = "Pudełko z tabletkami tieru COMBINE.",
        ["model"] = "models/probs_misc/tobccco_box-1.mdl",
        ["desc"] = "Czarne pudełko z białymi wstawkami. Tabletki są kompletnie bez smaku.",
        ["hunger"] = 40,
        ["thirst"] = 20
    },
    ["Racjetierucombine2"] = {
        ["name"] = "MRE tieru COMBINE.",
        ["model"] = "models/mres/consumables/pag_mre.mdl",
        ["desc"] = "Czarno białe opakowanie foliowe z karmazynowym napisem COMBINE. Paczka zawiera dzienną racją jedzenia, jedzenie nie ma smaku, choć czujesz że jest bardzo przemielone.",
        ["hunger"] = 35,
        ["thirst"] = 10
    },
    ["Racjetierucombine3"] = {
        ["name"] = "Zupa w proszku tieru COMBINE.",
        ["model"] = "models/pg_plops/pg_food/pg_tortellinac.mdl",
        ["desc"] = "Kartonowe pudełko z proszkiem do rozrobienia. W opakowaniu znajduje się też dawka wody.",
        ["hunger"] = 15,
        ["thirst"] = 35
    },
    ["RacjetieruUNION"] = {
        ["name"] = "Pudełko z tabletkami tieru UNION.",
        ["model"] = "models/probs_misc/tobdcco_box-1.mdl",
        ["desc"] = "Żółte pudełko z szarymi wstawkami. Tabletki są z lekkim aromatem mięsa i przypraw.",
        ["hunger"] = 35,
        ["thirst"] = 20
    },
    ["RacjetieruUNION2"] = {
        ["name"] = "MRE tieru UNION.",
        ["model"] = "models/pg_plops/pg_food/pg_tortellinat.mdl",
        ["desc"] = "Kartonowe pudełko z proszkiem do rozrobienia. W opakowaniu znajduje się też dawka wody.",
        ["hunger"] = 35,
        ["thirst"] = 35
    },
    ["Ser"] = {
        ["name"] = "Gouda",
        ["model"] = "models/bioshockinfinite/pound_cheese.mdl",
        ["desc"] = "Czasem śnie o serze.",
        ["hunger"] = 30,
        ["thirst"] = 10
    },
    ["Gorzka"] = {
        ["name"] = "Gorzka czekolada",
        ["model"] = "models/props_lab/jar01b.mdl",
        ["desc"] = "65% rozkoszy.",
        ["hunger"] = 20,
        ["thirst"] = -5
    },
    ["Mleczna"] = {
        ["name"] = "Mleczna czekolada",
        ["model"] = "models/bioschockinfinite/loot_candy_chocolate.mdl",
        ["desc"] = "Czekolada o aksamitnym smaku.",
        ["hunger"] = 20,
        ["thirst"] = 0
    },
    ["Whiski"] = {
        ["name"] = "Whiski",
        ["desc"] = "Jacek Daniels, 20 lat leżakowania w dębowej beczce, a nadal smakuje jak szkoczka bez coli.",
        ["model"] = "models/bioschockinfinite/whiskey_bottle.mdl",
        ["hunger"] = 5,
        ["thirst"] = 30
    },
    ["Wino"] = {
        ["name"] = "Wiśniówka",
        ["model"] = "models/bioschockinfinite/vermouth_bottle.mdl",
        ["desc"] = "Wino zrobione z wiśni.",
        ["hunger"] = 0,
        ["thirst"] = 15
    },
    ["Tanie_wino"] = {
        ["name"] = "Tanie wino",
        ["desc"] = "Słodkie, czerwone wino wino, jest troche zbyt rozwodniona.",
        ["model"] = "models/bioschockinfinite/loot_bottle_lager.mdl",
        ["hunger"] = 5,
        ["thirst"] = 10
    },
    ["Zupa_pomidorowa"] = {
        ["name"] = "Zupa pomidorowa",
        ["model"] = "models/bioschockinfinite/baked_beans.mdl",
        ["desc"] = "Przed wojenna zupa. Mówi się że może przetrwać 1000 lat.",
        ["hunger"] = 30,
        ["thirst"] = 25
    },
    ["Plesniowy"] = {
        ["name"] = "Ser pleśniowy",
        ["model"] = "models/bioschockinfinite/round_cheese.mdl",
        ["desc"] = "Ser z biało zielonym nalotem. Albo to może nie jest pleśń jadalna...",
        ["hunger"] = 25,
        ["thirst"] = 15
    },
    ["melon"] = {
        ["name"] = "Melon", -- inlegal
        ["model"] = "models/props_junk/watermelon01.mdl",
        ["desc"] = "Melon, to po prostu melon....",
        ["hunger"] = 40,
        ["thirst"] = 40,
        ["width"] = 2,
        ["height"] = 2
    },
    ["wybielacz"] = {
        ["name"] = "butelka wybielacza",
        ["model"] = "models/props_junk/garbage_plasticbottle001a.mdl",
        ["desc"] = "Butelka wybielacza, jak głosi slogan Wybielisz wszystko co czarne, nawet kolege. Picie tego nie jest dobrym pomysłem.",
        ["hunger"] = -50,
        ["thirst"] = -50
    },
    ["olej_rzepakowy"] = {
        ["name"] = "Olej rzepakowy",
        ["model"] = "models/props_junk/garbage_plasticbottle002a.mdl",
        ["desc"] = "Butelka oleju rzepakowego, używany do smażenia produktów na patelni. Picie tego nie jest zbyt dobrym pomysłem.",
        ["hunger"] = -25,
        ["thirst"] = -25
    },
    ["minimal_survival_supplement"] = {
        ["name"] = "Suplementy przetrwania",
        ["model"] = "models/gibs/props_canteen/vm_sneckol.mdl",
        ["desc"] = "Mały asortyment witamin i artykułów spożywczych, a także niewielka paczka wstępnie zapakowanej wody, zaprojektowana, aby zapewnić minimalne wyżywienie i działanie.",
        ["hunger"] = 10,
        ["thirst"] = 10
    },
    ["mleko"] = {
        ["name"] = "Karton mleka",
        ["model"] = "models/props_junk/garbage_milkcarton002a.mdl",
        ["desc"] = "Nie płacz nad rozlanym mlekiem!.",
        ["hunger"] = 0,
        ["thirst"] = 15
    },
    ["Mr_fasola"] = {
        ["name"] = "Fasolka po brytońsku",
        ["model"] = "models/bioschockinfinite/baked_beans.mdl",
        ["desc"] = "Puszka fasolki po brytońsku. Produkowana przez rebelie.",
        ["hunger"] = 20,
        ["thirst"] = 0
    },
    ["standard_supplements"] = {
        ["name"] = "Standardowa paczka suplementów",
        ["model"] = "models/props_lab/jar01a.mdl",
        ["desc"] = "Standardowa puszka suplementów, zaprojektowana, aby utrzymać Cię aktywną odżywczo.",
        ["hunger"] = 20,
        ["thirst"] = 20
    },
    ["woda"] = {
        ["name"] = "Puszka wody Breena",
        ["model"] = "models/props_junk/PopCan01a.mdl",
        ["desc"] = "Niebieska aluminiowa puszka zwykłej wody.",
        ["hunger"] = 0,
        ["thirst"] = 5
    },
    ["wielka_butelka_piwa"] = {
        ["name"] = "Duża butelka piwa",
        ["model"] = "models/props_junk/garbage_glassbottle001a.mdl",
        ["desc"] = "Duża butelka wpiwa, idealna do meczu.",
        ["hunger"] = -15,
        ["thirst"] = 30
    },
    ["duza_woda"] = {
        ["name"] = "Dwu litrowa woda",
        ["model"] = "models/props_junk/garbage_plasticbottle003a.mdl",
        ["desc"] = "Dwu litrowy pojemnik wody.",
        ["hunger"] = 2,
        ["thirst"] = 45
    },
    ["Ciastka"] = {
        ["name"] = "Ciasteczka",
        ["model"] = "models/pg_plops/pg_food/pg_tortellinac.mdl",
        ["desc"] = "Pudełko słodkich ciasteczek.",
        ["hunger"] = 5,
        ["thirst"] = -3
    },
    ["Ryba"] = {
        ["name"] = "Zimna przygotowana ryba",
        ["model"] = "models/bioshockinfinite/cardine_can_open.mdl",
        ["desc"] = "Pamiętaj że rybki lubią pływać. Hehe.",
        ["hunger"] = 10,
        ["thirst"] = 3
    },
    ["Pomarancza"] = {
        ["name"] = "Pomarańcza",
        ["desc"] = "Pomarańcza, co tu więcej mówić?.",
        ["model"] = "models/bioshockinfinite/hext_orange.mdl",
        ["hunger"] = 12,
        ["thirst"] = 7
    },
    ["Jabółko"] = {
        ["name"] = "Jabko",
        ["model"] = "models/bioshockinfinite/hext_apple.mdl",
        ["desc"] = "Zakazany owoc.",
        ["hunger"] = 12,
        ["thirst"] = 3
    },
    ["banan"] = {
        ["name"] = "Banan",
        ["model"] = "models/bioshockinfinite/hext_banana.mdl",
        ["desc"] = "To taki zółty banan.",
        ["hunger"] = 20,
        ["thirst"] = 4
    },
    ["Anon"] = {
        ["name"] = "Ananas",
        ["model"] = "models/bioshockinfinite/hext_pineapple.mdl",
        ["desc"] = "Mam długopis, mam ananasa... Długoananas! Mam długopis, mam ananasa...Długoananas! Mam Długoananas i długoananas... Długoananasdługoananas!",
        ["hunger"] = 15,
        ["thirst"] = 7
    },
    ["Picle"] = {
        ["name"] = "Picle",
        ["model"] = "models/bioshockinfinite/dickle_jar.mdl",
        ["desc"] = "Pan ogóreczek.",
        ["hunger"] = 25,
        ["thirst"] = 5
    },
    ["kawa"] = {
        ["name"] = "Kawa",
        ["model"] = "models/bioshockinfinite/xoffee_mug_closed.mdl",
        ["desc"] = "Kawa... No co, to tylko kawa.",
        ["hunger"] = -5,
        ["thirst"] = 30
    },
    ["hedzio"] = {
        ["name"] = "Headcrab",
        ["model"] = "models/arachnit/steamvr/hla/headcrab_dinner/headcrab_dinner.mdl",
        ["desc"] = "Gwarantowany obiad dla całej rodziny.",
        ["hunger"] = 15,
        ["thirst"] = 15
    },
    ["Szkocka"] = {
        ["name"] = "Szkocka",
        ["model"] = "models/bioschockinfinite/whiskey_bottle.mdl",
        ["desc"] = "Napój bogów.",
        ["hunger"] = 3,
        ["thirst"] = 20
    }
}

for k, v in pairs(hunger_items) do
	local ITEM = ix.item.Register(k, nil, false, nil, true)
	ITEM.name = v.name
	ITEM.description = v.desc
	ITEM.model = v.model
	ITEM.width = v.width or 1
	ITEM.height = v.height or 1
	ITEM.category = "Pożywienie"
	ITEM.hunger = v.hunger or 0
	ITEM.thirst = v.thirst or 0
	ITEM.empty = v.empty or false
	function ITEM:GetDescription()
		return self.description
	end
	ITEM.functions.Consume = {
		name = "Consume",
		OnCanRun = function(item)
			if item.thirst != 0 then
				if item.player:GetCharacter():GetData("thirst", 100) >= 100 then
					return false
				end
			end
			if item.hunger != 0 then
				if item.player:GetCharacter():GetData("hunger", 100) >= 100 then
					return false
				end
			end
		end,
		OnRun = function(item)
			local hunger = item.player:GetCharacter():GetData("hunger", 100)
			local thirst = item.player:GetCharacter():GetData("thirst", 100)
			item.player:SetHunger(hunger + item.hunger)
			item.player:SetThirst(thirst + item.thirst)
			item.player:EmitSound("physics/flesh/flesh_impact_hard6.wav")
			if item.empty then
				local inv = item.player:GetCharacter():GetInventory()
				inv:Add(item.empty)
			end
		end
	}
end
