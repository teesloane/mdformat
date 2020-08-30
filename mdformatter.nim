import std/wordwrap
import strutils

let inputF = open("testfile.md")
var outputF = open("output.md", fmWrite)

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


proc handleTable(currentLine: string): void =
  ## Formats a markdown table.
  ## Reads lines until end of table, then aligns cells with whitespace.
  # var buffer: seq[string]
  var table: @[currentLine]
  var matrix: seq[seq[string]]
  # buffer = @["foo"]
  for line in inputF.lines:
  # if line.len > 0 and line[0..1] == "|":
    let x = line.split({'|'})
    echo "X ISSSSSS", x


proc handleFrontMatter(inFile: File) : void =
  ## reads the first line of a file, deterimines if there is frontmatter
  ## and then appropriately handles parsing/formatting until front matter is done.
  var is_capturing = false
  for line in inFile.lines:
    if line.len < 3:
      outputF.writeLine(line)
      return

    let isFM = line[0..2] == "---"
    if isFM and is_capturing == false: # if first line is fm
      is_capturing = true
      outputF.writeLine(line)
    elif isFM and is_capturing:
      outputF.writeLine(line)
      break
    if not isFM and is_capturing:
      outputF.writeLine(line)



handleFrontMatter(inputF)


# have to handle for the following not being line broken:
# - headings
# - is html
# - is table (would need to lookahead at lines and check for equal nums of pipes)
# - - could also have a table formatter...
# - is in code block
# - is frontmatter (ala jekyll / hugo)
for line in inputF.lines:
  let t = determineLineType(line.string)

  case t:
    of "empty":
      outputF.writeLine(line)
    of "heading":
      outputF.writeLine(line)
    of "table":
      handleTable(line)
    else:
      outputF.writeLine(wrapWords(line, maxLineWidth=80, splitLongWords=true))

# LEAVING OFF:
# proc processor () : void =
# check if there is an "unprocessed line, from a pervious loop"
# generally there will only be a unprocessed line when we have processed a "block" element,
# ex: we start reading a table, and it reads lines until there are no more table elements
# it only stores the elements it needs, but by the time it finds out the table element is "done" it has already read a new line.
# # if there is, send it through the line determiner and process it accordingly.
# now, loop through file lines: for line in inputFiles.lines...
  # check the line type and send it to a function.
