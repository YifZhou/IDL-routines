function idp3_findfile, name, path=path, all=all

  if n_elements(path) eq 0 then cd, current = path
  if n_elements(all) eq 0 then all = 0
;  res = file_search(path, name, /fully_qualify_path, count=fcount)
  res = file_search(name, /fully_qualify_path, count=fcount)
  if fcount gt 0 then output = res
  if fcount eq 0 or all eq 1 then begin
    pathstr = !path
    tmppath = strsplit(pathstr, ':', /extract)
    npaths = n_elements(tmppath)
    fnd = 0
    for i = 0, npaths-1 do begin
      tpath = tmppath[i]
      if fnd eq 0 or all eq 1 then begin
        res = file_search(tpath, name, /fully_qualify_path, count=fcount)
	if fcount gt 0 then begin
	  if n_elements(output) gt 0 then output=[output,res] else output=res
          if all eq 0 then fnd = 1
        endif 
      endif
    endfor
  endif
  if n_elements(output) eq 0 then begin
    print, 'File: ', name, ' not found'
    output = ''
  endif else output = output[0]
  return, output 
end
