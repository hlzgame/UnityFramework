local game_proto = {}

game_proto.types = [[
.package {
  type 0 : integer
  session 1 : integer
}

.Position {
  x 0 : integer
  y 1 : integer
  z 2 : integer
  o 3 : integer
}

.MoveInfo {
  account 0 : integer
  pos 1 : Position
}

.ObjectInfo {
    id 0 : integer
    type 1 : integer
    data 2 : string
}
]]

game_proto.c2s = [[
move 1 {
	request {
		pos 0 : Position
	}
	response {
		result 0 : integer
	}
}

playersInfo 2 {
    response {
      player 0 : *MoveInfo
    }
}

myInfo 3 {
    response {
      pos 0 : Position
    }
}
]]

game_proto.s2c = [[
playerMove 10001 {
  request {
    player 0 : MoveInfo
  }
}

createObjects 10002 {
    request {
        objects 0: *ObjectInfo
    }
}
]]

return game_proto
