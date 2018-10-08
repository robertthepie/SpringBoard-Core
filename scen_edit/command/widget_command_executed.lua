WidgetCommandExecuted = Command:extends{}
WidgetCommandExecuted.className = "WidgetCommandExecuted"

function WidgetCommandExecuted:init(display, cmdIDs)
    self.display = display
    self.cmdIDs = cmdIDs
end

function WidgetCommandExecuted:execute()
    SB.commandManager:callListeners("OnCommandExecuted",
        self.cmdIDs, false, false, self.display)
end

WidgetCommandUndo = Command:extends{}
WidgetCommandUndo.className = "WidgetCommandUndo"

function WidgetCommandUndo:execute()
    SB.commandManager:callListeners("OnCommandExecuted",
        self.cmdIDs, true)
end

WidgetCommandRedo = Command:extends{}
WidgetCommandRedo.className = "WidgetCommandRedo"

function WidgetCommandRedo:execute()
    SB.commandManager:callListeners("OnCommandExecuted",
        self.cmdIDs, false, true)
end

-- undo stack has been cleared
WidgetCommandClearUndoStack = Command:extends{}
WidgetCommandClearUndoStack.className = "WidgetCommandClearUndoStack"

function WidgetCommandClearUndoStack:execute()
    SB.commandManager:callListeners("OnClearUndoStack")
    SB.commandManager:clearUndoStack()
end

-- redo stack has been cleared
WidgetCommandClearRedoStack = Command:extends{}
WidgetCommandClearRedoStack.className = "WidgetCommandClearRedoStack"

function WidgetCommandClearRedoStack:execute()
    SB.commandManager:callListeners("OnClearRedoStack")
    SB.commandManager:clearRedoStack()
end

-- removed first undo
WidgetCommandRemoveFirstUndo = Command:extends{}
WidgetCommandRemoveFirstUndo.className = "WidgetCommandRemoveFirstUndo"

function WidgetCommandRemoveFirstUndo:execute()
    SB.commandManager:callListeners("OnRemoveFirstUndo")
    SB.delayGL(function()
        SB.model.textureManager:RemoveFirst()
    end)
end

-- removed first redo
WidgetCommandRemoveFirstRedo = Command:extends{}
WidgetCommandRemoveFirstRedo.className = "WidgetCommandRemoveFirstRedo"

function WidgetCommandRemoveFirstRedo:execute()
    SB.commandManager:callListeners("OnRemoveFirstRedo")
end
