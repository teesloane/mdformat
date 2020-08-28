import std/wordwrap

let inputF = open("testfile.md")
var outputF = open("output.md", fmWrite)

for line in inputF.lines:

  # have to handle for the following not being line broken:
  # - headings
  # - is html
  # - is table (would need to lookahead at lines and check for equal nums of pipes)
  # - - could also have a table formatter...
  # - is in code block
  # - is frontmatter (ala jekyll / hugo)

  # - ...?

  if line.len == 0:
    outputF.writeLine(line)
  elif line.string[0] == '#':
    outputF.writeLine(line)
  else:
    outputF.writeLine(wrapWords(line, maxLineWidth=80, splitLongWords=true))



# proc lineType ...
# determines the type of line (heading, html section, blockquote)
#
#
# -- line handlers --

# proc: table handler.
