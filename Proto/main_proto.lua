local sparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local common_types = require "common_proto"

local _origin_proto_map = {}

if SProto then
	return SProto
end

SProto = {}

SProto.ProtoMap = {}

SProto.LOGIN_PROTO = 1
SProto.GAME_PROTO = 2
_origin_proto_map[SProto.LOGIN_PROTO] = require "login_proto"
_origin_proto_map[SProto.GAME_PROTO] = require "game_proto"

for k,v in pairs(_origin_proto_map) do
	local localTypes = v.types or ""
	SProto.ProtoMap[k] = sparser.parse(common_types .. localTypes .. v.c2s .. v.s2c)
	sprotoloader.save(SProto.ProtoMap[k], k)
end

return SProto
