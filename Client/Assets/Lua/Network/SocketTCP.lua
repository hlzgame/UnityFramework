--[[
For quick-cocos2d-x
SocketTCP lua
@author zrong (zengrong.net)
Creation: 2013-11-12
Last Modification: 2013-12-05
@see http://cn.quick-x.com/?topic=quickkydsocketfzl
]]

require "Utils/Log"

local SOCKET_TICK_TIME = 0.05 			-- check socket data interval
local SOCKET_RECONNECT_TIME = 0.5		-- socket reconnect try interval --[CY MOD: 加长方便debug, default is 5]
local SOCKET_CONNECT_FAIL_TIMEOUT = 6	-- socket failure timeout  --[CY MOD: 加长方便debug, default is 3]

local STATUS_CLOSED = "closed"
local STATUS_NOT_CONNECTED = "Socket is not connected"
local STATUS_ALREADY_CONNECTED = "already connected"
local STATUS_ALREADY_IN_PROGRESS = "Operation already in progress"
local STATUS_TIMEOUT = "timeout"

local socket = require "socket"

SocketTCP = class("SocketTCP")

SocketTCP.EVENT_DATA = "SOCKET_TCP_DATA"
SocketTCP.EVENT_CLOSE = "SOCKET_TCP_CLOSE"
SocketTCP.EVENT_CLOSED = "SOCKET_TCP_CLOSED"
SocketTCP.EVENT_CONNECTED = "SOCKET_TCP_CONNECTED"
SocketTCP.EVENT_CONNECT_FAILURE = "SOCKET_TCP_CONNECT_FAILURE"
SocketTCP.EVENT_CLOSE_REASON = "SOCKET_TCP_CLOSE_REASON"

SocketTCP._VERSION = socket._VERSION
SocketTCP._DEBUG = socket._DEBUG

function SocketTCP.getTime()
	return socket.gettime()
end

function SocketTCP:ctor(__host, __port, __retryConnectWhenFailure,socketIndex)
    self.host = __host
    self.port = __port
	self.tickTimer = nil			-- timer for data
	self.reconnectTimer = nil		-- timer for reconnect
	self.connectTimer = nil	-- timer for connect timeout
	self.name = 'SocketTCP'
	self.tcp = nil
	self.isRetryConnect = __retryConnectWhenFailure or true
	self.isConnected = false
    self.isSocketTCPAvailbale = true;
    self._sendBuffer = nil;
    self._sentSize = 0;
    self._socketIndex = socketIndex;
	self._sendCooldownCount = 0;
end

function SocketTCP:setName( __name )
	self.name = __name
	return self
end

function SocketTCP:setTickTime(__time)
	SOCKET_TICK_TIME = __time
	return self
end

function SocketTCP:setReconnTime(__time)
	SOCKET_RECONNECT_TIME = __time
	return self
end

function SocketTCP:setConnFailTime(__time)
	SOCKET_CONNECT_FAIL_TIMEOUT = __time
	return self
end

function SocketTCP:connect(__host, __port, __retryConnectWhenFailure )
    self:removeTimer();
    self:__clearSocketBuffer();
    
	if __host then self.host = __host end
	if __port then self.port = __port end
	if __retryConnectWhenFailure ~= nil then self.isRetryConnect = __retryConnectWhenFailure end
	assert(self.host or self.port, "Host and port are necessary!")
	logInfo("%s.connect(%s, %d)", self.name, self.host, self.port)
	self.tcp = socket.tcp()
    if nil == self.tcp then
        self:close()
        self:_connectFailure()
        return;
    end
	self.tcp:settimeout(0)
    self.isSocketTCPAvailbale = true;

	local function __checkConnect()
		local __succ = self:_connect()
		if __succ then
			self:_onConnected()
		end
		return __succ
	end

	if not __checkConnect() then
		-- check whether connection is success
		-- the connection is failure if socket isn't connected after SOCKET_CONNECT_FAIL_TIMEOUT seconds
		local __connectTimeTick = function ()
			logInfo("%s.connectTimeTick", self.name)
			if self.isConnected then return end
			self.waitConnect = self.waitConnect or 0
			self.waitConnect = self.waitConnect + SOCKET_RECONNECT_TIME;
            logInfo("%f.connectTimeTick %f", self.waitConnect, SOCKET_CONNECT_FAIL_TIMEOUT );
			if self.waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
				self.waitConnect = nil
				self:close()
				self:_connectFailure()
			end
			__checkConnect()
		end
		self.connectTimer = Timer.New(__connectTimeTick, SOCKET_RECONNECT_TIME, -1,false)
	end
end 

function SocketTCP:send(__data)
	if nil == self._sendBuffer then
        self._sendBuffer = __data;
    else
        self._sendBuffer = self._sendBuffer .. __data;    
    end
    self:update();
end

function SocketTCP:__clearSocketBuffer()
    self._sendBuffer = nil;
end

function SocketTCP:delaySendMessage()
	self._sendCooldownCount = 10;
end

function SocketTCP:update()
	if nil == self.tcp then
		return;
	end
	---在ios版本下，发现从后台切回来的时候，会发送消息，测试在切回来的时候，延迟10帧发送
	if self._sendCooldownCount > 0 then
		self._sendCooldownCount = self._sendCooldownCount - 1;
		return;
	end
    if true == self:isTCPConnected() and nil ~= self._sendBuffer then
        local totalSize = string.len( self._sendBuffer );
        logInfo("totalSize:"..totalSize)
        if totalSize ~= 0 then
            local size , error , sentSize = self.tcp:send(self._sendBuffer )
            if nil ~= error then
                --延时错误，代表发送窗口已满，等待下一次发送
                --网络还没有建立连接，等待建立连接后再次发送
                if error == STATUS_TIMEOUT or error == STATUS_NOT_CONNECTED then
                    self._sendBuffer = string.sub(self._sendBuffer, -1 * ( totalSize - sentSize ));
                    logInfo("分拆网络包,包的总的大小=%f,发送大小=%f", totalSize, sentSize );
                --网络已经关闭
                --其他的未知错误
                --STATUS_CLOSED
                else
					mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CLOSE_REASON, data=error, point = "send",ip = self.host, port = self.port } );
                    logInfo("网络发送故障，清空发送缓冲区，错误为"..error );
                    self:__clearSocketBuffer();
                    self:__closeSocket();
                end
            else
                --发送正常
                logInfo("send buffer success")
                self:__clearSocketBuffer();
            end
        end
    end
end

function SocketTCP:isTCPConnected()
    return self.isConnected;
end

function SocketTCP:setConnectFlag( b )
    self.isConnected = b;
end

function SocketTCP:removeTimer()
    if self.connectTimer then 
        self.connectTimer:Stop()
        self.connectTimer = nil; 
    end
	if self.tickTimer then 
        self.tickTimer:Stop()
        self.tickTimer = nil;
    end
end

function SocketTCP:close( ... )
	logInfo("%s.close", self.name)
    self:__clearSocketBuffer();
    if nil ~= self.tcp then
	    self.tcp:close();
    end
	mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CLOSE})
end

-- disconnect on user's own initiative.
function SocketTCP:disconnect()
    self:__clearSocketBuffer();
	self:_disconnect()
	self.isRetryConnect = false -- initiative to disconnect, no reconnect.

    logInfo("SocketTCP:disconnect");
end

--------------------
-- private
--------------------

--- When connect a connected socket server, it will return "already connected"
-- @see: http://lua-users.org/lists/lua-l/2009-10/msg00584.html
function SocketTCP:_connect()
    self:__clearSocketBuffer();
	local __succ, __status = self.tcp:connect(self.host, self.port)
	--logInfo(self.host.."SocketTCP._connect:".. tostring(__succ).. tostring(__status))
	return __succ == 1 or __status == STATUS_ALREADY_CONNECTED
end

function SocketTCP:_disconnect()
    self:__clearSocketBuffer();
    logInfo("%s.SocketTCP:_disconnect", self.name);
	if nil == self.tcp then
		return;
	end
	self.tcp:shutdown()
	--mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CLOSED})
end

function SocketTCP:__closeSocket()
    self:close()
	if self.isConnected then
        logInfo("%s.closed(%s, %d)", self.name, self.host, self.port)
		self:_onDisconnect()
	else
        logInfo("%s.failed(%s, %d)", self.name, self.host, self.port)
		self:_connectFailure()
	end
    self:__clearSocketBuffer();
    self.isSocketTCPAvailbale = false;
end

function SocketTCP:checkNetworkState()
    if false == self.isSocketTCPAvailbale then
        self:removeTimer();
        return;
    end
	if nil == self.tcp then
		return;
	end
	while true do
		-- if use "*l" pattern, some buffer will be discarded, why?
		local __body, __status, __partial = self.tcp:receive("*a")	-- read the package body
		--logInfo("body:", __body, "__status:", __status, "__partial:", __partial)
    	if __status == STATUS_CLOSED or __status == STATUS_NOT_CONNECTED then
		    self:__closeSocket();
			mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CLOSE_REASON, data=__status, point = "receive",ip = self.host, port = self.port } );
		   	return
	    end
		if 	(__body and string.len(__body) == 0) or
			(__partial and string.len(__partial) == 0)
		then return end
		if __body and __partial then __body = __body .. __partial end
		mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_DATA, data=(__partial or __body), partial=__partial, body=__body ,socketID = self._socketIndex })
	end
end

-- connecte success, cancel the connection timerout timer
function SocketTCP:_onConnected()
    self:__clearSocketBuffer();
	logInfo("%s._onConnectd", self.name)
	self.isConnected = true
	mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CONNECTED,socketID = self._socketIndex})
	if self.connectTimer then 
		self.connectTimer:Stop()
        self.connectTimer = nil;
    end
	-- start to read TCP data

	self.tickTimer = Timer.New(handler(self, self.checkNetworkState),SOCKET_TICK_TIME,-1,false)
end


function SocketTCP:_onDisconnect()
	logInfo("%s._onDisConnect", self.name);
    self:removeTimer();
	self.isConnected = false;
	mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CLOSED})
	--self:_reconnect();
end
function SocketTCP:_connectFailure(status)
	logInfo("%s._connectFailure", self.name);
    self:removeTimer();
	mtEventCentre():dispatchEvent({name=SocketTCP.EVENT_CONNECT_FAILURE,socketID = self._socketIndex})
	self:_reconnect();
    self.isConnected = false;
end

-- if connection is initiative, do not reconnect
function SocketTCP:_reconnect(__immediately)
	
    if not self.isRetryConnect then return end
	logInfo("%s._reconnect", self.name)
	if __immediately then self:connect() return end
	if self.reconnectTimer then 
		self.reconnectTimer:Stor()
		self.reconnectTimer = nil
	end
	local __doReConnect = function ()
		self:connect()
	end
	self.reconnectTimer = Timer.New(__doReConnect,SOCKET_RECONNECT_TIME,1,false)
end

