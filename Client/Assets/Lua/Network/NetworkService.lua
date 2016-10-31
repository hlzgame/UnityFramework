require "Network.SocketTCP"
require "Utils.Log"
local sprotoparser = require "Network.sprotoparser"
local sprotoloader = require "Network.sprotoloader"
local sproto = require "Network.sproto"
local crypt = require "crypt"
local Sproto = require "main_proto"
NetworkService = class("NetworkService")

function NetworkService:ctor()
    self.fd = nil
    self.ip = nil
    self.port = nil
    self.recvBuffer = ""

    mtEventCentre():addEventListener(SocketTCP.EVENT_CONNECTED, handler(self,self.onConnectSuccess) );
    mtEventCentre():addEventListener(SocketTCP.EVENT_CLOSE, handler(self,self.onConnectClosed) );
    mtEventCentre():addEventListener(SocketTCP.EVENT_CLOSED, handler(self,self.onConnectClosed) );
    mtEventCentre():addEventListener(SocketTCP.EVENT_CONNECT_FAILURE, handler(self,self.onConnectFailure) );
    mtEventCentre():addEventListener(SocketTCP.EVENT_DATA, handler(self,self.onReceiveMessage) );
    mtEventCentre():addEventListener(SocketTCP.EVENT_CLOSE_REASON, handler(self,self.onNetworkError));

    self.host = nil
    self.sessionCB = {}
end

function NetworkService:connect()
    print("NetworkService:connect")
    self.fd = SocketTCP.new(self.ip,self.port)
    self.fd:connect()
end

function NetworkService:onConnectSuccess()
    self.session = 0
    if self.connectCB ~= nil then
        self.connectCB()
    end
end

function NetworkService:onConnectClosed()
end

function NetworkService:onConnectFailure()
end

function NetworkService:onReceiveMessage(event)
    local function unpack_package(text)
          local size = #text
          if size < 2 then
             return _,text
          end
          local s = text:byte(1)* 256 + text:byte(2)
          if size < s + 2 then
             return _,text
          end
          print("v "..text:sub(3,2+s))
          return text:sub(3,2+s),text:sub(3+s)
    end

    local result
    result, self.recvBuffer = unpack_package(self.recvBuffer .. event.data.data)
    if result then
        self:dealPackage(self.host:dispatch(result))
    end
end

function NetworkService:dealRequest()
  assert(false)
end


function NetworkService:dealResponse(session,args)
      print("RESPONSE",session)

      if self.sessionCB[session] == nil then
        return
      end

      local f = self.sessionCB[session]
      f(args)
end

function NetworkService:dealPackage(t,...)
    if t == "REQUEST" then
       self:dealRequest(...)
    else
      assert(t=="RESPONSE")
      self:dealResponse(...)
    end
end

function NetworkService:onNetworkError()
end

function NetworkService:_sendPackage(pack)
    local size = #pack
    local a = size % 256
    size = math.floor(size / 256)
    local b = size
    local pack = string.char(b)..string.char(a).. pack
    assert(self.fd ~= nil)
    self.fd:send(pack)
end

function NetworkService:sendMessage(name,data,callback)
      self.session = self.session + 1
      if callback then
        self.sessionCB[self.session] = callback
      end
      
      local str = self.request(name,data,self.session)
      self:_sendPackage(str)
end


-----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	写在华丽的分割线以下的函数都是临时使用的。
]]
function NetworkService:connectLoginServer()
	assert(self.fd == nil,"already has connect to the server")
	self.ip = "47.88.6.248"
	self.port = "8001"
	
	self.connectCB = handler(self,self.connectSuccessLogin)
	self:connect()

  local currProto = sprotoloader.load(Sproto.LOGIN_PROTO)
  self.host = currProto:host "package"
  self.request = self.host:attach(sproto)
end

function NetworkService:connectSuccessLogin()
  clientkey = "blackfe1"
  self:sendMessage("getSecret",{clientkey = crypt.base64encode(crypt.dhexchange(clientkey))},handler(self,self.getSecretSuccess))
end

function NetworkService:getSecretSuccess(args)
  local function verify_token(token)
      return string.format("%s:%s",
                       crypt.base64encode(token.user),
                       crypt.base64encode(token.password))
  end
  local serverkey = crypt.base64decode(args.serverkey)
  local challenge = crypt.base64decode(args.challenge)
  secret = crypt.dhsecret(serverkey, clientkey)
  local hmac = crypt.hmac64(challenge,secret)
  local token = crypt.base64encode(crypt.desencode(secret,verify_token({user = "blackfe"..math.random(100),password = "62544872"})))
  self:sendMessage("verify",{hmac = crypt.base64encode(hmac), token = token},handler(self,self.verifySuccess))
end

function NetworkService:verifySuccess(args)
    local function encode_token(token)
        local str = string.format("%s:%s",
                             crypt.base64encode(token.accountID),
                             crypt.base64encode(token.server))
        print("str ".. str)
        return str
    end
    if args.result ~= 0  then
        print("login failed")
    end
    local randomIndex = math.random(#args.zones)
    local server = args.zones[randomIndex].name
    server_ip = args.zones[randomIndex].ip
    local etoken = crypt.base64encode(crypt.desencode(secret,encode_token({accountID = tostring(args.accountID), server = server})))
    self:sendMessage("login",{etoken = etoken},handler(self,self.loginSuccess))
end

function NetworkService:loginSuccess(args)
  print("LoginSuccess")
end

function NetworkService:connectGameServer()
end

return NetworkService

