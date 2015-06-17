function idp3_getfeps, file, instrument, pipeline, channel, name, value

  openr, lun, file, /get_lun
  titlestr = ' '
  readf, lun, titlestr
  fields = strsplit(titlestr, ' ', /extract)
  fields = strupcase(fields)
  fnum = n_elements(fields)
  col = -1
  if fnum ge 4 then begin
    for i = 3, fnum-1 do begin
      if fields[i] eq name then col = i
    endfor
  endif
  if col lt 0 then begin
    print, 'Data not found'
    value = 0
    return, -1
  endif

  str = ' '
  while not eof(lun) do begin
    readf, lun, str
    dat = strsplit(str, ' ', /extract)
    inst = strupcase(dat[0])
    pipe = strupcase(dat[1])
    ch = fix(dat[2])
    if inst eq instrument and pipe eq pipeline and ch eq channel then begin
      dnum = n_elements(dat)
      if dnum gt col then begin
	value = float(dat[col])
      endif else value = 0
      close, lun
      free_lun, lun
      return, 0
    endif
  endwhile
  print, 'No match'
  close, lun
  free_lun, lun
  value = 0
  return, -1
end
