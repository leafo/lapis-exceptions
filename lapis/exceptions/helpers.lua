local P, Cs, R, S
do
  local _obj_0 = require("lpeg")
  P, Cs, R, S = _obj_0.P, _obj_0.Cs, _obj_0.R, _obj_0.S
end
local cont = R("\128\191")
local utf8_codepoint = R("\194\223") * cont + R("\224\239") * cont * cont + R("\240\244") * cont * cont * cont
local acceptable_character = S("\r\n\t") + R("\032\126") + utf8_codepoint
local sanitize_text
do
  local escape_char
  escape_char = function(c)
    return "<" .. tostring(("%X"):format(string.byte(c))) .. ">"
  end
  local p = Cs((acceptable_character + P(1) / escape_char) ^ 0 * -1)
  sanitize_text = function(text)
    return text and p:match(text)
  end
end
return {
  sanitize_text = sanitize_text
}
