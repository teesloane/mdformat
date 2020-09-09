import strutils
import nre

let isHtmlRE = nre.re("""^<\s*[a-z][^>]*>((.*?)(<\s*\/[a-z]*>))?""")

proc isHtml*(s: string): bool =
    # check if a string starts with a html tag (and/or closes with one too.)
    s.strip(leading=true).contains(isHtmlRE)
