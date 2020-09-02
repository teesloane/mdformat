import std/wordwrap
from os import nil
from table import nil

# This program formats markdown in the following ways:
# - breaks lines over N chars (optional)
# - align table columns by minimum char space.
# - ...?
#
# Generally, the program is more complicated than expected because we reads the files line by
# line rather than into memory. I suppose this is more effecient, but we have
# to do some fiddling to keep track of the current line and where we iterate on inputF
#
# Features:
# TODO: code samples (make sure they don't line break)
# TODO: hr line breaks (change determineLineType)
# TODO: inline html - don't format at all.
#
# Usability Things:
# TODO: Add cli tooling + ability to choose to view diff of fmt, or overwrite file.
# TODO: Add ability to read multiple files and operate on them

let inputF = open("tests/testfile.md", fmRead)        # re-open file for iteration after prepping.
var outputF = open("tests/testfile.tmp.md", fmWrite)  # re-open file for reading.
var overwrite = false

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
  elif line.len > 3 and line[0..2] == "---":
    "frontmatter" # FIXME: should be "rule" or "hr"
  elif line.len > 3 and line[0..2] == "+++":
    "frontmatter"
  else:
    "default"

proc handleTable(currLine: string): void =
  ## Formats a markdown table.
  ## Reads lines until end of table, then aligns cells with whitespace.
  ## Known limitations:
  ## - cells with a `|` in them will break the formatting.
  ## - tables must start and end with pipes (`|`)
  var tableRows = @[currLine]
  # fns inside fns... I wonder if there's a more idiomatic way to do this.
  # FIXME: is there an equivalent to (let [temp-fn (fn [x] ...))]) ?
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

proc processLine(line : string) : void =
  let t = determineLineType(line)
  case t:
    of "empty":
      outputF.writeLine(line)
    of "heading":
      outputF.writeLine(line)
    of "table":
      handleTable(line)
    else:
      outputF.writeLine(wrapWords(line, maxLineWidth=80, splitLongWords=true))

proc handleFrontMatter(inFile: File) : void =
  ## reads the first line of a file, deterimines if there is frontmatter
  ## and then appropriately handles parsing/formatting until front matter is done.
  var is_capturing = false
  var firstLine = ""
  for line in inFile.lines:
    if firstLine.len == 0: # get the first line and store in a var
      firstLine = line
    if firstLine != "---": # if the first line isn't front matter, get outta here
      processLine(line)
      return

    let isFM = line[0..2] == "---" # check if each successive line is frontmatter.
    if isFM and is_capturing == false: # if first line is fm
      is_capturing = true
      outputF.writeLine(line)
    elif isFM and is_capturing:
      outputF.writeLine(line)
      break
    if not isFM and is_capturing:
      outputF.writeLine(line)

proc main() : void =
  handleFrontMatter(inputF)
  for line in inputF.lines:
    # check if the prev line has anything in it, and process it
    if prevLine != "__empty__": # HACK: "__empty__" is not ideal. Can't nil check strings tho.
      processLine(prevLine)
      prevLine = "__empty__"
    processLine(line.string)

  # if overwrite:
    # os.moveFile("./testfile.tmp.md", "./testfile.md")

main()
