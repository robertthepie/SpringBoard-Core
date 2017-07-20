SB.Include(Path.Join(SB_VIEW_DIR, "editor.lua"))

NewProjectDialog = Editor:extends{}

function NewProjectDialog:init()
    self:super("init")

    self.initializing = true

    local btnOK = Button:New {
        caption = 'OK',
        width = '40%',
        x = 1,
        bottom = 1,
        height = SB.conf.B_HEIGHT,
        backgroundColor = SB.conf.BTN_OK_COLOR,
        OnClick = {
            function()
                local scriptTxt = StartScript.GenerateScriptTxt({
                    game = {
                        name = Game.gameName,
                        version = Game.gameVersion,
                    },
                    map = "FlatTemplate",
                    teams = {},
                    players = {},
                    ais = {},
                    mapOptions = {
                        sizeX = self.fields["sizeX"].value,
                        sizeZ = self.fields["sizeZ"].value,
                    }
                })
                Spring.Echo(scriptTxt)
                Spring.Reload(scriptTxt)
                --if self:UpdateModel(self.variable) then
                --    self.window:Dispose()
                --end
            end
        }
    }
    local btnCancel = Button:New {
        caption = 'Cancel',
        width = '40%',
        x = '50%',
        bottom = 1,
        height = SB.conf.B_HEIGHT,
        backgroundColor = SB.conf.BTN_CANCEL_COLOR,
        OnClick = {
            function()
                self.window:Dispose()
            end
        }
    }

    self:AddField(GroupField({
        NumericField({
            name = "sizeX",
            title = "Size X:",
            width = 140,
            minValue = 1,
            value = 5,
            maxValue = 32,
        }),
        NumericField({
            name = "sizeZ",
            title = "Size Z:",
            width = 140,
            minValue = 1,
            value = 5,
            maxValue = 32,
        })
    }))

    local children = {
        btnOK,
        btnCancel,
        ScrollPanel:New {
            x = 0,
            y = 0,
            bottom = 30,
            right = 0,
            borderColor = {0,0,0,0},
            horizontalScrollbar = false,
            children = { self.stackPanel },
        },
    }

    self:Finalize(children, {notMainWindow=true, noCloseButton=true})
end
