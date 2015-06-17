function idp3_getname, iname, maxlen
  
  blank = '                                                                   '
  ua_decompose, iname, disk, path, fname, vers
  nlen = strlen(fname)
  if nlen eq maxlen then begin
    oname = fname
  endif else begin
    if nlen lt maxlen then begin
      diff = maxlen - nlen
      blnk = strmid(blank,0,diff)
      oname = fname + blnk
    endif else oname = strmid(fname, 0, maxlen)
  endelse
  return, oname
  end
