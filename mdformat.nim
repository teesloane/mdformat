import std/wordwrap
import strutils
import algorithm
import sequtils, sugar

let inputF = open("testfile.md")
var outputF = open("output.md", fmWrite)


# Utils ================================

proc stringLenCompare(x, y: string): int =
  # echo "x len and y len:" , x.len, " | ", y.len
  if x.len < y.len: -1
  elif x.len == y.len: 0
  else: 1

proc longestStringinSeq(lst: seq[string]): int =
  result = sorted(lst, stringLenCompare, Descending)[0].len

# ====================================

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

# proc myCmp(x, y: People): int =
  # if x.name < y.name: -1
  # elif x.name == y.name: 0
  # else: 1


proc handleTable(currLine: string): void =
  ## Formats a markdown table.
  ## Reads lines until end of table, then aligns cells with whitespace.
  var table = @[currLine]
  # var matrix: seq[seq[string]]
  for line in inputF.lines:
    let t = determineLineType(line.string)
    prevLine = line
    if t == "table":
      table.add(line)
    else: # a new line comes in that is not a table
      prevLine = line # don't forget we need to process this later.
      var matrixTable = table.map(x => x.split('|'))
      echo matrixTable
      var cols = newSeq[int]()
      echo "copl lenglkajdf", cols.len

      for i, row in matrixTable:
        for j, cell in row:
          # echo cols.len, " ", j
          if cols.len <= j:
            cols.add(cell.len)
          when cell.len > cols[j]:
            cols[j] = cell.len # STUCK: FIXME: can't evaluate at compile time

        # var maxCellLength = row.longestStringinSeq()
        # echo "max cell length is ", maxCellLength
      echo cols
      break
  # this only runs if the table is the very last thing in the file.
  # echo "table is: ", table


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


# have to handle for the following not being line broken:
# - headings
# - is html
# - is table (would need to lookahead at lines and check for equal nums of pipes)
# - - could also have a table formatter...
# - is in code block
# - is frontmatter (ala jekyll / hugo)
# for line in inputF.lines:
#   let t = determineLineType(line.string)
#   prevLine = line

#   case t:
#     of "empty":
#       outputF.writeLine(line)
#     of "heading":
#       outputF.writeLine(line)
#     of "table":
#       handleTable(line)
#     else:
#       outputF.writeLine(wrapWords(line, maxLineWidth=80, splitLongWords=true))

# LEAVING OFF:
# proc processor () : void =
# check if there is an "unprocessed line, from a pervious loop"
# generally there will only be a unprocessed line when we have processed a "block" element,
# ex: we start reading a table, and it reads lines until there are no more table elements
# it only stores the elements it needs, but by the time it finds out the table element is "done" it has already read a new line.
# # if there is, send it through the line determiner and process it accordingly.
# now, loop through file lines: for line in inputFiles.lines...
  # check the line type and send it to a function.

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


proc main() : void =
  handleFrontMatter(inputF)
  for line in inputF.lines:
    echo "in main loop:", line
    # check if the prev line has anything in it, and process it
    if prevLine != "__empty__": # not ideal. Can't nil check strings.
      processLine(prevLine)
      prevLine = "__empty__"
    # otherwise, keep on keepin' on
    processLine(line.string)
   


main()

# ["foo | jo", "bar | mo ", "baz | so"] =>
