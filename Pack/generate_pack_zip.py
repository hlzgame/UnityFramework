import util
import argparse
import os
parser = argparse.ArgumentParser()
parser.add_argument("--begin")
parser.add_argument("--end")
parser.add_argument("--work_path")
parser.add_argument("--res_path")
args = parser.parse_args()

work_path = util.specPath(args.work_path)
res_path = util.specPath(args.res_path)

begin = args.begin.replace(".","_")
begin_folder = util.specPath(work_path + begin)
begin_dict = util.file2Dict(begin_folder + "fullList.pickle")

end = args.end.replace(".","_")
end_folder = util.specPath(work_path + end)
end_dict = util.file2Dict(end_folder + "fullList.pickle")

target_folder = util.specPath(work_path + begin + "-" + end)

util.rmdir(target_folder)
util.mkdir(target_folder)
keys = end_dict.keys() 
keys.sort()
for key in keys:
	if begin_dict.get(key) != None:
		if begin_dict[key] != end_dict[key]:
			util.cp(res_path+key,target_folder+key)
	else:
		util.cp(res_path+key,target_folder+key)
		
zip_name = work_path+ begin + "-" + end + ".zip"
os.system("7z a -tzip "+ zip_name + " " + target_folder+"*")


