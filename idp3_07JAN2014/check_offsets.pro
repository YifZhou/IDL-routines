pro check_offsets, infile, outfile

  openr, ilun, infile, /get_lun

  instr = ' '
  indx = 0
  tempnames = strarr(1)
  centroidx = strarr(1)
  centroidy = strarr(1)
  wcsx = strarr(1)
  wcsy = strarr(1)

  while not eof(ilun) do begin
    readf, ilun, instr
    ttmpstr = strsplit(instr, /extract)
    if indx eq 0 then begin
      tempnames = ttmpstr[0]
      wcsx = ttmpstr[3]
      wcsy = ttmpstr[4]
      centroidx = ttmpstr[5]
      centroidy = ttmpstr[6]
    endif else begin
      tempnames = [tempnames, ttmpstr[0]]
      wcsx = [wcsx, ttmpstr[3]]
      wcsy = [wcsy, ttmpstr[4]]
      centroidx = [centroidx, ttmpstr[5]]
      centroidy = [centroidy, ttmpstr[6]]
    endelse
    indx = indx + 1
  endwhile

  close, ilun
  free_lun, ilun

  openw, olun, outfile, /get_lun
  fcx = float(centroidx)
  fcy = float(centroidy)
  fwx = float(wcsx)
  fwy = float(wcsy)
  for i = 0, indx-1 do begin
    printf, olun, tempnames[i], string(fwx[i]-fwx[0], '$(f11.2)'), $
      string(fwy[i]-fwy[0],'$(f9.2)'), string(fcx[i]-fcx[0],'$(f11.2)'), $
      string(fcy[i]-fcy[0], '$(f9.2)')
  endfor

  close, olun
  free_lun, olun

end

