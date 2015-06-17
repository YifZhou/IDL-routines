function setnum, indx, limit, pad

str = '00000000000000000000000'

tmpstr = strtrim(string(indx),2)
if (pad EQ 0) then begin
  return, tmpstr
endif else begin
  tmplen = strlen(tmpstr)
  limstr = strtrim(string(limit),2)
  limlen = strlen(limstr)
  diff = limlen - tmplen
  newstr = strmid(str, 0, diff) + tmpstr
  return, newstr
endelse
END

