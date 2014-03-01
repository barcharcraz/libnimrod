import xmltree
import os
import strtabs
import streams
import strutils

proc isNimrodFile(file: string): bool =
  var (dir, name, ext) = splitFile(file)
  if ext == ".nim":
    result = true
  else:
    result = false

proc findNimrodFiles(baseDir: string): seq[string] =
  result = @[]
  for item in walkDirRec(baseDir):
    var (dir, name, ext) = splitFile(item)
    if ext == ".nim":
      result.add(item)


proc findDirectoriesRec(baseDir: string): seq[string] = 
  result = @[]
  for kind, item in walkDir(baseDir):
    if kind == pcDir:
      result = result & findDirectoriesRec(item)
    if kind == pcFile:
      if splitFile(item).ext == ".nim":
        result = result & baseDir
proc findDirectories(baseDir: string): seq[string] =
  result = @[]
  for kind, item in walkDir(baseDir):
    if kind == pcDir:
      #we only want to return the subdirectories
      #with nimrod items in them
      result = result & findDirectoriesRec(item)
  

proc createItemsList(items: openarray[string]): string =
  result = join(items, ";")
  

proc genHeader(): PXMLNode =
  result = newElement("Project")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["ToolsVersion"]="4.0"
  result.attrs["DefaultTargets"]="Build"
  result.attrs["xmlns"]=r"http://schemas.microsoft.com/developer/msbuild/2003"
  
proc genImportNode(file: string): PXMLNode = 
  result = newElement("Import")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["Project"] = file
  
proc genDefaultPropertyGroup(mainfile: string): PXMLNode =
  result = newElement("PropertyGroup")
  var configuration = newElement("Configuration")
  configuration.attrs = newStringTable(modeCaseSensitive)
  configuration.attrs["Condition"] = r" '$(Configuration)' == '' "
  configuration.add(newText("Debug"))
  result.add(configuration)
  var SchemaVersion = newElement("SchemaVersion")
  SchemaVersion.add(newText("2.0"))
  result.add(SchemaVersion)
  var projectguid = newElement("ProjectGuid")
  projectguid.add(newText("6CAFC0C6-A428-4d30-A9F9-700E829FEA51"))
  result.add(projectguid)
  var outputtype = newElement("OutputType")
  outputtype.add(newText("Exe"))
  result.add(outputtype)
  var rootnamespace = newElement("RootNamespace")
  rootnamespace.add(newText("VisualNimrod"))
  result.add(rootnamespace)
  var assemblyname = newElement("AssemblyName")
  assemblyname.add(newText("VisualNimrod"))
  result.add(assemblyname)
  var startupobject = newElement("StartupObject")
  startupobject.add(newText(mainfile))
  result.add(startupobject)
  var nameelt = newElement("Name")
  var (dir, name, ext) = splitFile(mainfile)
  nameelt.add(newText(name))
  result.add(nameelt)
  
proc genConfigurationPropertyGroup(config: string, outputpath: string, flags: string): PXMLNode =
  result = newElement("PropertyGroup")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["Condition"] = r" '$(Configuration)' == '" & config & r"' "
  var debugsymbols = newElement("DebugSymbols")
  var compilerflags = newElement("CompilerFlags")
  var outpath = newElement("OutputPath")
  var unmanageddebugging = newElement("EnableUnmanagedDebugging")
  debugsymbols.add(newText("true"))
  compilerflags.add(newText(flags))
  var winoutputpath = outputpath.replace(r"/",r"\")
  outpath.add(newText(winoutputpath & r"\"))
  unmanageddebugging.add(newText("false"))
  result.add(debugsymbols)
  result.add(compilerflags)
  result.add(outpath)
  result.add(unmanageddebugging)

proc genDebugPropertyGroup(): PXMLNode = 
  result = genConfigurationPropertyGroup("Debug", "bin/Debug", "")

proc genReleasePropertyGroup(): PXMLNode = 
  result = genConfigurationPropertyGroup("Release", "bin/Release", "")

proc genItemGroup(elmType: string, paths: seq[string]): PXMLNode = 
  result = newElement("ItemGroup")
  for file in paths.items:
    var toAdd = newElement(elmType)
    toAdd.attrs = newStringTable(modeCaseSensitive)
    toAdd.attrs["Include"] = file
    result.add(toAdd)
proc genFolderItemGroup(paths: seq[string]): PXMLNode =
  result = genItemGroup("Folder", paths)
proc genContentItemGroup(paths: seq[string]): PXMLNode =
  result = genItemGroup("Content", paths)
proc genBuildTarget(): PXMLNode =
  result = newElement("Target")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["Name"] = "Build"
  var execNode = newElement("Exec")
  execNode.attrs = newStringTable(modeCaseSensitive)
  execNode.attrs["Command"] = """
  call "%VS120COMNTOOLS%VCVarsQueryRegistry.bat" No32bit 64bit
  call "%VCINSTALLDIR%vcvarsall.bat" amd64
  nimrod c --cc:vcc --passc:""$(CompilerFlags)"" -d:$(Configuration) -o:$(OutputPath)$(AssemblyName) $(StartupObject) 
  """
  result.add(execNode)
  
proc genVCCImports(): PXMLNode =
  result = newElement("Import")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["Project"] = r"$(VCTargetsPath)\Microsoft.Cpp.props"
proc genVSPropSheetImport(): PXMLNode =
  result = newElement("ImportGroup")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["Label"] = r"PropertySheets"
  var importNode = newElement("Import")
  importNode.attrs = newStringTable(modeCaseSensitive)
  importNode.attrs["Project"] = r"$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props"
  importNode.attrs["Condition"] = r"exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')"
  importNode.attrs["Label"]=r"LocalAppDataPlatform"
  result.add(importNode)
proc genVCCTargetsImport(): PXMLNode =
  result = genImportNode(r"$(VCTargetsPath)\Microsoft.Cpp.targets")
proc genVCCDefaultTargets(): PXMLNode = 
  result = genImportNode(r"$(VCTargetsPath)\Microsoft.Cpp.Default.props")

proc genNimrodProject(baseModule: string): PXMLNode =
  result = genHeader()
  var (dir, name, ext) = splitFile(baseModule)
  var files = findNimrodFiles(dir)
  var dirs = findDirectories(dir)
  echo repr(dirs)
  result.add(genDefaultPropertyGroup(baseModule))
  result.add(genVCCImports())
  result.add(genVSPropSheetImport())
  result.add(genVCCTargetsImport())
  result.add(genDebugPropertyGroup())
  result.add(genReleasePropertyGroup())
  result.add(genContentItemGroup(files))
  result.add(genFolderItemGroup(dirs))
  result.add(genBuildTarget())
  
proc outputNimrodProject(baseModule: string) =
  var (dir, name, ext) = splitFile(baseModule)
  var filename = addFileExt(name, "nimproj")
  var stream = newFileStream(filename, fmWrite)
  var xml = genNimrodProject(baseModule)
  stream.write(xmlHeader)
  stream.write($xml)
  
when isMainModule:
  outputNimrodProject(commandLineParams()[0])