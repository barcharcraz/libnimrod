import xmltree
import os
import strtabs
import streams
import strutils

proc isNimrodFile(file: string): bool =
  var (dir, name, ext) = splitFile(item)
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

proc findDirectories(baseDir: string): seq[string] =
  result = @[]
  for kind, item in walkDir(baseDir):
    if kind == pcDir:
      result = result & item
      result = result & findDirectories(item)

proc createItemsList(items: openarray[string]): string =
  result = join(items, ";")
  

proc genHeader(): PXMLNode =
  result = newElement("Project")
  result.attrs = newStringTable(modeCaseSensitive)
  result.attrs["ToolsVersion"]="4.0"
  result.attrs["DefaultTargets"]="Build"
  result.attrs["xmlns"]=r"http://schemas.microsoft.com/developer/msbuild/2003"
  
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
  execNode.attrs["Command"] = r"nimrod c --passc:$(CompilerFlags) -d:$(Configuration) -o:$(OutputPath)$(AssemblyName) $(StartupObject) "
  result.add(execNode)
  
proc genNimrodProject(baseModule: string): PXMLNode =
  result = genHeader()
  var (dir, name, ext) = splitFile(baseModule)
  var files = findNimrodFiles(dir)
  var dirs = findDirectories(dir)
  echo repr(dirs)
  result.add(genDefaultPropertyGroup(name & ext))
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