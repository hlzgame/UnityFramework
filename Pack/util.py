import os.path
import re
import string
import pdb
import shutil

try: 
	import cpickle
except ImportError: 
	import pickle

import sys

def specFile(p):
	p = str( p )
	p = p.replace("/","\\")
	return p

	
def specPath(p):
	p = str(p)
	p = p.replace("/","\\")
	if p[-1] != "\\":
		p = p+"\\"
	return p
	
def getFileList( p ):
	if p=="":
		return [ ]
	p = specPath(p)
	a = os.listdir( p )
	b = [ x  for x in a if os.path.isfile( p + x ) ]
	return b

def getDirList( p ):
	if p=="":
		return [ ]
	p = specPath(p)
	a = os.listdir( p )
	b = [ x  for x in a if os.path.isdir( p + x ) ]
	return b

def loopFolder(d,cb):
	d = specPath(d)
	check_path = d
	fileList = getFileList(d)
	for file in fileList:
		cb(file,d+file)
	
	dirList = getDirList(d)
	for dir in dirList:
		dir = specPath(d + dir)
		loopFolder(dir,cb)
	
def getFolder(file):
	return os.path.dirname(file)
	
def mkdir(path):
	path = specPath(path)
	os.makedirs(path)
	
def rmdir(path):
	if os.path.exists(path) == True:
		shutil.rmtree(path)
		
def cp(src,des):
	foldier = getFolder(des)
	if os.path.exists(foldier) != True:
		mkdir(foldier)
	shutil.copy(src,des)
		
def dict2File(o,fullpath):
	f = open(fullpath,'wb')
	pickle.dump(o, f)
	f.close()
	
def file2Dict(filepath):
	f = open(filepath, 'rb')
	data = pickle.load(f)
	f.close()
	return data

		
def dict2LuaTable(o,indent):
	str = ""
	if type(o) == type([]):
		str += "\t"*indent + "{\n"
		indent = indent+1
		for _l in o:
			str += "\t"*indent + dict2LuaTable(_l,indent) + ",\n"
		indent = indent - 1
		str += "\t"*indent+"}\n"
	elif type(o) == type({}):
		str += "\t"*indent + "{\n"
		indent = indent+1
		keys = o.keys() 
		keys.sort() 
		for _k in keys:
			str += "\t"*indent + "\"" + _k + "\" = " + dict2LuaTable(o[_k],indent) + ",\n"
		indent = indent - 1
		str += "\t"*indent+"}\n"
	elif type(o) == type(""):
		str = str + "\"" + o + "\","
	else:
		str = o;
	return str