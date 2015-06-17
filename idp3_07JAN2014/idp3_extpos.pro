function idp3_extpos, str
  len = strlen(str)
  if strpos(str, '[') ge 0 and strpos(str, ']') gt 0 $
    then vals = fix(strsplit(strmid(str,1,len-2),',',/extract)) $
    else vals = [0,0]
  return, vals
end

