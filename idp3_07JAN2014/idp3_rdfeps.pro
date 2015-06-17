function idp3_rdfeps, inpath, outpath, fepsfile, get_new

  f0 = 'inst'
  f1 = 'pipe'
  f2 = 'chan'
  if get_new eq 1 then begin
    fepsfile = Dialog_Pickfile(/Read, Get_Path=outpath, Path=inpath, $
      title='Select FEPS Data File', /Must_Exist)
    fepsfile = strtrim(fepsfile[0],2)
  endif
  if strlen(fepsfile) gt 1 then begin
    openr, lun, fepsfile, /get_lun
    titlestr = ' '
    readf, lun, titlestr
    fields = strsplit(titlestr, ' ', /extract)
    fnum = n_elements(fields)
    if fnum lt 4 then begin
      stat = Widget_Message('Insufficient number of fields in file!')
      close, lun
      free_lun, lun
      return, -1
    endif else begin
      fields = strlowcase(fields)
      if strmid(fields[0],0,4) ne f0 and strmid(fields[1],0,4) ne f1 and $
        strmid(fields[2],0,4) ne f2 then begin
        stat = Widget_Message('Invalid Header to table')
	close, lun
	free_lun, lun
        return, -1
      endif else begin
        dstr = ' '
        while not eof(lun) do begin
	  readf, lun, dstr
          strs = strsplit(dstr, ' ', /extract)
	  num = n_elements(strs)
	  if num lt 4 then begin
	    stat = Widget_Message('Insufficent data')
	    close, lun
	    free_lun, lun
	    return, -1
          endif else begin
	    ii = strlowcase(strmid(strs[0],0,1))
	    pp = strlowcase(strmid(strs[1],0,1))
	    if ii ne 'i' and ii ne 'm' then begin
	      print, strs[0], ' ', strs[1], ' ', strs[2], ' ', strs[3]
	      stat = Widget_Message('Cannot recognize instrument')
	      close, lun
	      free_lun, lun
	      return, -1
            endif else begin
	      if pp ne 's' then begin
		print, strs[0], ' ', strs[1], ' ', strs[2], ' ', strs[3]
		stat = Widget_Message('Cannot recognize pipeline')
              endif else begin
	        for i = 2, num-1 do begin
		  isdata = strverify(strs[i], '1234567890.-+ed ')
		  if isdata eq '-1' then begin
		    stat = Widget_Message('Invalid data')
		    close, lun
		    free_lun, lun
		    return, -1
                  endif
                endfor
              endelse
            endelse
          endelse
        endwhile
      endelse
    endelse
  endif
  close, lun
  free_lun, lun
  return, 0
end
