function idp3_extstr, str
  if strpos(str, "'") ge 0 then remchar, str, "'"
  return, str
end

