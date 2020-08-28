import std/wordwrap

let inputF = open("testfile.md")
var outputF = open("output.md", fmWrite)

proc determineLineType(line: string): string =
  if line.len == 0:
    "empty"
  elif line[0] == '#':
    "heading"
  elif line.len > 3 and line[0..2] == "---":
    "frontmatter" # FIXME: should be "rule" or "hr"
  elif line.len > 3 and line[0..2] == "+++":
    "frontmatter"
  else:
    "default"


proc handleFrontMatter(inFile: File) : void =
  ## reads the first line of a file, deterimines if there is frontmatter
  ## and then appropriately handles parsing/formatting until front matter is done.
  var is_capturing = false
  for line in inFile.lines:
    if line.len < 3: return

    let isFM = line[0..2] == "---"
    if isFM and is_capturing == false: # if first line is fm
      is_capturing = true
      outputF.writeLine(line)
      # count up?
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


handleFrontMatter(inputF) # readLines and handle
for line in inputF.lines:
  let t = determineLineType(line.string)

  case t:
    of "empty":
      outputF.writeLine(line)
    of "heading":
      outputF.writeLine(line)
    else:
      outputF.writeLine(wrapWords(line, maxLineWidth=80, splitLongWords=true))
