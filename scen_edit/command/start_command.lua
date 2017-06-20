StartCommand = Command:extends{}

function StartCommand:init()
    self.className = "StartCommand"
end

function StartCommand:execute()
    if SB.rtModel.hasStarted then
        return
    end

    Log.Notice("Starting game...")

    local oldModel = SB.model:Serialize()
    SB.model.oldModel = oldModel

    local heightMap = HeightMap()
    heightMap:Serialize()
    SB.model.oldHeightMap = heightMap

    SB.rtModel:LoadMission(SB.model:GetMetaData())

    if SB_USE_PLAY_PAUSE then
        Spring.SendCommands("pause 0")
    else
        local allUnits = Spring.GetAllUnits()
        for _, unitID in pairs(allUnits) do
            --[[Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, { 2 }, {})
            Spring.MoveCtrl.Disable(unitID)
            SB.delay(function()
                Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
                Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
            end)]]--
            Spring.SetUnitHealth(unitID, { paralyze = 0 })
        end
    end

    Spring.SetGameRulesParam("sb_gameMode", "test")
    SB.rtModel:GameStart()
end
