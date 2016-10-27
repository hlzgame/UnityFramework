require "TableLoader"

local key_list = {}

for k,v in pairs(Table.Lottery) do
	if k ~= "__meta" and k ~= "get" then
		table.insert(key_list,k)
	end	
end

print(collectgarbage("count"))
local beginTime = os.clock()
for i = 0,10000000 do
	local index = math.random(#key_list)
	local data = Table.Lottery.get(key_list[index])
	local method = math.random(13)
	local rt
	if method == 1 then
		rt = data.iSet1
	elseif method == 2 then
		rt = data.iSet2
	elseif method == 3 then
		rt = data.iSet3
	elseif method == 4 then
		rt = data.iSet4
	elseif method == 5 then
		rt = data.test.iSet5
	elseif method == 6 then
		rt = data.test.iSet6
	elseif method == 7 then
		rt = data.iSet7
	elseif method == 8 then
		rt = data.iSet8
	elseif method == 9 then
		rt = data.iSet9
	elseif method == 10 then
		rt = data.iSet10
	elseif method == 11 then
		rt = data.iSet11
	elseif method == 12 then
		rt = data.iSet12
	elseif method == 13 then
		rt = data.iSet13
	end
end


print(os.clock()-beginTime)
print(collectgarbage("count"))