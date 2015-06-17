function get_bincol, colname, filename=filename, extn=extn, row=row

; procedure to retrieve one or more rows of a single column in a FITS
; binary table.
; The only required parameter is the column name.  If the filename is
; not given, a dialog_pickfile widget will pop up for selecting it.
; All other parameters have default values if not given.
; Input Parameters:
;   colname = text string of column name.  It is not case-sensitive
;   filename = name of FITS binary table
;   extn     = extension of binary table to read.  Default is first.
;   row      = row to read, Default is first.
; Output:
;   data - a scalar to multi-dimensional value depending on the size
;          of the column nam.

  if n_elements(filename) eq 0 then begin
    filename = Dialog_Pickfile(/READ,/Must_Exist,title='Select File', $
	       filter='*.fit*')
  endif
  if n_elements(extn) eq 0 then extn = 1
  if n_elements(row) eq 0 then row = 0
  if strlen(filename) gt 0 then begin
    temp = findfile(filename, Count=fcount)
    if fcount gt 0 then begin
      ua_fits_open, filename, fcb
      nextend = fcb.nextend
      ua_fits_close, fcb
      print, filename, ': ', strtrim(string(nextend),2), ' extensions
      if nextend eq 0 then return, -1
      ua_fits_read, filename, im, ehdr, /no_pdu, exten_no=i
      xten = sxpar(ehdr, 'XTENSION')
      fxbopen, lun, filename, extn, ihdr
      ncols = sxpar(ihdr, 'TFIELDS')
      nrows = sxpar(ihdr, 'NAXIS2')
      rows = [1, nrows]
      found = 0
      for j = 0, ncols-1 do begin
	ttype = 'TTYPE' + strtrim(string(j+1),2)
	tcolname = strtrim(sxpar(ihdr, ttype),2)
	if strlowcase(colname) eq strlowcase(tcolname) then begin
	  tform = 'TFORM' + strtrim(string(j+1),2)
	  tsize = sxpar(ihdr, tform)
	  len = strlen(tsize)
	  siz = fix(strmid(tsize,0,len-1))
	  typdat = strmid(tsize, len-1)
	  fxbread, lun, data, j+1, rows
	  found = 1
	endif
      endfor
      fxbclose, lun
      if found eq 1 then begin
        xx = size(data)
	print, 'Returning array: ', colname, ' with ', xx[1], $
               ' elements for row ', row
	return, data[*,row]
      endif else begin
	print, 'Error in column name: ', colname
        return, -1
      endelse
    endif
  endif
end

  
