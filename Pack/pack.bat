::call python generate_md5_list.py --input C:\Project\Client\Resources --output K:\ --ver 1.0.0
::call python generate_md5_list.py --input K:\branch_56\Client\Resources --output K:\ --ver 1.0.1
call python generate_pack_zip.py --begin 1.0.0 --end 1.0.1 --work_path K:\ --res_path K:\branch_56\Client\Resources
