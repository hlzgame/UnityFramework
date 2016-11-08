import util
import md5
import argparse
import sys
parser = argparse.ArgumentParser()
parser.add_argument("--input")
parser.add_argument("--output")
parser.add_argument("--version")
args = parser.parse_args()
input = args.input
input = util.specPath(input)
output = args.output
output = util.specPath(output)

version = args.version
path_version = version.replace(".","_")
output = output + path_version
util.rmdir(output)
output = util.specPath(output)
util.mkdir(output)


file_map = {}

def generateMD5(fullPath):
	m = md5.new()
	a_file = open(fullPath,'rb')
	m.update(a_file.read())
	a_file.close()
	return str(m.hexdigest())

def dealFile(fileName,fullPath):
	relativePath = fullPath.split(input,1)
	
	md5Code = generateMD5(fullPath)
	if file_map.get(relativePath[1]) != None:
		print "File name duplicate " + fullPath
	file_map[relativePath[1]] = md5Code
	

util.loopFolder(input,dealFile)

out_file = open(output+"fullList.lua","w")
out_file.write("local res_list = {\n")
out_file.write("\t\"ver\" = \""+version+"\",\n")
out_file.write("\t\"file_list\"=\n")

file_str = util.dict2LuaTable(file_map,1)
out_file.write(file_str)
out_file.write("return res_list")

out_file.close

util.dict2File(file_map,output+"fullList.pickle")