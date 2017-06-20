SB.classes = {}
-- include this dir
SB.classes[SB_DIR .. "util.lua"] = true

function MakeComponentPanel(parentPanel)
    local componentPanel = Control:New {
        parent = parentPanel,
        width = "100%",
        height = SB.conf.B_HEIGHT + 8,
        orientation = "horizontal",
        padding = {0, 0, 0, 0},
        itemMarging = {0, 0, 0, 0},
        margin = { 0, 0, 0, 0},
        resizeItems = false,
    }
    return componentPanel
end

--non recursive file include
function SB.IncludeDir(dirPath)
    local files = VFS.DirList(dirPath)
    local context = Script.GetName()
    for i = 1, #files do
        local file = files[i]
        -- don't load files ending in _gadget.lua in LuaUI nor _widget.lua in LuaRules
        if file:sub(-string.len(".lua")) == ".lua" and
            (context ~= "LuaRules" or file:sub(-string.len("_widget.lua")) ~= "_widget.lua") and
            (context ~= "LuaUI" or file:sub(-string.len("_gadget.lua")) ~= "_gadget.lua") then

            SB.Include(file)
        end
    end
end

function SB.Include(path)
    if not SB.classes[path] then
        -- mark it included before it's actually included to prevent circular inclusions
        SB.classes[path] = true
        VFS.Include(path)
    end
end

function SB.ZlibCompress(str)
    return tostring(#str) .. "|" .. VFS.ZlibCompress(str)
end

function SB.ZlibDecompress(str)
    local compressedSize = 0
    local strStart = 0
    for i = 1, #str do
        local substr = str:sub(1, i)
        if str:sub(i,i) == '|' then
            compressedSize = tonumber(str:sub(1, i - 1))
            strStart = i + 1
            break
        end
    end
    if compressedSize == 0 then
        error("string is not of valid format")
    end
    return VFS.ZlibDecompress(str:sub(strStart, #str), compressedSize)
end

function CallListeners(listeners, ...)
    for i = 1, #listeners do
        local listener = listeners[i]
        listener(...)
    end
end

function SB.MakeConfirmButton(dialog, btnConfirm)
    dialog.OnConfirm = {}
    btnConfirm.OnClick = {
        function()
            CallListeners(dialog.OnConfirm)
            dialog:Dispose()
        end
    }
end

function SB.MakeRadioButtonGroup(checkBoxes)
    for i = 1, #checkBoxes do
        local checkBox = checkBoxes[i]
        table.insert(checkBox.OnChange,
            function(cbToggled, checked)
                if not checked then
                    return
                end
                for j = 1, #checkBoxes do
                    if i ~= j then
                        local cb = checkBoxes[j]
                        if cb.checked then
                            cb:Toggle()
                        end
                    end
                end
            end
        )
    end
end

function SB.checkAreaIntersections(x, z)
    local areas = SB.model.areaManager:getAllAreas()
    local selected, dragDiffX, dragDiffZ
    for _, areaID in pairs(areas) do
        local area = SB.model.areaManager:getArea(areaID)
        local objectX, _, objectZ = areaBridge.spGetObjectPosition(areaID)
        if x >= area[1] and x < area[3] and z >= area[2] and z < area[4] then
            selected = areaID
            dragDiffX = objectX - x
            dragDiffZ = objectZ - z
        end
    end
    return selected, dragDiffX, dragDiffZ
end

SB.assignedCursors = {}
function SB.SetMouseCursor(name)
    SB.cursor = name
    if SB.cursor ~= nil then
        if SB.assignedCursors[name] == nil then
            Spring.AssignMouseCursor(name, name, false)
            SB.assignedCursors[name] = true
        end
        Spring.SetMouseCursor(SB.cursor)
    end
end

function SB.MakeSeparator(panel)
    local lblSeparator = Line:New {
        parent = panel,
        height = SB.conf.B_HEIGHT + 10,
        width = "100%",
    }
    return lblSeparator
end


function SB.CreateNameMapping(origArray)
    local newArray = {}
    for i = 1, #origArray do
        local item = origArray[i]
        newArray[item.name] = item
    end
    return newArray
end

function SB.GroupByField(origArray, field)
    local newArray = {}
    for i = 1, #origArray do
        local item = origArray[i]
        local fieldValue = item[field]
        if newArray[fieldValue] then
            table.insert(newArray[fieldValue], item)
        else
            newArray[fieldValue] = { item }
        end
    end
    return newArray
end

function GetKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function GetField(origArray, field)
    local newArray = {}
    for k, v in pairs(origArray) do
        table.insert(newArray, v[field])
    end
    return newArray
end

function GetIndex(table, value)
    assert(value ~= nil, "GetIndex called with nil value.")
    for i = 1, #table do
        if table[i] == value then
            return i
        end
    end
end

-- basically does origTable = newTableValues but instead uses the old table reference
function SetTableValues(origTable, newTable)
    for k in pairs(origTable) do
        origTable[k] = nil
    end
    for k in pairs(newTable) do
        origTable[k] = newTable[k]
    end
end

function SortByName(t, name)
    local i = 1
    local sortedTable = {}
    for k, v in pairs(t) do
        sortedTable[i] = v
        i = i + 1
    end
    table.sort(sortedTable,
        function(a, b)
            return a[name] < b[name]
        end
    )
    return sortedTable
end

function PassToGadget(prefix, tag, data)
    newTable = { tag = tag, data = data }
    local msg = prefix .. "|table" .. table.show(newTable)
    Spring.SendLuaRulesMsg(msg)
end

SB.humanExpressionMaxLevel = 3
function SB.humanExpression(data, exprType, dataType, level)
    local success, data = pcall(function()

    if level == nil then
        level = 1
    end
    if SB.humanExpressionMaxLevel < level then
        return "..."
    end

    if exprType == "condition" and data.typeName:find("compare_") then
        local firstExpr = SB.humanExpression(data.first, "value", nil, level + 1)
        local relation
        if data.typeName == "compare_number" then
            relation = SB.humanExpression(data.relation, "numeric_comparison", nil, level + 1)
        else
            relation = SB.humanExpression(data.relation, "identity_comparison", nil, level + 1)
        end
        local secondExpr = SB.humanExpression(data.second, "value", nil, level + 1)
        local condHumanName = SB.metaModel.functionTypes[data.typeName].humanName
        return condHumanName .. " (" .. firstExpr .. " " .. relation .. " " .. secondExpr .. ")"
    elseif exprType == "action" then
        local action = SB.metaModel.actionTypes[data.typeName]
        local humanName = action.humanName .. " ("
        for i, input in pairs(action.input) do
            humanName = humanName .. SB.humanExpression(data[input.name], "value", nil, level + 1)
            if i ~= #action.input then
                humanName = humanName .. ", "
            end
        end
        return humanName .. ")"
    elseif (exprType == "value" and data.type == "expr") or exprType == "condition" then
        local expr = nil
        if data.expr then
            expr = data.expr[1]
        else
            expr = data
        end
        local exprHumanName = SB.metaModel.functionTypes[expr.typeName].humanName

        local paramsStr = ""
        local first = true
        for k, v in pairs(expr) do
            if k ~= "typeName" then
                if not first then
                    paramsStr = paramsStr .. ", "
                end
                first = false
                paramsStr = paramsStr .. SB.humanExpression(v, "value", k, level + 1)
            end
        end
        return exprHumanName .. " (" .. paramsStr .. ")"
    elseif exprType == "value" then
        if data.type == "pred" then
            if dataType == "unitType" then
                local unitDef = UnitDefs[data.value]
                local dataIDStr = "(id=" .. tostring(data.value) .. ")"
                if unitDef then
                    return tostring(unitDef.name) .. " " .. dataIDStr
                else
                    return dataIDStr
                end
            elseif dataType == "unit" then
                local unitID = SB.model.unitManager:getSpringUnitID(data.value)
                local dataIDStr = "(id=" .. tostring(data.value) .. ")"
                if Spring.ValidUnitID(unitID) then
                    local unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
                    if unitDef then
                        return tostring(unitDef.name) .. " " .. dataIDStr
                    else
                        return dataIDStr
                    end
                else
                    return dataIDStr
                end
            elseif dataType == "trigger" then
                return data.name
            else
                return tostring(data.value)
            end
        elseif data.type == "spec" then
            return data.name
        elseif data.type == "var" then
            return SB.model.variableManager:getVariable(data.value).name
        elseif data.orderTypeName then
            local orderType = SB.metaModel.orderTypes[data.orderTypeName]
            local humanName = orderType.humanName
            for i = 1, #orderType.input do
                local input = orderType.input[i]
                humanName = humanName .. " " .. SB.humanExpression(data[input.name], "value", nil, level + 1)
            end
            return humanName
        end
        return "nothing"
    elseif exprType == "numeric_comparison" then
        return SB.metaModel.numericComparisonTypes[data.cmpTypeID]
    elseif exprType == "identity_comparison" then
        return SB.metaModel.identityComparisonTypes[data.cmpTypeID]
	end
    return data.humanName
    end)
    if success then
        return data
    else
        return "Err."
    end
end

function SB.GenerateTeamColor()
    return 1, 1, 1, 1 --yeah, ain't it great
end

function SB.GetTeams(widget)
    local teams = {}

    local gaiaTeamID = Spring.GetGaiaTeamID()
    for _, teamID in pairs(Spring.GetTeamList()) do
        local team = { id = teamID }
        table.insert(teams, team)

        team.name = tostring(team.id)

        local aiID, _, _, name = Spring.GetAIInfo(team.id)
        if aiID ~= nil then
            team.name = team.name .. ": " .. name
            team.ai = true -- TODO: maybe get the exact AI as well?
        end

        local r, g, b, a = SB.GenerateTeamColor()--Spring.GetTeamColor(teamID)
        if widget then
            r, g, b, a = Spring.GetTeamColor(team.id)
            team.color = { r = r, g = g, b = b, a = a }
        end

        local _, _, _, _, side, allyTeam = Spring.GetTeamInfo(team.id)
        team.allyTeam = allyTeam
        team.side = side

        team.gaia = gaiaTeamID == team.id
        if team.gaia then
            team.ai = true
        end

		if not widget then
			local metal, metalMax = Spring.GetTeamResources(team.id, "metal")
			team.metal = metal
			team.metalMax = metalMax

			local energy, energyMax = Spring.GetTeamResources(team.id, "energy")
			team.energy = energy
			team.energyMax = energyMax
		end
    end
    return teams
end

local function filterControls(ctrl)
    if ctrl.classname == "button" or ctrl.classname == "combobox" or ctrl.classname == "editbox" or ctrl.classname == "checkbox" or ctrl.classname == "label" or ctrl.classname == "editbox" then
        return {ctrl}
    end
    local childRets = {}
    for _, childCtrl in pairs(ctrl.childrenByName) do
        childRet = filterControls(childCtrl)
        if childRet ~= nil and type(childRet) == "table" then
            for _, v in pairs(childRet) do
                table.insert(childRets, v)
            end
        end
    end
    return childRets
end

local function hintCtrlFunction(ctrl, startTime, timeout, color)
    local deltaTime = os.clock() - startTime
    local newColor = SB.deepcopy(color)
    newColor[4] = 0.2 + math.abs(math.sin(deltaTime * 6) / 3.14)

    if ctrl.classname == "label" or ctrl.classname == "checkbox" or ctrl.classname == "editbox" then
        ctrl.font.color = newColor
    else
        ctrl.backgroundColor = newColor
    end
    ctrl:Invalidate()
    SB.delay(
        function()
            if os.clock() - startTime < timeout then
                hintCtrlFunction(ctrl, startTime, timeout, color)
            else
                if ctrl.classname == "label" or ctrl.classname == "checkbox" or ctrl.classname == "editbox" then
                    ctrl.font.color = ctrl._originalColor
                else
                    ctrl.backgroundColor = ctrl._originalColor
                end
                ctrl._originalColor = nil
                ctrl:Invalidate()
            end
        end
    )
end


function SB.HintControl(control, color, timeout)
    timeout = timeout or 1
    color = color or {1, 0, 0, 1}
    local childControls = filterControls(control)
    local startTime = os.clock()
    for _, childControl in pairs(childControls) do
        if childControl._originalColor == nil then
            if childControl.classname == "label" or childControl.classname == "checkbox" or childControl.classname == "editbox" then
                childControl._originalColor = SB.deepcopy(childControl.font.color)
            else
                childControl._originalColor = SB.deepcopy(childControl.backgroundColor)
            end
            hintCtrlFunction(childControl, startTime, timeout, color)
        end
    end
end

function SB.SetClassName(class, className)
    class.className = className
    if SB.commandManager:getCommandType(className) == nil then
        SB.commandManager:addCommandType(className, class)
    end
end

function SB.deepcopy(t)
    if type(t) ~= 'table' then return t end
    local mt = getmetatable(t)
    local res = {}
    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = SB.deepcopy(v)
        end
        res[k] = v
    end
    setmetatable(res,mt)
    return res
end

function SB.GiveOrderToUnit(unitID, orderType, params)
    Spring.GiveOrderToUnit(unit, CMD.INSERT,
        { -1, orderType, CMD.OPT_SHIFT, unpack(params) }, { "alt" })
end

function SB.createNewPanel(opts)
    local dataTypeName = opts.dataType.type
    if dataTypeName == "unit" then
        return UnitPanel(opts)
    elseif dataTypeName == "feature" then
        return FeaturePanel(opts)
    elseif dataTypeName == "area" then
        return AreaPanel(opts)
    elseif dataTypeName == "trigger" then
        return TriggerPanel(opts)
    elseif dataTypeName == "unitType" then
        return UnitTypePanel(opts)
    elseif dataTypeName == "featureType" then
        return FeatureTypePanel(opts)
    elseif dataTypeName == "team" then
        return TeamPanel(opts)
    elseif dataTypeName == "number" then
        return NumberPanel(opts)
    elseif dataTypeName == "string" then
        return StringPanel(opts)
    elseif dataTypeName == "bool" then
        return BoolPanel(opts)
    elseif dataTypeName == "numericComparison" then
        return NumericComparisonPanel(opts)
    elseif dataTypeName == "order" then
        return OrderPanel(opts)
    elseif dataTypeName == "identityComparison" then
        return IdentityComparisonPanel(opts)
    elseif dataTypeName == "position" then
        return PositionPanel(opts)
    elseif dataTypeName == "function" or dataTypeName == "action" then
        return FunctionPanel(opts)
    elseif dataTypeName:find("_array") then
        return GenericArrayPanel(opts)
    elseif dataTypeName ~= nil and SB.metaModel:GetCustomDataType(dataTypeName) then
        return CustomDataTypePanel(opts)
    end
    Log.Error("No panel for this data: " .. tostring(dataTypeName))
end

SB.delayed = {
--     Update      = {},
    GameFrame   = {},
    DrawWorld   = {},
    DrawScreen  = {},
    Initialize = {},
}
function SB.delayGL(func, params)
    SB.Delay("DrawWorld", func, params)
end
function SB.delay(func, params)
    SB.Delay("GameFrame", func, params)
end
function SB.OnInitialize(func, params)
    SB.Delay("Initialize", func, params)
end
function SB.Delay(name, func, params)
    local delayed = SB.delayed[name]
    table.insert(delayed, {func, params or {}})
end

function SB.executeDelayed(name)
    local delayed = SB.delayed[name]
    SB.delayed[name] = {}
    for i, call in pairs(delayed) do
        xpcall(function() call[1](unpack(call[2])) end,
              function(err) Log.Error(debug.traceback(err)) end )
    end
end

function SB.glToFontColor(color)
    return "\255" ..
        string.char(math.ceil(255 * color.r)) ..
        string.char(math.ceil(255 * color.g)) ..
        string.char(math.ceil(255 * color.b))
end

function SB.SetControlEnabled(control, enabled)
    control.disableChildrenHitTest = not enabled
    control:Invalidate()
    for _, childCtrl in pairs(control.childrenByName) do
        SB.SetControlEnabled(childCtrl, enabled)
    end
end

function SB.DirExists(path, ...)
    return (#VFS.SubDirs(path, "*", ...) + #VFS.DirList(path, "*", ...)) ~= 0
end

local warningsIssued = {}

function SB.MinVersion(versionNumber, feature)
    if Script.IsEngineMinVersion == nil or not Script.IsEngineMinVersion(versionNumber) then
        if warningsIssued[feature] == nil then
            Log.Warning(feature .. " requires a minimum Spring version of " .. tostring(versionNumber))
            warningsIssued[feature] = true
        end
        return false
    end
    return true
end

function SB.FunctionExists(fun, feature)
    if fun ~= nil then
        if warningsIssued[feature] == nil then
            Log.Warning(feature .. " requires a minimum Spring version of " .. tostring(versionNumber))
            warningsIssued[feature] = true
        end
        return false
    end
    return true
end

function boolToNumber(bool)
    if bool then
        return 1
    else
        return 0
    end
end

-- should go to string utils
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function explode(div, str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
