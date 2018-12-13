local _AddonName, _Addon = ...;


local _ScrollFrame = nil;
local _itemFramesPool = nil;
local _FavoriteDropDown = nil;
local _SetsDataProvider = nil;
local _ButtonHeight = nil;
local _BaseSets = {};
local _VariantSets = {};
local _SelectedID = nil;
local testsets = {};
local CurrentID = nil;
local DEBUG = false;

local BASE_SET_BUTTON_HEIGHT = 46;
local VARIANT_SET_BUTTON_HEIGHT = 20;
local SET_PROGRESS_BAR_MAX_WIDTH = 204;
local IN_PROGRESS_FONT_COLOR = CreateColor(0.251, 0.753, 0.251);
local IN_PROGRESS_FONT_COLOR_CODE = "|cff40c040";


function ModGetVariantSets(SetID)
	local englishFaction, localizedFaction = UnitFactionGroup('player');
	local UsableIDs = GetClassIDs();
	local ReturnVariantSets = { };
	local found = false;
	for index, data in ipairs(_VariantSets) do
		if data.baseSetID == SetID then
			found = true;
			table.insert(ReturnVariantSets,data);
	    end
	end
	return ReturnVariantSets;
end

function GetSetByID(SetID)
	for index, data in ipairs(_BaseSets) do
		if data.setID == SetID then
			return data;
		end
	end
	return nil;
end

function GetBaseSetID(SetID)
	--print("Buscando set...")
	for index, data in ipairs(_VariantSets) do
		if data.setID == SetID then
			--print("Encontre uno :");
			--print(to_string(data));
			return data.baseSetID;
		end
	end
	--print("No encontre una mierda");
	return SetID;
end





function GetClassIDs()
	local localizedClass, englishClass, classIndex = UnitClass('player');
	local ClassIDs = {}
	local MyClassID = nil;
	local ComClass = nil;
	if classIndex == 1 or classIndex == 2 or classIndex == 6 then -- Warrior, Pala, DK
		table.insert(ClassIDs,1);
		table.insert(ClassIDs,2);
		table.insert(ClassIDs,32);
		table.insert(ClassIDs,35);
	elseif classIndex == 3 or classIndex == 7 then -- Hunter, Shaman
		table.insert(ClassIDs,4);
		table.insert(ClassIDs,64);
		table.insert(ClassIDs,68);
	elseif classIndex == 4 or classIndex == 10 or classIndex == 11 or classIndex == 12 then -- Rogue, Monk, Druid, DH
		table.insert(ClassIDs,8);
		table.insert(ClassIDs,512);
		table.insert(ClassIDs,1024);
		table.insert(ClassIDs,2048);
		table.insert(ClassIDs,3592);
	else 										--Priest, Mage, Lock
		table.insert(ClassIDs,16);
		table.insert(ClassIDs,128);
		table.insert(ClassIDs,256);
		table.insert(ClassIDs,400);
	end

	if classIndex == 1 then
		MyClassID = 1;
		ComClass = 35;
	elseif classIndex == 2 then
		MyClassID = 2;
		ComClass = 35;
	elseif classIndex == 6 then
		MyClassID = 32;
		ComClass = 35;
	elseif classIndex == 3 then
		MyClassID = 4;
		ComClass = 68;
	elseif classIndex == 7 then
		MyClassID = 64;
		ComClass = 68;
	elseif classIndex == 4 then
		MyClassID = 8;
		ComClass = 3592;
	elseif classIndex == 10 then
		MyClassID = 512;
		ComClass = 3592;
	elseif classIndex == 11 then
		MyClassID = 1024;
		ComClass = 3592;
	elseif classIndex == 12 then
		MyClassID = 2048;
		ComClass = 3592;
	elseif classIndex == 5 then
		MyClassID = 16;
		ComClass = 400;
	elseif classIndex == 8 then
		MyClassID = 128;
		ComClass = 400;
	elseif classIndex == 9 then
		MyClassID = 256;
		ComClass = 400;
	end

	return ClassIDs, MyClassID, ComClass;
end


function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if next(tt) == nil then
  	print("La tabla esta vacia");
  end
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, "{\n");
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string( tbl )
	if DEBUG then
	    if  "nil"       == type( tbl ) then
	        return tostring(nil)
	    elseif  "table" == type( tbl ) then
	        return table_print(tbl)
	    elseif  "string" == type( tbl ) then
	        return tbl
	    else
	        return tostring(tbl)
	    end
	end
end

-------------------------------------------------WardrobeCollectionFrame.SetsCollectionFrame--------------------------------------------------------------------------------------------

function OnShow()
	WardrobeCollectionFrame.SetsCollectionFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
	WardrobeCollectionFrame.SetsCollectionFrame:RegisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
	WardrobeCollectionFrame.SetsCollectionFrame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");
	-- select the first set if not init
	local baseSets = GetBaseSets();
	if ( not WardrobeCollectionFrame.SetsCollectionFrame.init ) then
		WardrobeCollectionFrame.SetsCollectionFrame.init = true;
		if ( baseSets and baseSets[1] ) then
			WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(WardrobeCollectionFrame.SetsCollectionFrame:GetDefaultSetIDForBaseSet(baseSets[1].setID));
		end
	else
		WardrobeCollectionFrame.SetsCollectionFrame:Refresh();
	end

	local latestSource = C_TransmogSets.GetLatestSource();
	if ( latestSource ~= NO_TRANSMOG_SOURCE_ID ) then
		local sets = C_TransmogSets.GetSetsContainingSourceID(latestSource);
		local setID = sets and sets[1];
		if ( setID ) then
			WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(setID);
			local baseSetID = C_TransmogSets.GetBaseSetID(setID);
			WardrobeCollectionFrame.SetsCollectionFrame:ScrollToSet(baseSetID);
		end
		WardrobeCollectionFrame.SetsCollectionFrame:ClearLatestSource();
	end

	WardrobeCollectionFrame.progressBar:Show();
	WardrobeCollectionFrame.SetsCollectionFrame:UpdateProgressBar();
	WardrobeCollectionFrame.SetsCollectionFrame:RefreshCameras();

	if (WardrobeCollectionFrame.SetsCollectionFrame:GetParent().SetsTabHelpBox:IsShown()) then
		WardrobeCollectionFrame.SetsCollectionFrame:GetParent().SetsTabHelpBox:Hide()
		SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB, true);
	end
end

function OnHide()
	WardrobeCollectionFrame.SetsCollectionFrame:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
	WardrobeCollectionFrame.SetsCollectionFrame:UnregisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
	WardrobeCollectionFrame.SetsCollectionFrame:UnregisterEvent("TRANSMOG_COLLECTION_UPDATED");
	_SetsDataProvider:ClearSets();
	WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_BASE_SETS);
end

function OnEvent(event, ...)
	if ( event == "GET_ITEM_INFO_RECEIVED" ) then
		local itemID = ...;
		for itemFrame in WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.itemFramesPool:EnumerateActive() do
			if ( itemFrame.itemID == itemID ) then
				WardrobeCollectionFrame.SetsCollectionFrame:SetItemFrameQuality(itemFrame);
				break;
			end
		end
	elseif ( event == "TRANSMOG_COLLECTION_ITEM_UPDATE" ) then
		for itemFrame in WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.itemFramesPool:EnumerateActive() do
			WardrobeCollectionFrame.SetsCollectionFrame:SetItemFrameQuality(itemFrame);
		end
	elseif ( event == "TRANSMOG_COLLECTION_UPDATED" ) then
		_SetsDataProvider:ClearSets();
		WardrobeCollectionFrame.SetsCollectionFrame:Refresh();
		WardrobeCollectionFrame.SetsCollectionFrame:UpdateProgressBar();
		WardrobeCollectionFrame.SetsCollectionFrame:ClearLatestSource();
	end
end

function DisplaySet(ID)
	local setID = WardrobeCollectionFrame.SetsCollectionFrame:GetSelectedSetID();
	if type(setID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	--print(to_string(setID));
	--print(to_string(C_TransmogSets.GetSetInfo(setID)));
	--print(setID);
	--print(setID);
	--print("DisplaySet");

	local setInfo = (setID and C_TransmogSets.GetSetInfo(setID)) or nil;
	if ( not setInfo ) then
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame:Hide();
		WardrobeCollectionFrame.SetsCollectionFrame.Model:Hide();
		return;
	else
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame:Show();
		WardrobeCollectionFrame.SetsCollectionFrame.Model:Show();
	end

	WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.Name:SetText(setInfo.name);
	if ( WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.Name:IsTruncated() ) then
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.Name:Hide();
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.LongName:SetText(setInfo.name);
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.LongName:Show();
	else
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.Name:Show();
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.LongName:Hide();
	end
	WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.Label:SetText(setInfo.label);
	--WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.LimitedSet:SetShown(setInfo.limitedTimeSet);

	local newSourceIDs = C_TransmogSets.GetSetNewSources(setID);

	WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.itemFramesPool:ReleaseAll();
	WardrobeCollectionFrame.SetsCollectionFrame.Model:Undress();
	local BUTTON_SPACE = 37;	-- button width + spacing between 2 buttons
	local sortedSources = GetSortedSetSources(setID);
	local xOffset = -floor((#sortedSources - 1) * BUTTON_SPACE / 2);
	for i = 1, #sortedSources do
		local itemFrame = WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.itemFramesPool:Acquire();
		itemFrame.sourceID = sortedSources[i].sourceID;
		itemFrame.itemID = sortedSources[i].itemID;
		itemFrame.collected = sortedSources[i].collected;
		itemFrame.invType = sortedSources[i].invType;
		local texture = C_TransmogCollection.GetSourceIcon(sortedSources[i].sourceID);
		itemFrame.Icon:SetTexture(texture);
		if ( sortedSources[i].collected ) then
			itemFrame.Icon:SetDesaturated(false);
			itemFrame.Icon:SetAlpha(1);
			itemFrame.IconBorder:SetDesaturation(0);
			itemFrame.IconBorder:SetAlpha(1);

			local transmogSlot = C_Transmog.GetSlotForInventoryType(itemFrame.invType);
			if ( C_TransmogSets.SetHasNewSourcesForSlot(setID, transmogSlot) ) then
				itemFrame.New:Show();
				itemFrame.New.Anim:Play();
			else
				itemFrame.New:Hide();
				itemFrame.New.Anim:Stop();
			end
		else
			itemFrame.Icon:SetDesaturated(true);
			itemFrame.Icon:SetAlpha(0.3);
			itemFrame.IconBorder:SetDesaturation(1);
			itemFrame.IconBorder:SetAlpha(0.3);
			itemFrame.New:Hide();
		end
		WardrobeCollectionFrame.SetsCollectionFrame:SetItemFrameQuality(itemFrame);
		itemFrame:SetPoint("TOP", WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame, "TOP", xOffset + (i - 1) * BUTTON_SPACE, -94);
		itemFrame:Show();
		WardrobeCollectionFrame.SetsCollectionFrame.Model:TryOn(sortedSources[i].sourceID);
	end

	-- variant sets
	local baseSetID = C_TransmogSets.GetBaseSetID(setID);
	local variantSets = GetVariantSets(baseSetID);
	if ( #variantSets == 0 )  then
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.VariantSetsButton:Hide();
	else
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.VariantSetsButton:Show();
		WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.VariantSetsButton:SetText(setInfo.description);
	end
end

function OnSearchUpdate()
	if ( WardrobeCollectionFrame.SetsCollectionFrame.init ) then
		_SetsDataProvider:ClearBaseSets();
		_SetsDataProvider:ClearVariantSets();
		_SetsDataProvider:ClearUsableSets();
		WardrobeCollectionFrame.SetsCollectionFrame:Refresh();
	end
end

function SelectSet(ID)
	if type(ID) ~= "number" then
		ID = CurrentID;
	else
		CurrentID = ID;
	end
	WardrobeCollectionFrame.SetsCollectionFrame.selectedSetID = ID;
	_ScrollFrame.selectedSetID = ID;
	ScrollFrame_Update();


	local baseSetID = GetBaseSetID(ID);
	local variantSets = GetVariantSets(baseSetID);
	--print(to_string(variantSets));
	if ( #variantSets > 0 ) then
		WardrobeCollectionFrame.SetsCollectionFrame.selectedVariantSets[baseSetID] = setID;
	end
	--print(to_string(ID));
	--print(" - SelectSet");
	WardrobeCollectionFrame.SetsCollectionFrame:Refresh();
end

function GetDefaultSetIDForBaseSet(baseSetID)
	if type(baseSetID) ~= "number" then
		baseSetID = CurrentID;
	else
		CurrentID = baseSetID;
	end
	if(type(baseSetID) == "number") then
		if ( IsBaseSetNew(baseSetID) ) then
			if ( C_TransmogSets.SetHasNewSources(baseSetID) ) then
				return baseSetID;
			else
				local variantSets = GetVariantSets(baseSetID);
				for i, variantSet in ipairs(variantSets) do
					if ( C_TransmogSets.SetHasNewSources(variantSet.setID) ) then
						return variantSet.setID;
					end
				end
			end
		end
		--print(to_string(WardrobeCollectionFrame.SetsCollectionFrame.selectedVariantSets));
		if ( WardrobeCollectionFrame.SetsCollectionFrame.selectedVariantSets[baseSetID] ) then
			--print(to_string(WardrobeCollectionFrame.SetsCollectionFrame.selectedVariantSets[baseSetID]));
			--print("GetDefaultSetIDForBaseSet");
			return WardrobeCollectionFrame.SetsCollectionFrame.selectedVariantSets[baseSetID];
		end

		local baseSet = GetSetByID(baseSetID);
		if ( baseSet.favoriteSetID ) then
			return baseSet.favoriteSetID;
		end
		-- pick the one with most collected, higher difficulty wins ties
		local highestCount = 0;
		local highestCountSetID;
		local variantSets = GetVariantSets(baseSetID);
		for i = 1, #variantSets do
			local variantSetID = variantSets[i].setID;
			local numCollected = GetSetSourceCounts(variantSetID);
			if ( numCollected > 0 and numCollected >= highestCount ) then
				highestCount = numCollected;
				highestCountSetID = variantSetID;
			end
		end
		return highestCountSetID or baseSetID;
	end
end

function OpenVariantSetsDropDown()
	local selectedSetID = WardrobeCollectionFrame.SetsCollectionFrame:GetSelectedSetID();
	--print("Set elegido - " .. selectedSetID);
	if ( not selectedSetID ) then
		return;
	end
	local info = UIDropDownMenu_CreateInfo();
	local baseSetID = GetBaseSetID(selectedSetID);
	--print("Base set - " .. baseSetID);

	local variantSets = GetVariantSets(baseSetID);
	--print("Variant Sets ---------------------------------------------");
	--print(to_string(variantSets));
	for i = 1, #variantSets do
		local variantSet = variantSets[i];
		local numSourcesCollected, numSourcesTotal = _SetsDataProvider:GetSetSourceCounts(variantSet.setID);
		local colorCode = IN_PROGRESS_FONT_COLOR_CODE;
		if ( numSourcesCollected == numSourcesTotal ) then
			colorCode = NORMAL_FONT_COLOR_CODE;
		elseif ( numSourcesCollected == 0 ) then
			colorCode = GRAY_FONT_COLOR_CODE;
		end
		info.text = format(ITEM_SET_NAME, variantSet.description..colorCode, numSourcesCollected, numSourcesTotal);
		info.checked = (variantSet.setID == selectedSetID);
		CurrentID = variantSet.setID;
		info.func = function() SelectSet(variantSet.setID); end;
		UIDropDownMenu_AddButton(info);
	end
end

--------------------------------------------------------------------_SetsDataProvider---------------------------------------------------------------------

function GetBaseSets()
	if ( not _SetsDataProvider.baseSets ) then
		local sets = C_TransmogSets.GetAllSets();
		local englishFaction, localizedFaction = UnitFactionGroup('player');
		local UsableIDs, MyClassID, ComonClass = GetClassIDs();
		local UsableSets = {};
		local VarSets = {};
		local ReverseFaction = nil;
	    if englishFaction == "Horde" then
	        ReverseFaction = "Alliance"
	    else
	        ReverseFaction = "Horde"
	    end

	    local uldirfix = 11050;

		for index, data in ipairs(sets) do
			if data.baseSetID == nil then
				if data.classMask == 0 and data.collected == true then
					table.insert(UsableSets,data);
				else
					for i = 1, #UsableIDs do
						if data.classMask == UsableIDs[i] and data.requiredFaction ~= ReverseFaction then
							if data.classMask == MyClassID or data.classMask == ComonClass or type(data.requiredFaction) ~= "string" then
								--Fix Uldir Set Order
								if data.expansionID == 7 and data.uiOrder < 10000 then
									data.uiOrder = uldirfix;
									uldirfix = uldirfix + 1;
								end
								table.insert(UsableSets,data);
							end
						end
			      	end
			    end
		    else
		    	for i = 1, #UsableIDs do
					if data.classMask == UsableIDs[i] and data.requiredFaction ~= ReverseFaction then
						if data.expansionID == 7 and data.uiOrder < 10000 then
							data.uiOrder = uldirfix;
							uldirfix = uldirfix + 1;
						end
						table.insert(VarSets,data);
					end		
		      	end
		    end
		end
	 	_SetsDataProvider.baseSets = UsableSets;
	 	
	 	_SetsDataProvider:DetermineFavorites();
	 	_SetsDataProvider:SortSets(_SetsDataProvider.baseSets,false);
	 	_VariantSets = VarSets;	
	end
	return _SetsDataProvider.baseSets;	
end

function GetVariantSets(baseSetID)
	if type(baseSetID) ~= "number" then
		baseSetID = CurrentID;
	else
		CurrentID = baseSetID;
	end
	if ( not _SetsDataProvider.variantSets ) then
		_SetsDataProvider.variantSets = { };
	end

	local variantSets = _SetsDataProvider.variantSets[baseSetID];
	if ( not variantSets ) then
		variantSets = ModGetVariantSets(baseSetID);
		_SetsDataProvider.variantSets[baseSetID] = variantSets;
		if ( #variantSets > 0 ) then
			-- add base to variants and sort
			local baseSet = GetSetByID(baseSetID);
			if ( baseSet ) then
				tinsert(variantSets, baseSet);
			end
			--_SetsDataProvider:SortSets(variantSets, false);
			--print(to_string(variantSets));
		end
	end
	return variantSets;
end

function DetermineFavorites()
	-- if a variant is favorited, so is the base set
	-- keep track of which set is favorited
	local baseSets = GetBaseSets();
	for i = 1, #baseSets do
		local baseSet = baseSets[i];
		baseSet.favoriteSetID = nil;
		if ( baseSet.favorite ) then
			baseSet.favoriteSetID = baseSet.setID;
		else
			local variantSets = GetVariantSets(baseSet.setID);
			for j = 1, #variantSets do
				if ( variantSets[j].favorite ) then
					baseSet.favoriteSetID = variantSets[j].setID;
					break;
				end
			end
		end
	end
end

function IsBaseSetNew(baseSetID)
	if type(baseSetID) ~= "number" then
		baseSetID = CurrentID;
	else
		CurrentID = baseSetID;
	end
	local baseSetData = GetBaseSetData(baseSetID)
	if ( not baseSetData.newStatus ) then
		local newStatus = C_TransmogSets.SetHasNewSources(baseSetID);
		if ( not newStatus ) then
			-- check variants
			local variantSets = GetVariantSets(baseSetID);
			for i, variantSet in ipairs(variantSets) do
				--print(variantSet.setID);
				if(variantSet.setID ~= nil) then
					if ( C_TransmogSets.SetHasNewSources(variantSet.setID) ) then
						newStatus = true;
						break;
					end
				end
			end
		end
		baseSetData.newStatus = newStatus;
	end
	return baseSetData.newStatus;
end

function GetBaseSetData(setID)
	if type(baseSetID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	if ( not _SetsDataProvider.baseSetsData ) then
		_SetsDataProvider.baseSetsData = { };
	end
	if ( not _SetsDataProvider.baseSetsData[setID] ) then
		local baseSetID = GetBaseSetID(setID);
		if ( baseSetID ~= setID ) then
			return;
		end
		--print(setID);
		--print(" - GetBaseSetData");
		local topCollected, topTotal = GetSetSourceCounts(setID);
		local variantSets = GetVariantSets(setID);
		for i = 1, #variantSets do
			local numCollected, numTotal = GetSetSourceCounts(variantSets[i].setID);
			if ( numCollected > topCollected ) then
				topCollected = numCollected;
				topTotal = numTotal;
			end
		end
		local setInfo = { topCollected = topCollected, topTotal = topTotal, completed = (topCollected == topTotal) };
		_SetsDataProvider.baseSetsData[setID] = setInfo;
	end
	return _SetsDataProvider.baseSetsData[setID];
end

function GetSetSourceData(setID)
	if type(baseSetID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	if ( not _SetsDataProvider.sourceData ) then
		_SetsDataProvider.sourceData = { };
	end
	--print (setID);
	local sourceData = _SetsDataProvider.sourceData[setID];
	if ( not sourceData ) then
		--print (to_string(setID));
		--print("GetSetSourceData");
		local sources = C_TransmogSets.GetSetSources(setID);
		local numCollected = 0;
		local numTotal = 0;
		for sourceID, collected in pairs(sources) do
			if ( collected ) then
				numCollected = numCollected + 1;
			end
			numTotal = numTotal + 1;
		end
		sourceData = { numCollected = numCollected, numTotal = numTotal, sources = sources };
		_SetsDataProvider.sourceData[setID] = sourceData;
	end
	return sourceData;
end

function GetIconForSet(setID)
	if type(setID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	local sourceData = GetSetSourceData(setID);
	if ( not sourceData.icon ) then
		local sortedSources = GetSortedSetSources(setID);
		if ( sortedSources[1] ) then
			local _, _, _, _, icon = GetItemInfoInstant(sortedSources[1].itemID);
			sourceData.icon = icon;
		else
			sourceData.icon = QUESTION_MARK_ICON;
		end
	end
	return sourceData.icon;
end

function GetSetSourceTopCounts(setID)
	if type(setID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	--print(setID);
	--print(" - GetSetSourceTopCounts");
	local baseSetData = GetBaseSetData(setID);
	if ( baseSetData ) then
		return baseSetData.topCollected, baseSetData.topTotal;
	else
		return GetSetSourceCounts(setID);
	end
end

function GetSetSourceCounts(setID)
	if type(setID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	local sourceData = GetSetSourceData(setID);
	return sourceData.numCollected, sourceData.numTotal;
end

function ResetBaseSetNewStatus(baseSetID)
	if type(baseSetID) ~= "number" then
		baseSetID = CurrentID;
	else
		CurrentID = baseSetID;
	end
	local baseSetData = GetBaseSetData(baseSetID);
	if ( baseSetData ) then
		baseSetData.newStatus = nil;
	end
end

function GetSortedSetSources(setID)
	if type(baseSetID) ~= "number" then
		setID = CurrentID;
	else
		CurrentID = setID;
	end
	local returnTable = { };
	local sourceData = GetSetSourceData(setID);
	for sourceID, collected in pairs(sourceData.sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
		if ( sourceInfo ) then
			local sortOrder = EJ_GetInvTypeSortOrder(sourceInfo.invType);
			tinsert(returnTable, { sourceID = sourceID, collected = collected, sortOrder = sortOrder, itemID = sourceInfo.itemID, invType = sourceInfo.invType });
		end
	end

	local comparison = function(entry1, entry2)
		if ( entry1.sortOrder == entry2.sortOrder ) then
			return entry1.itemID < entry2.itemID;
		else
			return entry1.sortOrder < entry2.sortOrder;
		end
	end
	table.sort(returnTable, comparison);
	return returnTable;
end

function SortSets(sets, reverseUIOrder)
	local comparison = function(set1, set2)
		local groupFavorite1 = set1.favoriteSetID and true;
		local groupFavorite2 = set2.favoriteSetID and true;
		if ( groupFavorite1 ~= groupFavorite2 ) then
			return groupFavorite1;
		end
		if ( set1.favorite ~= set2.favorite ) then
			return set1.favorite;
		end
		if ( set1.expansionID ~= set2.expansionID ) then
			return set1.expansionID > set2.expansionID;
		end
		if ( set1.patchID ~= set2.patchID ) then
			return set1.patchID > set2.patchID;
		end
		if ( set1.uiOrder ~= set2.uiOrder ) then
			if ( reverseUIOrder ) then
				return set1.uiOrder < set2.uiOrder;
			else
				return set1.uiOrder > set2.uiOrder;
			end
		end
		return set1.setID > set2.setID;
	end

	table.sort(sets, comparison);
end

--------------------------------------------------------------------WardrobeCollectionFrameScrollFrame----------------------------------------------------------------------------------
--[[
function ScrollUpdate()
	local offset = HybridScrollFrame_GetOffset(WardrobeCollectionFrameScrollFrame);
	local buttons = WardrobeCollectionFrameScrollFrame.buttons;
	local baseSets = GetBaseSets();

	-- show the base set as selected
	local selectedSetID = WardrobeCollectionFrameScrollFrame:GetParent():GetSelectedSetID();
	--print(to_string(WardrobeCollectionFrameScrollFrame:GetParent():GetSelectedSetID()));
	local selectedBaseSetID = selectedSetID;
	--print(to_string(_SetsDataProvider.baseSets));
	for i = 1, #buttons do
		local button = buttons[i];
		local setIndex = i + offset;
		--print(setIndex .. " <= " .. #baseSets);
		if ( setIndex <= #baseSets ) then
			local baseSet = baseSets[setIndex];
			button:Show();
			button.Name:SetText(baseSet.name);
			--print (baseSet.setID);
			--print(" - Update");
			CurrentID = baseSet.setID;
			local topSourcesCollected, topSourcesTotal = GetSetSourceTopCounts(baseSet.setID);
			local setCollected = C_TransmogSets.IsBaseSetCollected(baseSet.setID);
			local color = IN_PROGRESS_FONT_COLOR;
			if ( setCollected ) then
				color = NORMAL_FONT_COLOR;
			elseif ( topSourcesCollected == 0 ) then
				color = GRAY_FONT_COLOR;
			end
			button.Name:SetTextColor(color.r, color.g, color.b);
			button.Label:SetText(baseSet.label);
			button.Icon:SetTexture(GetIconForSet(baseSet.setID));
			button.Icon:SetDesaturation((topSourcesCollected == 0) and 1 or 0);
			button.SelectedTexture:SetShown(baseSet.setID == selectedBaseSetID);
			button.Favorite:SetShown(baseSet.favoriteSetID);
			button.New:SetShown(IsBaseSetNew(baseSet.setID));
			button.setID = baseSet.setID;

			if ( topSourcesCollected == 0 or setCollected ) then
				button.ProgressBar:Hide();
			else
				button.ProgressBar:Show();
				button.ProgressBar:SetWidth(SET_PROGRESS_BAR_MAX_WIDTH * topSourcesCollected / topSourcesTotal);
			end
			button.IconCover:SetShown(not setCollected);
		else
			button:Hide();
		end
	end

	local extraHeight = (WardrobeCollectionFrameScrollFrame.largeButtonHeight and WardrobeCollectionFrameScrollFrame.largeButtonHeight - _BASE_SET_BUTTON_HEIGHT) or 0;
	local totalHeight = #baseSets * _BASE_SET_BUTTON_HEIGHT + extraHeight;
	HybridScrollFrame_Update(WardrobeCollectionFrameScrollFrame, totalHeight, WardrobeCollectionFrameScrollFrame:GetHeight());
end]]

local function CalculateCount()
	local countAll = 0;
	local countCollected = 0;
	local baseSets = _SetsDataProvider:GetBaseSets();
	for _, baseSet in pairs(baseSets) do
		
		local numCollected, numTotal = _SetsDataProvider:GetSetSourceCounts(baseSet.setID);
		if numTotal > 0 then
			countAll = countAll + 1;
			if numCollected == numTotal then
				countCollected = countCollected + 1;
			end
		end
	end
	return countAll, countCollected;
end

function ScrollFrameButton_BindSet(pButton, pBaseSet, pVariantSet, pIsHeader)
	--print(pBaseSet.setID ..  " - Base");
	--print(pVariantSet.setID ..  " - Variant");
	local numCollected, numTotal = GetSetSourceCounts(pVariantSet.setID);
	local setCollected = numCollected == numTotal;


	
	pButton.setID = pBaseSet.setID;
	pButton.setVariantID = pVariantSet.setID;
	pButton:Show();
	
	pButton.Name:SetText(pVariantSet.name);
	local color;
	if setCollected then
		color = NORMAL_FONT_COLOR;
	elseif numCollected == 0 then
		color = GRAY_FONT_COLOR;
	else 
		color = IN_PROGRESS_FONT_COLOR;
	end
	pButton.Name:SetTextColor(color.r, color.g, color.b);
	
	if pVariantSet.description and pVariantSet.label then
		pButton.Label:SetText(pVariantSet.description .. ' - ' .. pVariantSet.label);
	else
		pButton.Label:SetText(pVariantSet.label);
	end
	
	if pIsHeader then
		pButton.IconCover:Show();
		pButton.IconCover:SetShown(false);
		pButton.Icon:Show();
		pButton.Icon:SetDesaturation(0);
		pButton.Icon:SetTexture(_SetsDataProvider:GetIconForSet(pBaseSet.setID));
		pButton.Icon:SetDesaturation((topSourcesCollected == 0) and 1 or 0);
		pButton.Favorite:SetShown(pBaseSet.favoriteSetID);
	else
		pButton.IconCover:Hide();
		pButton.Icon:Hide();
		pButton.Favorite:Hide();
	end
	
	pButton.New:SetShown(_SetsDataProvider:IsBaseSetNew(pBaseSet.setID));
	
	pButton.SelectedTexture:SetShown(GetBaseSetID(pVariantSet.setID) == _ScrollFrame.selectedSetID);
	
	if numCollected == 0 then
		pButton.ProgressBar:Hide();
	else
		pButton.ProgressBar:Show();
		pButton.ProgressBar:SetWidth(SET_PROGRESS_BAR_MAX_WIDTH * numCollected / numTotal);
	end
end

function ScrollFrame_Update()
	
	
	local offset = HybridScrollFrame_GetOffset(_ScrollFrame) + 1;
	local baseSets = _SetsDataProvider:GetBaseSets();
	local buttons = _ScrollFrame.buttons;
	local index = 0;
	local indexButton = 1;
	--print(to_string(_SetsDataProvider:GetBaseSets()));
	for _, baseSet in pairs(baseSets) do
		if indexButton > #buttons then
			break;
		end
		index = index + 1;
		--print(baseSet.setID .. " - Antes del bind");
		local variantSets = _SetsDataProvider:GetVariantSets(baseSet.setID);
		if offset <= index then
				ScrollFrameButton_BindSet(buttons[indexButton], baseSet, baseSet, true);
				indexButton = indexButton + 1;
		end
	end
	for i = indexButton, #buttons do 
		buttons[i]:Hide();
	end
	
	local countAll, countCollected = CalculateCount();
	
	WardrobeCollectionFrame.progressBar:SetMinMaxValues(0, countAll);
	WardrobeCollectionFrame.progressBar:SetValue(countCollected);
	WardrobeCollectionFrame.progressBar.text:SetFormattedText(HEIRLOOMS_PROGRESS_FORMAT, countCollected, countAll);
	
	local totalHeight = countAll * _ButtonHeight;
	local range = math.floor(totalHeight - _ScrollFrame:GetHeight() + 0.5);
	if range > 0 then
		local minVal, maxVal = _ScrollFrame.scrollBar:GetMinMaxValues();
		_ScrollFrame.scrollBar:SetMinMaxValues(0, range)
		if math.floor(_ScrollFrame.scrollBar:GetValue()) >= math.floor(maxVal) then
			if math.floor(_ScrollFrame.scrollBar:GetValue()) ~= math.floor(range) then
				_ScrollFrame.scrollBar:SetValue(range);
			else
				HybridScrollFrame_SetOffset(_ScrollFrame, range); 
			end
		end
		_ScrollFrame.scrollBar:Enable();
		HybridScrollFrame_UpdateButtonStates(_ScrollFrame);
		_ScrollFrame.scrollBar:Show();
	else
		_ScrollFrame.scrollBar:SetValue(0);
		_ScrollFrame.scrollBar:Disable();
		_ScrollFrame.scrollUp:Disable();
		_ScrollFrame.scrollDown:Disable();
		_ScrollFrame.scrollBar.thumbTexture:Hide();
	end
	_ScrollFrame.range = range;
	_ScrollFrame:UpdateScrollChildRect();
end

local function ScrollFrame_SelectSet(pSetID)
	_ScrollFrame.selectedSetID = pSetID;
	--print(pSetID .. " - Seleccionar");
	CurrentID = pSetID;
	SelectSet(pSetID);
	ScrollFrame_Update();
end

local function ScrollFrame_ScrollToSet(pSetID)
	local totalHeight = 0;
	local scrollFrameHeight = _ScrollFrame:GetHeight();
	local baseSets = _SetsDataProvider:GetBaseSets();
	local b = false;
	for _, baseSet in pairs(baseSets) do
		local variantSets = _SetsDataProvider:GetVariantSets(baseSet.setID);
		if #variantSets > 0 then
			for _, variantSet in pairs(variantSets) do
				if variantSet.setID == pSetID then
					b = true;
					break;
				end
				totalHeight = totalHeight + _ButtonHeight;
			end
			if b then
				break;
			end
		else
			if baseSet.setID == pSetID then
				break;
			else
				totalHeight = totalHeight + _ButtonHeight;
			end
		end
	end
	if totalHeight + _ButtonHeight > _ScrollFrame.scrollBar.scrollValue + scrollFrameHeight then
		_ScrollFrame.scrollBar.scrollValue = totalHeight + _ButtonHeight - scrollFrameHeight;
	elseif totalHeight < _ScrollFrame.scrollBar.scrollValue then
		_ScrollFrame.scrollBar.scrollValue = totalHeight;
	end
	_ScrollFrame.scrollBar:SetValue(_ScrollFrame.scrollBar.scrollValue, true);
end

local function ScrollFrame_HandleKey(pKey)
	if pKey ~= WARDROBE_DOWN_VISUAL_KEY and pKey ~= WARDROBE_UP_VISUAL_KEY then
		_ScrollFrame:SetPropagateKeyboardInput(true);
		return;
	end
	
	if not _ScrollFrame.selectedSetID then
		_ScrollFrame:SetPropagateKeyboardInput(true);
		return;
	end
	
	local prevSet = nil;
	local curSet = nil;
	local nextSet = nil;
	local baseSets = _SetsDataProvider:GetBaseSets();
	for _, baseSet in pairs(baseSets) do
		local variantSets = _SetsDataProvider:GetVariantSets(baseSet.setID);
		if #variantSets > 0 then
			for _, variantSet in pairs(variantSets) do
				if curSet then
					nextSet = variantSet;
					break;
				elseif _ScrollFrame.selectedSetID == variantSet.setID then
					curSet = variantSet;
				else
					prevSet = variantSet;
				end
			end
		else
			if curSet then
				nextSet = baseSet;
			elseif _ScrollFrame.selectedSetID == baseSet.setID then
				curSet = baseSet;
			else
				prevSet = baseSet;
			end
		end
		if nextSet then
			break;
		end
	end
	_ScrollFrame:SetPropagateKeyboardInput(false);
	if pKey == WARDROBE_DOWN_VISUAL_KEY then
		if nextSet then
			ScrollFrame_SelectSet(nextSet.setID);
			ScrollFrame_ScrollToSet(nextSet.setID);
		end
	elseif pKey == WARDROBE_UP_VISUAL_KEY then
		if prevSet then
			ScrollFrame_SelectSet(prevSet.setID);
			ScrollFrame_ScrollToSet(prevSet.setID);
		end
	end
end

local function FavoriteDropDown_Init(pSelf)
	if not _ScrollFrame.menuInitBaseSetID then
		return;
	end

	local baseSet = _SetsDataProvider:GetBaseSetByID(_ScrollFrame.menuInitBaseSetID);
	local variantSets = _SetsDataProvider:GetVariantSets(_ScrollFrame.menuInitBaseSetID);
	local useDescription = (#variantSets > 0);

	local info1 = UIDropDownMenu_CreateInfo();
	info1.notCheckable = true;
	info1.disabled = nil;
	if baseSet.favoriteSetID then
		if useDescription then
			local setInfo = C_TransmogSets.GetSetInfo(baseSet.favoriteSetID);
			info1.text = format(TRANSMOG_SETS_UNFAVORITE_WITH_DESCRIPTION, setInfo.description);
		else
			info1.text = BATTLE_PET_UNFAVORITE;
		end
		info1.func = function()
			C_TransmogSets.SetIsFavorite(baseSet.favoriteSetID, false);
		end
	else
		local targetSetID = WardrobeCollectionFrame.SetsCollectionFrame:GetDefaultSetIDForBaseSet(_ScrollFrame.menuInitBaseSetID);
		if useDescription then
			local setInfo = C_TransmogSets.GetSetInfo(targetSetID);
			info1.text = format(TRANSMOG_SETS_FAVORITE_WITH_DESCRIPTION, setInfo.description);
		else
			info1.text = BATTLE_PET_FAVORITE;
		end
		info1.func = function()
			C_TransmogSets.SetIsFavorite(targetSetID, true);
		end
	end
	UIDropDownMenu_AddButton(info1, 1);
  
	--local info2 = UIDropDownMenu_CreateInfo();
	--info2.notCheckable = true;
	--info2.disabled = nil;
	--info2.text = CANCEL;
	--info2.func = nil;
	--UIDropDownMenu_AddButton(info2, 1);
end

function CreateScrollbar(frame)
	WardrobeCollectionFrameScrollFrame:Hide();
		
	_ButtonHeight = WardrobeCollectionFrameScrollFrame.buttons[1]:GetHeight();
	
	_ScrollFrame = CreateFrame("ScrollFrame", "SetCollectionUngroupScrollFrame", WardrobeCollectionFrame.SetsCollectionFrame, "HybridScrollFrameTemplate");
	_ScrollFrame:SetAllPoints(WardrobeCollectionFrameScrollFrame);
	
	_ScrollFrame.scrollBar = CreateFrame("Slider", "SetCollectionUngroupScrollFrameScrollBar", _ScrollFrame, "HybridScrollBarTrimTemplate");
	_ScrollFrame.scrollBar:SetAllPoints(WardrobeCollectionFrameScrollFrame.scrollBar);
	_ScrollFrame.scrollBar:SetScript("OnValueChanged", function(pSelf, pValue) 
		pSelf.scrollValue = pValue;
		HybridScrollFrame_OnValueChanged(pSelf, pValue);
		ScrollFrame_Update();
	end);
	_ScrollFrame.scrollBar.trackBG:Show();
	_ScrollFrame.scrollBar.trackBG:SetVertexColor(0, 0, 0, 0.75);
	_ScrollFrame.scrollBar.scrollValue = 0;
	
	HybridScrollFrame_CreateButtons(_ScrollFrame, "WardrobeSetsScrollFrameButtonTemplate", 44, 0);
	for _, button in pairs(_ScrollFrame.buttons) do
		button.ProgressBar:SetTexture(1, 1, 1);
		button:RegisterForClicks("AnyUp", "AnyDown");
		button:SetScript("OnMouseUp", function(pSelf, pButton, pDown)
			if pButton == "LeftButton" then
				--PlaySound("igMainMenuOptionCheckBoxOn");
				CloseDropDownMenus();
				ScrollFrame_SelectSet(pSelf.setVariantID);
			elseif pButton == "RightButton" then
				_ScrollFrame.menuInitBaseSetID = pSelf.setID;
				ToggleDropDownMenu(1, nil, _FavoriteDropDown, pSelf, 0, 0);
				--PlaySound("igMainMenuOptionCheckBoxOn");
			end
		end)
	end
	
	_BaseSets = GetBaseSets();
	local firstSet = nil;
	for i,set in ipairs(_SetsDataProvider.baseSets) do
		firstSet = set;
		break
	end
	--print(firstSet.setID);
	--print("Start")
	_ScrollFrame.selectedSetID = firstSet.setID;

	local variantSets = _SetsDataProvider:GetVariantSets(_ScrollFrame.selectedSetID);
	if #variantSets > 0 then
		_ScrollFrame.selectedSetID = variantSets[1].setID;
	end
	WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(_ScrollFrame.selectedSetID);
	
	_FavoriteDropDown = CreateFrame("Frame", "SetCollectionUngroupFavoriteDropDown", _ScrollFrame, "UIDropDownMenuTemplate");
	UIDropDownMenu_Initialize(_FavoriteDropDown, FavoriteDropDown_Init, "MENU");

	hooksecurefunc(WardrobeCollectionFrameScrollFrame, "update", function(pSelf)
		_ScrollFrame.selectedSetID = WardrobeCollectionFrame.SetsCollectionFrame:GetSelectedSetID();
		ScrollFrame_Update();
	end);
	hooksecurefunc(WardrobeCollectionFrameScrollFrame, "Update", function(pSelf)
		_ScrollFrame.selectedSetID = WardrobeCollectionFrame.SetsCollectionFrame:GetSelectedSetID();
		ScrollFrame_Update();
	end);
	
	_ScrollFrame:SetScript("OnShow", function(pSelf) 
		ScrollFrame_Update();
		frame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");
		frame:RegisterEvent("PLAYER_REGEN_ENABLED");
		frame:RegisterEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
	end);
	_ScrollFrame:SetScript("OnHide", function(pSelf) 
		frame:UnregisterEvent("TRANSMOG_COLLECTION_UPDATED");
		frame:UnregisterEvent("PLAYER_REGEN_ENABLED");
		frame:UnregisterEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
	end);
	_ScrollFrame:SetScript("OnKeyDown", function(pSelf, pKey)
		ScrollFrame_HandleKey(pKey);
	end);
end

local InsaneSets = nil;
local frame = CreateFrame("frame"); 
frame:RegisterEvent("ADDON_LOADED");
frame:SetScript("OnEvent", function(pSelf, pEvent, pUnit)
	if pEvent == "ADDON_LOADED" and pUnit == "Blizzard_Collections" then
		--WardrobeCollectionFrameScrollFrame:Hide();
		_SetsDataProvider = CreateFromMixins(WardrobeSetsDataProviderMixin);

		------------------------------------------------------------------------Remplazar funciones
		WardrobeCollectionFrame.SetsCollectionFrame.OnShow = OnShow;
		WardrobeCollectionFrame.SetsCollectionFrame.OnHide = OnHide;
		WardrobeCollectionFrame.SetsCollectionFrame.OnEvent = OnEvent;
		WardrobeCollectionFrame.SetsCollectionFrame.DisplaySet = DisplaySet;
		WardrobeCollectionFrame.SetsCollectionFrame.OnSearchUpdate = OnSearchUpdate;
		WardrobeCollectionFrame.SetsCollectionFrame.SelectSet = SelectSet;
		WardrobeCollectionFrame.SetsCollectionFrame.GetDefaultSetIDForBaseSet = GetDefaultSetIDForBaseSet;
		WardrobeCollectionFrame.SetsCollectionFrame.OpenVariantSetsDropDown = OpenVariantSetsDropDown;
		--WardrobeCollectionFrame.SetsCollectionFrame.DisplaySet = DisplaySet;


		_SetsDataProvider.GetBaseSets = GetBaseSets;
		_SetsDataProvider.GetVariantSets = GetVariantSets;
		_SetsDataProvider.DetermineFavorites = DetermineFavorites;
		_SetsDataProvider.IsBaseSetNew = IsBaseSetNew;
		_SetsDataProvider.GetBaseSetData = GetBaseSetData;
		_SetsDataProvider.GetSetSourceData = GetSetSourceData;
		_SetsDataProvider.GetIconForSet = GetIconForSet;
		_SetsDataProvider.GetSetSourceTopCounts = GetSetSourceTopCounts;
		_SetsDataProvider.GetSetSourceCounts = GetSetSourceCounts;
		_SetsDataProvider.ResetBaseSetNewStatus = ResetBaseSetNewStatus;
		_SetsDataProvider.GetSortedSetSources = GetSortedSetSources;


		--print(to_string(_SetsDataProvider));
		--WardrobeCollectionFrameScrollFrame.Update = ScrollUpdate;
		---------------------------------------------------------------------------------------------------------------------------------------

		CreateScrollbar(frame);

		hooksecurefunc(WardrobeCollectionFrameScrollFrame, "update", function(pSelf)
			--ScrollUpdate()
		end);
		--[[hooksecurefunc(WardrobeCollectionFrameScrollFrame, "Update", function(pSelf)
			ScrollUpdate()
		end);]]

		--WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.itemFramesPool:Hide();

		
		--_itemFramesPool = CreateFramePool("FRAME", WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame, "WardrobeSetsDetailsItemFrameTemplate");

		
		--_ScrollFrame.selectedSetID = _SetsDataProvider.baseSets[1].setID;

	elseif _ScrollFrame then 
		if pEvent == "TRANSMOG_SETS_UPDATE_FAVORITE" then
			WardrobeCollectionFrameScrollFrame:OnEvent(pEvent);
		end
		ScrollFrame_Update();
	end
end)


