"""
方便将scripts内的Lua API插入到default.lua当中
"""

import re
import sys

if len(sys.argv) != 3:
    print("param error")
    sys.exit(0)

org_lua_file_name = sys.argv[1]
to_lua_file_name = sys.argv[2]

if org_lua_file_name == to_lua_file_name:
    print("param error: same input/output filename")
    sys.exit(0)

org_file = open(org_lua_file_name, 'r')
to_file = open(to_lua_file_name, 'w')


def read_file(file_path):
    """
    读取文件内容
    :param file_path: 文件路径
    :return: lines
    """
    f = open(file_path)
    f_text = f.readlines()
    f.close()
    return f_text


for line in org_file.readlines():
    match_obj = re.match(r'.*require\(\W*[\'|\"](.*)[\'|\"]\W*\)', line)
    if match_obj is not None:
        path = match_obj.group(1)
        text_lines = read_file(path)
        to_file.writelines(text_lines)
    else:
        to_file.write(line)

org_file.close()
to_file.close()



