require "Log"
local DEBUG = 0;
local EventCentre = {}

function EventCentre:init()
    self.listeners_ = {}
    self.nextListenerHandleIndex_ = 0
end

function EventCentre:addEventListener( eventName, listener, tag )
    assert(type(eventName) == "string" and eventName ~= "", "EventCentre:addEventListener()-invalid eventName, tag="..tostring(tag)..",eventName="..tostring(eventName) );
    eventName = string.upper(eventName)
    if self.listeners_[eventName] == nil then
        self.listeners_[eventName] = {}
    end

    self.nextListenerHandleIndex_ = self.nextListenerHandleIndex_ + 1
    local handle = tostring(self.nextListenerHandleIndex_)
    tag = tag or ""
    self.listeners_[eventName][handle] = {listener, tag}

    if DEBUG > 1 then
        logInfo("%s [EventCentre] addEventListener() - event: %s, handle: %s, tag: %s", tostring(self.target_), eventName, handle, tostring(tag))
    end

    return handle
end

function EventCentre:dispatchEvent(event)
    event.name = string.upper(tostring(event.name))
    local eventName = event.name
    if DEBUG > 1 then
        logInfo("%s [EventCentre] dispatchEvent() - event %s", tostring(self.target_), eventName)
    end

    if self.listeners_[eventName] == nil then return end
    event.target = self.target_
    event.stop_ = false
    event.stop = function(self)
        self.stop_ = true
    end

    for handle, listener in pairs(self.listeners_[eventName]) do
        if DEBUG > 1 then
            logInfo("%s [EventCentre] dispatchEvent() - dispatching event %s to listener %s", tostring(self.target_), eventName, handle)
        end
        -- listener[1] = listener
        -- listener[2] = tag
        listener[1](event)
        if event.stop_ then
            if DEBUG > 1 then
                logInfo("%s [EventCentre] dispatchEvent() - break dispatching for event %s", tostring(self.target_), eventName)
            end
            break
        end
    end

    return self.target_
end

function EventCentre:removeEventListener( handleToRemove )
    for eventName, listenersForEvent in pairs(self.listeners_) do
        for handle, _ in pairs(listenersForEvent) do
            if handle == handleToRemove then
                listenersForEvent[handle] = nil
                if DEBUG > 1 then
                    logInfo("%s [EventCentre] removeEventListener() - remove listener [%s] for event %s", tostring(self.target_), handle, eventName)
                end
                return self.target_
            end
        end
    end

    return self.target_
end

function EventCentre:removeEventListenersByTag(tagToRemove)
    for eventName, listenersForEvent in pairs(self.listeners_) do
        for handle, listener in pairs(listenersForEvent) do
            -- listener[1] = listener
            -- listener[2] = tag
            if listener[2] == tagToRemove then
                listenersForEvent[handle] = nil
                if DEBUG > 1 then
                    logInfo("%s [EventCentre] removeEventListener() - remove listener [%s] for event %s", tostring(self.target_), handle, eventName)
                end
            end
        end
    end

    return self.target_
end

function EventCentre:removeEventListenersByEvent(eventName)
    self.listeners_[string.upper(eventName)] = nil
    if DEBUG > 1 then
        logInfo("%s [EventCentre] removeAllEventListenersForEvent() - remove all listeners for event %s", tostring(self.target_), eventName)
    end
    return self.target_
end

function EventCentre:removeAllEventListeners()
    self.listeners_ = {}
    if DEBUG > 1 then
        logInfo("%s [EventCentre] removeAllEventListeners() - remove all listeners", tostring(self.target_))
    end
    return self.target_
end

function EventCentre:hasEventListener(eventName)
    event.name = string.upper(tostring(eventName))
    local t = self.listeners_[eventName]
    for _, __ in pairs(t) do
        return true
    end
    return false
end

function EventCentre:dumpAllEventListeners()
    print("---- EventCentre:dumpAllEventListeners() ----")
    for name, listeners in pairs(self.listeners_) do
        printf("-- event: %s", name)
        for handle, listener in pairs(listeners) do
            printf("--     listener: %s, handle: %s", tostring(listener), tostring(handle))
        end
    end
    return self.target_
end

EventCentre:init();
return EventCentre;
