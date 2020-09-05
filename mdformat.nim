from os import nil
import std/wordwrap
import strutils
import parseUtils
import parseopt
from util import nil
from table import nil


# This program formats markdown in the following ways:
# - breaks lines over N chars (optional)
# - align table columns by minimum char space.
#
# io is a bit messy as we read files line by line rather than into memory.
# effecient, but we have to keep track of the current line and where we iterate on inputF

# FIXME: bug - formatting an already formatted tables adds empty spaces to it.

var inputFPath: string
var outputFPath: string = "./.tmp.md"
var inputF: File
var outputF = open(outputFPath, fmWrite)  # re-open file for reading.

var cliArgs = (
  tables: true,
  lineBreak: 80,
  noLineBreak: false,
  noRecursion: false,
  write: false
)

# HACK: due to how reading a file line by line works, we need to store the "last
# line" of an iteration at times.
# ex: when processing a table we loop through readLine input until the next line
# is not a line of type "table". this new line, however, needs to be processed,
# and so we store it.
var prevLine: string = "__empty__" # HACK: string's can't be nil. Need a better way of checking that the previous line isn't being used...

proc determineLineType(line: string): string =
  if line.len == 0:
    "empty"
  elif line[0] == '#':
    "heading"
  elif line[0] == '|':
    "table"
  elif line.len > 2 and line[0..2] == "---":
    "frontmatter" 
  elif line.len > 2 and line[0..2] == "+++": 
    "frontmatter" 
  elif line.len > 2 and line.strip(true)[0..2] == "```":
    "codeblock" 
  elif line.len > 0 and util.isHtml(line):
    "html"
  else:
    "default"


proc handleTable(currLine: string): void =
  ## Formats a markdown table.
  ## Reads lines until end of table, then aligns cells with whitespace.
  ## Known limitations:
  ## - cells with a `|` in them will break the formatting.
  ## - tables must start and end with pipes (`|`)
  var tableRows = @[currLine]

  proc handleWrite(rows: seq[string]): void =
    var res = table.format(rows)
    for l in res:
      if l.len > 0:
        outputF.writeLine(l)

  # Loop through lines and collect all the table related ones.
  for line in inputF.lines:
    let t = determineLineType(line.string)
    prevLine = line
    if t == "table":
      tableRows.add(line)
    else: # a new line comes in that is not a table
      prevLine = line # to be processed in main loop as the next line.
      handleWrite(tableRows)
      break
    if endOfFile(inputF):
      handleWrite(tableRows)

proc handleBlockElement(currentLine: string, blockType: string) : void =
  # for handling start/finish blocks, like front-matter or codeblocks. (ie. anything with delimiters.)
  var buffer = @[currentLine]
  for line in inputF.lines:
    let t = determineLineType(line)
    if t != blockType:
      buffer.add(line)
    else:
      buffer.add(line)
      for line in buffer:
        outputF.writeLine(line)
      break
    if endOfFile(inputF):
      buffer.add(line)
      for line in buffer:
        outputF.writeLine(line)

proc processLine(line : string) : void =
  let t = determineLineType(line)
  case t:
    of "empty":
      outputF.writeLine(line)
    of "heading":
      outputF.writeLine(line)
    of "table":
      handleTable(line)
    of "codeblock":
      handleBlockElement(line, "codeblock")
    of "html":
      outputF.writeLine(line)
    else:
      if cliArgs.noLineBreak:
        outputF.writeLine(line)
      else:
        outputF.writeLine(wrapWords(line, maxLineWidth=cliArgs.lineBreak, splitLongWords=true))


proc process() : void =
  # handle front matter
  var firstLine = ""        
  for line in inputF.lines:
    firstLine = line
    break
  if firstLine != "---": # if the first line isn't front matter, get outta here
    processLine(firstLine)
  else:
    handleBlockElement(firstLine, "frontmatter")

  # The rest of the file.
  for line in inputF.lines:
    # check if the prev line has anything in it, and process it
    if prevLine != "__empty__": # HACK: "__empty__" is not ideal. Can't nil check strings tho.
      processLine(prevLine)
      prevLine = "__empty__"
    processLine(line.string)


## -- Writing Fns

proc writeFile(filename: string): void =
  if cliArgs.write:
    outputF.close()
    outputF = open(outputFPath, fmWrite) 
    inputFPath = filename
    inputF = open(filename)
    process()
    os.moveFile(outputFPath, inputFPath)


## -- CLI ---------------------------------------------------------------------

const VERSION = "0.0.1"
const HELP = """

mdformat - markdown formatter

Usage: mdformat [file | directory]

Options:                   Default:    Intent:
  -w --write               false       Write formatting changes to files.
  -t --no-tables           false       Do not process tables.
  -n --line-break          n=80        Break lines at `n` char line length.
  -d --no-line-break       false       Disable line breaking entirely.
  -r --no-recursion        false       Do not format directories recursively. 
  -h --help                            Show this screen.
  -v --version                         Show version.

Example:
  mdformat docs/posts --write -n=120
"""

proc main() : void =

# Parse cli arguments...
  var p = initOptParser("")
  var command = ""
  var commandType = ""

  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      if os.fileExists(key):
        commandType = "file"
      elif os.dirExists(key):
        commandType = "directory"
      command = key

    # parse options - do this first to turn on writeEnabled
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": echo HELP
      of "version", "v": echo VERSION
      of "no-tables", "t": cliArgs.tables = false
      of "write", "w": cliArgs.write = true
      of "no-line-break", "d": cliArgs.noLineBreak = true
      of "no-recursion", "r": cliArgs.noRecursion = true
      of "line-break", "n": 
        try:
          var i = parseInt(val)
          cliArgs.lineBreak = i
        except ValueError as e:
          quit("Failed to parse line-break value. Error message: " & e.msg, 1)
          

    of cmdEnd: assert(false) # cannot happen

  if command == "":
    echo HELP

  case commandType
  of "file": 
    writeFile(command)
  of "directory":
    if cliArgs.noRecursion:
      for file in os.walkPattern(command & "/*.md"):
        writeFile(file)
    else:
      for file in os.walkDirRec(command):
        var (_, _, ext) = os.splitFile(file)
        if ext == ".md":
          writeFile(file)
  else:
    discard ""

## -- ##

main()