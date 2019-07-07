QuickBankStacker = {}

QuickBankStacker.name = "QuickBankStacker"
QuickBankStacker.author = "Wintertoad"
QuickBankStacker.version = "1.0"
QuickBankStacker.savedVariables = {}
QuickBankStacker.defaultVariables = {
	autoStack = false,
	noConsumables = true,
	overStack = false,
}

local function SetToolTip(ctrl, text)
    ctrl:SetHandler("OnMouseEnter", function(self)
        ZO_Tooltips_ShowTextTooltip(self, TOP, text)
    end)
    ctrl:SetHandler("OnMouseExit", function(self)
        ZO_Tooltips_HideTextTooltip()
    end)
end

local function LogToChat(text)
	d("|c2196F3"..QuickBankStacker.name.."|r|cFFFFFF: "..text.."|r")
end

local function BankItem(bagItemSlot, bankItemSlot, amount)
	if IsProtectedFunction("RequestMoveItem") then
		CallSecureProtected("RequestMoveItem", BAG_BACKPACK, bagItemSlot, BAG_BANK, bankItemSlot, amount)
	else
		RequestMoveItem(BAG_BACKPACK, bagItemSlot, BAG_BANK, bankItemSlot, amount)
	end
end

function QuickBankStacker:QuickStack(manual)
	local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
	local bankCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BANK)
	
	local stacked = 0
	
	for bankItemSlot, bankItemData in pairs(bankCache) do
		if self.savedVariables.noConsumables and (bankItemData.itemType == ITEMTYPE_DRINK or bankItemData.itemType == ITEMTYPE_FOOD or bankItemData.itemType == ITEMTYPE_LOCKPICK 
								or bankItemData.itemType == ITEMTYPE_LURE or bankItemData.itemType == ITEMTYPE_POISON or bankItemData.itemType == ITEMTYPE_POTION
								or bankItemData.itemType == ITEMTYPE_SOUL_GEM) then
			break
		end
		
		local bankCurStack, bankMaxStack = GetSlotStackSize(BAG_BANK, bankItemSlot)
		
		if self.savedVariables.overStack or (bankCurStack < bankMaxStack) then
			for bagItemSlot, bagItemData in pairs(bagCache) do
				if bankItemData.rawName == bagItemData.rawName then
					local bagCurStack, bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagItemSlot)
					local amount = 0
					if self.savedVariables.overStack then
						if bagCurStack > bankMaxStack - bankCurStack then
							if DoesBagHaveSpaceFor(BAG_BANK, BAG_BACKPACK, bagItemSlot) then
								amount = bankMaxStack - bankCurStack
								BankItem(bagItemSlot, bankItemSlot, amount)
								amount = bagCurStack - amount
								bankItemSlot = FindFirstEmptySlotInBag(BAG_BANK)
							else
								break
							end
						else
							amount = bagCurStack
						end
					else
						amount = zo_min(bagCurStack, bankMaxStack - bankCurStack)
					end
					
					BankItem(bagItemSlot, bankItemSlot, amount)
					
					stacked = stacked + 1
				end
			end
		end
	end
	
	if manual and stacked == 0 then
		LogToChat("Nothing to stack")
	else
		LogToChat(zo_strformat("Stacked <<1>> items", stacked))
	end
	
end

function QuickBankStacker:EVENT_OPEN_BANK(...)
	if self.savedVariables.autoStack then
		self:QuickStack(false)
	end
end


function QuickBankStacker:CreateLAM2Panel()
	local panelData = {
		type = "panel",
		name = "Quick Bank Stacker",
		displayName = ZO_HIGHLIGHT_TEXT:Colorize("Quick Bank Stacker"),
		author = self.author,
		version = self.version,
	}

	local optionsData = {
		{
			type = "checkbox",
			name = "AutoStack",
			tooltip = "Automatically stack items on opening bank.",
			getFunc = function() return self.savedVariables.autoStack end,
			setFunc = function(value) self.savedVariables.autoStack = value end,
		},
		{
			type = "checkbox",
			name = "Overstack",
			tooltip = "Deposit whole stack even if it would create a new stack in bank.",
			getFunc = function() return self.savedVariables.overStack end,
			setFunc = function(value) self.savedVariables.overStack = value end,
		},
		{
			type = "checkbox",
			name = "Ignore consumables",
			tooltip = "Ignores drinks, food, lockpicks, lures, poisons, potions and soul gems.",
			getFunc = function() return self.savedVariables.noConsumables end,
			setFunc = function(value) self.savedVariables.noConsumables = value end,
		}
	}

	local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
	LAM2:RegisterAddonPanel(QuickBankStacker.name.."LAM2Options", panelData)
	LAM2:RegisterOptionControls(QuickBankStacker.name.."LAM2Options", optionsData)
end

function QuickBankStacker:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if (addOnName == QuickBankStacker.name) then
		EVENT_MANAGER:UnregisterForEvent(QuickBankStacker.name, EVENT_ADD_ON_LOADED)

		self.savedVariables = ZO_SavedVars:New("QBSSV", 1, nil, self.defaultVariables)
		 
		SetToolTip(QBSStackButton, "Quick Stack")
		local fragment = ZO_SimpleSceneFragment:New(QBSStackTLC)
		local scene = SCENE_MANAGER:GetScene("bank")
		scene:AddFragment(fragment)

		self:CreateLAM2Panel()

		EVENT_MANAGER:RegisterForEvent(QuickBankStacker.name, EVENT_OPEN_BANK, function(...) QuickBankStacker:EVENT_OPEN_BANK(...) end)
	end
end

EVENT_MANAGER:RegisterForEvent(QuickBankStacker.name, EVENT_ADD_ON_LOADED, function(...) QuickBankStacker:EVENT_ADD_ON_LOADED(...) end)
