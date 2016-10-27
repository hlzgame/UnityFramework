try: 
	import xml.etree.cElementTree as ET 
except ImportError: 
	import xml.etree.ElementTree as ET 
	
import xlrd
import sys
reload(sys)
sys.setdefaultencoding( "utf-8" )

try: 
	tree = ET.parse("clientDBBase.xml")
	root = tree.getroot()
except Exception, e: 
	print "Error:cannot parse file:country.xml."
	sys.exit(1) 
  
def toStr(value,type):
	if type == 'string' or type == 'quote':
		return "\""+str(value)+"\""
	elif type == 'int32' or type == 'uint32':
		if value == '':
			return str('0')
		else:
			return str(int(float(value)))
	else:
		return str(value)

def generateStruct(root,xlsTable):
	list = []
	for field in root:
		dict = {}
		fieldName = field.get("name")
		if field.tag == "dict":
			dict['field'] = generateStruct(field,xlsTable)
			dict['type'] = "dict"
			dict['name'] = fieldName
		else:
			col = field.get("col")
			type = field.get("type")
			key = field.get("key")
			split = field.get("split")
			subtype = field.get("subtype")
			dict = {'type':type,'key':key,'col':col,'name':fieldName,'excelCol':xlsTable[col],'split':split,'subtype':subtype}
		list.append(dict)

	return list
	
def bindToExcel(xlsTable):
	dict = {}
	for ncols in range(0,xlsTable.ncols):
		title = xlsTable.cell(0,ncols).value
		dict[title] = ncols
	return dict
	
def generateSheet(root):
	for child in root:
		tableName = child.get("name")
		out_file.write(tableName + ' = {\n')
		xlsName = child.get("xls")
		sheetName = child.get("sheet")
		xlsFile = xlrd.open_workbook(inputbase+xlsName)
		xlsTable = xlsFile.sheet_by_name(sheetName)
		xmlStruct = generateStruct(child,bindToExcel(xlsTable))
		out_file.write("__meta = " + generateStructTable(xmlStruct)+ ",\n")
		out_file.write(generateDataTable(xlsTable,xmlStruct))
		out_file.write ('}\n')
		
def generatePreRow(row,xmlStruct):
	luaTable = "{"
	keyList = []
	for field in xmlStruct:
		if field.get('key') != None:
			keyList.append(toStr(row[field['excelCol']],field['type']))
		if field['type'] == "dict":
			luaTable += generatePreRow(row,field['field']) + ",";
		elif field['type'] == "array":
			strList = str(row[field['excelCol']]).split(field['split'])
			luaTable += "{"
			for string in strList:
				luaTable += toStr(string,field['subtype'])+",";
			
			if luaTable[-1] == ",":
				luaTable = luaTable[:len(luaTable)-1]
				
			luaTable += "},"
		else:
			luaTable += toStr(row[field['excelCol']],field['type'])+",";
			
	
	if luaTable[-1] == ",":
		luaTable = luaTable[:len(luaTable)-1]
	luaTable += "}"
	if len(keyList) != 0:
		keyStr = "_".join(keyList)
		luaTable = "[\"" + keyStr + "\"] = " + luaTable
	return luaTable
	
def generateDataTable(xlsTable,xmlStruct):
	luaTable = ""
	for nrows in range(1,xlsTable.nrows):
		row = xlsTable.row_values(nrows)
		if row:
			luaTable += "\t"+generatePreRow(row,xmlStruct) + ",\n"
	return luaTable
	
def generateStructTable(xmlStruct):
	luaTable = "{"
	dict = {}
	for i in range(len(xmlStruct)):
		field = xmlStruct[i]
		if field['type'] == "dict":
			dict[i+1] = field
			
		luaTable += field["name"] + " = " + str(i+1) + ","
	
		
	if len(dict) != 0:
		luaTable += "__dict = {"
		for (index,field) in dict.items():
			luaTable += "[" + str(index) + "] = " + generateStructTable(field['field']) + ","
		
		if luaTable[-1] == ",":
			luaTable = luaTable[:len(luaTable)-1]
		
		luaTable += "}"
	
	
	if luaTable[-1] == ",":
		luaTable = luaTable[:len(luaTable)-1]
	luaTable += "}"
	return luaTable
			
			

inputbase = root.attrib.get("inputbase")
inputbase += '\/'
out_dir = root.attrib.get("outputbase")
out_fileName = root.attrib.get("mergeout")
out_file = open(out_dir+'/'+out_fileName,'w')
out_file.write('module("Table")\n')
generateSheet(root)
out_file.close