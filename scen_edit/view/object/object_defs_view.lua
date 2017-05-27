SB.Include(Path.Join(SB_VIEW_DIR, "editor_view.lua"))

ObjectDefsView = EditorView:extends{}

function ObjectDefsView:init()
    self:super("init")

    self.btnBrush = TabbedPanelButton({
        x = 00,
        y = 0,
        tooltip = "Brush",
        children = {
            TabbedPanelImage({ file = SB_IMG_DIR .. "unit.png" }),
            TabbedPanelLabel({ caption = "Brush" }),
        },
        OnClick = {
            function()
                self.type = "brush"
                self:EnterState()
            end
        },
    })
    self.btnSet = TabbedPanelButton({
        x = 70,
        y = 0,
        tooltip = "Set",
        children = {
            TabbedPanelImage({ file = SB_IMG_DIR .. "unit.png" }),
            TabbedPanelLabel({ caption = "Set" }),
        },
        OnClick = {
            function()
                self.type = "set"
                self:EnterState()
            end
        },
    })

    self:MakePanel()
    self.objectDefPanel:AddSelectListener(function(selected)
        if #self.objectDefPanel:GetSelectedObjectDefs() > 0 then
            self:EnterState()
        end
    end)

    self:MakeFilters()
    local children = {
        self.btnSet,
        self.btnBrush,
        ScrollPanel:New {
            x = 1,
			right = 1,
			y = SB.conf.C_HEIGHT * 9,
			height = "50%",
            children = {
                self.objectDefPanel.control
            },
        },
        btnClose,
    }
    for i = 1, #self.filters do
        table.insert(children, self.filters[i])
    end

    local teamIds = GetField(SB.model.teamManager:getAllTeams(), "id")
	for i = 1, #teamIds do
		teamIds[i] = tostring(teamIds[i])
	end
	local teamCaptions = GetField(SB.model.teamManager:getAllTeams(), "name")
	self:AddField(ChoiceField({
	    name = "team",
        items = teamIds,
		captions = teamCaptions,
        title = "Team: ",
    }))
	self:Update("team")
    self:AddField(NumericField({
        name = "amount",
        title = "Amount:",
        tooltip = "Amount",
        value = 1,
        minValue = 1,
        maxValue = 100,
        step = 1,
        decimals = 0,
    }))
    self:AddField(NumericField({
        name = "size",
        value = 100,
        minValue = 10,
        maxValue = 5000,
        title = "Size:",
        tooltip = "Size of the paint brush",
        decimals = 0,
    }))

    self:AddField(NumericField({
        name = "spread",
        title = "Spread:",
        tooltip = "Spread",
        value = 100,
        minValue = 1,
        maxValue = 500,
        step = 1,
        decimals = 0,
    }))
    self:AddField(NumericField({
        name = "noise",
        title = "Noise:",
        tooltip = "noise",
        value = 100,
        minValue = 1,
        maxValue = 2000,
        step = 1,
        decimals = 0,
    }))

    table.insert(children,
		ScrollPanel:New {
			x = 0,
			y = "65%",
			bottom = 30,
			right = 0,
			borderColor = {0,0,0,0},
			horizontalScrollbar = false,
			children = { self.stackPanel },
		}
	)

    self:Finalize(children)
    self:SetInvisibleFields("size", "spread", "noise", "amount")
    self.type = "brush"
end

function ObjectDefsView:IsValidTest(state)
    return state:is_A(AddObjectState) or state:is_A(BrushObjectState)
end

function ObjectDefsView:OnFieldChange(name, value)
    if name == "team" then
        self.objectDefPanel:SelectTeamID(value, type(value))
    end
end

UnitDefsView = ObjectDefsView:extends{}
function UnitDefsView:MakePanel()
    self.objectDefPanel = UnitDefsPanel({
        width = "100%",
        height = "100%"
    })
end
function UnitDefsView:EnterState()
    if self.type == "set" then
        self:SetInvisibleFields("size", "noise", "spread")
        SB.stateManager:SetState(AddUnitState(self, self.objectDefPanel:GetSelectedObjectDefs()))
    elseif self.type == "brush" then
        self:SetInvisibleFields("amount")
        SB.stateManager:SetState(BrushUnitState(self, self.objectDefPanel:GetSelectedObjectDefs()))
    end
end
function UnitDefsView:MakeFilters()
    self.filters = {
        Label:New {
            x = 1,
            y = 8 + SB.conf.C_HEIGHT * 5,
            caption = "Type:",
        },
        ComboBox:New {
            height = SB.conf.B_HEIGHT,
            x = 40,
            y = 1 + SB.conf.C_HEIGHT * 5,
            items = {
                "Units", "Buildings", "All",
            },
            width = 90,
            OnSelect = {
                function (obj, itemIdx, selected)
                    if selected then
                        self.objectDefPanel:SelectUnitTypesId(itemIdx)
                    end
                end
            },
        },
        Label:New {
            caption = "Terrain:",
            x = 140,
            y = 8 + SB.conf.C_HEIGHT * 5,
        },
        ComboBox:New {
            height = SB.conf.B_HEIGHT,
            x = 190,
            y = 1 + SB.conf.C_HEIGHT * 5,
            items = {
                "Ground", "Air", "Water", "All",
            },
            width = 90,
            OnSelect = {
                function (obj, itemIdx, selected)
                    if selected then
                        self.objectDefPanel:SelectTerrainId(itemIdx)
                    end
                end
            },
        },
        Label:New {
			x = 1,
			y = 8 + SB.conf.C_HEIGHT * 7,
			caption = "Search:",
		},
		EditBox:New {
			height = SB.conf.B_HEIGHT,
			x = 60,
			y = 1 + SB.conf.C_HEIGHT * 7,
			text = "",
			width = 90,
			OnTextInput = {
                function(obj)
                    self.objectDefPanel:SetSearchString(obj.text)
                end
            },
            OnKeyPress = {
                function(obj)
                    self.objectDefPanel:SetSearchString(obj.text)
                end
            },
		},
    }
end

FeatureDefsView = ObjectDefsView:extends{}
function FeatureDefsView:MakePanel()
    self.objectDefPanel = FeatureDefsPanel({
        width = "100%",
        height = "100%"
    })
end
function FeatureDefsView:EnterState()
    if self.type == "set" then
        self:SetInvisibleFields("size", "noise", "spread")
        SB.stateManager:SetState(AddFeatureState(self, self.objectDefPanel:GetSelectedObjectDefs()))
    elseif self.type == "brush" then
        self:SetInvisibleFields("amount")
        SB.stateManager:SetState(BrushFeatureState(self, self.objectDefPanel:GetSelectedObjectDefs()))
    end
end
function FeatureDefsView:MakeFilters()
    self.filters = {
        Label:New {
			x = 1,
			y = 8 + SB.conf.C_HEIGHT * 5,
			caption = "Type:",
		},
		ComboBox:New {
			height = SB.conf.B_HEIGHT,
			x = 40,
			y = 1 + SB.conf.C_HEIGHT * 5,
			items = {
				"Other", "Wreckage", "All",
			},
			width = 90,
			OnSelect = {
				function (obj, itemIdx, selected)
					if selected then
						self.objectDefPanel:SelectFeatureTypesId(itemIdx)
					end
				end
			},
		},
		Label:New {
			x = 140,
			y = 8 + SB.conf.C_HEIGHT * 5,
			caption = "Wreck:",
		},
		ComboBox:New {
			height = SB.conf.B_HEIGHT,
			x = 190,
			y = 1 + SB.conf.C_HEIGHT * 5,
			items = {
				"Units", "Buildings", "All",
			},
			width = 90,
			OnSelect = {
				function (obj, itemIdx, selected)
					if selected then
                        self.objectDefPanel:SelectUnitTypesId(itemIdx)
					end
				end
			},
		},
		Label:New {
			caption = "Terrain:",
			x = 290,
			y = 8 + SB.conf.C_HEIGHT * 5,
		},
		ComboBox:New {
			y = 1 + SB.conf.C_HEIGHT * 5,
			height = SB.conf.B_HEIGHT,
			items = {
				"Ground", "Air", "Water", "All",
			},
			x = 340,
			width = 90,
			OnSelect = {
				function (obj, itemIdx, selected)
					if selected then
						self.objectDefPanel:SelectTerrainId(itemIdx)
					end
				end
			},
		},
        Label:New {
			x = 1,
			y = 8 + SB.conf.C_HEIGHT * 7,
			caption = "Search:",
		},
		EditBox:New {
			height = SB.conf.B_HEIGHT,
			x = 60,
			y = 1 + SB.conf.C_HEIGHT * 7,
			text = "",
			width = 90,
			OnTextInput = {
                function(obj)
                    self.objectDefPanel:SetSearchString(obj.text)
                end
            },
            OnKeyPress = {
                function(obj)
                    self.objectDefPanel:SetSearchString(obj.text)
                end
            },
		},
    }
end