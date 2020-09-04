import sequtils, sugar
import strutils
import nre

# checks if a line is all dashes (for table heading/body separators)
let tableDividerRE = nre.re("^(-*)\1*$")

proc format*(table: seq[string]): seq[string] =
  var matrixTable = table.map(x => x.split('|'))
  var cols        = newSeq[int](matrixTable[0].len)
  var output      = newSeq[string](matrixTable[0].len) # assumes all tables are equal len.
  # here we find the largest string length in a cell for each column.
  # we loop through each row, and then each cell, filling the cols
  # with the cell length until the cols.len == row.len
  # Then, iterating through the rest of the rows, if we come across a cell
  # that is larger than what exists at the corresponding index, we replace it.
  # there is probably a cleaner way to do this.

  # Find the largest cell length for each column
  for i, row in matrixTable:
    for j, cell in row:
      let strip_cell = cell.strip()
      if strip_cell.len > cols[j]:
        cols[j] = strip_cell.len + 1

  # Now we know the minimum length a column must be for each row, we iterate
  # (again, bad), and make each cell the minimum length using the alignLeft
  # fn to pad with spaces or `-` depending on the row type.
  for row in matrixTable:
    var rowOutput = ""
    for j, cell_str in row:
      var cell = cell_str.strip()
      # check if we are operating on a "divider" line between th and td.
      if cell.contains(tableDividerRE) :
        cell = cell.alignLeft(cols[j], '-')
        if cell.len > 0: cell = "-" & cell
        rowOutput.add(cell)
      else:
        cell = cell.alignLeft(cols[j], ' ')
        rowOutput.add(cell.indent(1))
      rowOutput.add("|") # re-add table pipes (altho this adds an extra at the end.)

    rowOutput = rowOutput.strip(leading = false, chars = {'|'})
    rowOutput = rowOutput.strip(leading = false, chars = {'|'})
    rowOutput.add("|")
    output.add(rowOutput)
  return output
