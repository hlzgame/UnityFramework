--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local class = require("Utils/middleclass")
local event_manager = require("eventsystem/event_manager")

event_dispatcher = class("event_dispatcher")
function event_dispatcher:initialize()
    self.ui_event_manager = event_manager()
end

function event_dispatcher:instance()
    if self._instance == nil then
        self._instance = event_dispatcher()
    end

    return self._instance
end
