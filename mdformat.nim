from os import nil
import std/wordwrap
import strutils
from util import nil
from table import nil
import parseopt


# This program formats markdown in the following ways:
# - breaks lines over N chars (optional)
# - align table columns by minimum char space.
# - ...?
#
# Generally, the program is more complicated than expected because we reads the files line by
# line rather than into memory. I suppose this is more effecient, but we have
# to do some fiddling to keep track of the current line and where we iterate on inputF

# Usability Things:
# TODO: Add cli tooling + ability to choose to view diff of fmt, or overwrite file.
# TODO: Add ability to read multiple files and operate on them

# let inputF = open("tests/testfile.md", fmRead)       
var inputF: File
var outputF = open("./.tmp.md", fmWrite)  # re-open file for reading.
# var outputF: File
# var overwrite = false

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

proc saveFile(): void = 
  ## convert the temp output to the input and overwrite it.
  echo "------------------------------------"
  echo os.getFileInfo(inputF)
  # os.moveFile



proc handleTable(currLine: string): void =
  ## Formats a markdown table.
  ## Reads lines until end of table, then aligns cells with whitespace.
  ## Known limitations:
  ## - cells with a `|` in them will break the formatting.
  ## - tables must start and end with pipes (`|`)
  var tableRows = @[currLine]
  # fns inside fns... I wonder if there's a more idiomatic way to do this.
  # NOTE: is there an equivalent to (let [temp-fn (fn [x] ...))]) in nim?
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
      outputF.writeLine(wrapWords(line, maxLineWidth=80, splitLongWords=true))

proc process() : void =
  var firstLine = ""        
  for line in inputF.lines:
    firstLine = line
    break
  handleBlockElement(firstLine, "frontmatter")

  # The rest of the file.
  for line in inputF.lines:
    # check if the prev line has anything in it, and process it
    if prevLine != "__empty__": # HACK: "__empty__" is not ideal. Can't nil check strings tho.
      processLine(prevLine)
      prevLine = "__empty__"
    processLine(line.string)



## -- CLI ---------------------------------------------------------------------
## 
const VERSION = "0.0.1"
const HELP = """
mdformat - markdown formatter

usage: mdformat (commands) 
  mdformat [file | directory | pattern]

options:
  -h --help                          Show this screen.
  -v --version                       Show version.
  -w --write                         Write formatting changes to files.
  -t --no-tables                     Do not process tables.

example:
  mdformat docs/**/*.md --write      

"""

proc main() : void =

# var filename: string
  var p = initOptParser("")
  var command = ""
  var writeEnabled = false
  var commandType = ""

  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      if os.fileExists(key):
        commandType = "file"
      elif os.dirExists(key):
        commandType = "directory"
      else:
        commandType = "pattern"
      command = key

    # parse options - do this first to turn on writeEnabled
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": echo HELP
      of "version", "v": echo VERSION
      of "write", "w": writeEnabled = true
    of cmdEnd: assert(false) # cannot happen

  if command == "":
    echo HELP

  echo "command type : ", commandType
  echo command & "*.md"

  case commandType
  of "file": 
    inputF = open(command)
    process()
  of "directory":
    for file in os.walkPattern(command & "/*.md"):
      # close and reopen the temp file.
      # TODO Leaving off.
      outputF.close()
      outputF = open("./.tmp.md", fmWrite)  # re-open file for reading.
      inputF = open(file) # writes to tmp file
      saveFile()
      process() # re-open file for iteration after prepping.
  # TODO of "pattern":
  else:
    echo ""



main()