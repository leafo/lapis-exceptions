
import P, Cs, R, S from require "lpeg"

cont = R("\128\191")
utf8_codepoint = R("\194\223") * cont +
  R("\224\239") * cont * cont +
  R("\240\244") * cont * cont * cont

acceptable_character = S("\r\n\t") + R("\032\126") + utf8_codepoint

-- remove any invalid unicode sequences so it can be placed in DB without errors
-- converts bad hex chars to <HEX>
sanitize_text = do
  escape_char = (c) -> "<#{"%X"\format string.byte c}>"
  p = Cs (acceptable_character + P(1) / escape_char)^0 * -1
  (text) -> text and p\match text

{:sanitize_text}
