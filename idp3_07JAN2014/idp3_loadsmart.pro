pro Idp3_LoadSmart, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  ; -----------------------------------------------------------------------

;?? Betty I just blocked out this stuff
  ; temporary fix to read structure from disk
;  inpath = cinfo.pickpath
 ; filename = Dialog_Pickfile(/Read, Get_Path=outpath, $
 ;    Path=inpath, Title='Please Select Image File')
 ; cinfo.pickpath = outpath
 ; ua_decompose, filename, disk, path, name, extn, version
 ; fil = name + extn
 ; restore, fil
 ; str = 'aars = ' + name
 ; stat = execute(str)

    aars=*(!sm_idp3)
 ; ------------------------------------------------------------------------
 
  nextn = 0
  loaddata = 0
  asz = size(aars)
  str = 'LoadSmart: ' + string(asz)
  idp3_updatetxt, cinfo, str
  if asz[0] eq 1 and asz[2] eq 10 then begin
    naar = asz[1]
    if naar gt 1 then begin
      str = 'naar: ' + string(naar)
      idp3_updatetxt, cinfo, str
      idp3_getext, 'Multi-dimensional structure', 8, '*', valstr, naar-1
      all = strpos(valstr, '*')
      if all ge 0 then begin
	first = 0
	last = naar-1
      endif else begin
	rng = strpos(valstr, ':')
	if rng gt 0 then begin
	  len = strlen(valstr)
	  first = fix(strmid(valstr, 0, rng)) > 0
	  last = fix(strmid(valstr, rng+1, len-rng)) > first < (naar-1)
        endif else begin
	  first = fix(valstr) > 0 < (naar - 1)
	  last = first
        endelse
      endelse
    endif else begin
      first = 0
      last = 0
    endelse
    loaddata = 1
    for kk = first, last do begin
      phdr = *(*aars[kk]).header
;Betty I'm not sure if this is correct??
      filename= *(*aars[kk]).filename
      ua_decompose, filename, disk, path, name, extn, version
      ihdr = ' '
      tempdata = *(*aars[kk]).bcd
      imsz = size(tempdata)
      if imsz[0] eq 3 then begin
	idp3_getext, '3 Dimensional Image', 8, '0', valstr, imsz[3]-1
	all = strpos(valstr, '*')
	if all ge 0 then begin
	  findx = 0
	  lindx = imsz[3]-1
        endif else begin
	  rng = strpos(valstr, ':')
	  if rng gt 0 then begin
	    len = strlen(valstr)
	    findx = fix(strmid(valstr, 0, rng)) > 0
	    lindx=fix(strmid(valstr, rng+1, len-rng)) > findx < (imsz[3]-1)
          endif else begin
	    findx = fix(valstr) > 0 < (imsz[3]-1)
	    lindx = findx
          endelse
        endelse
      endif else begin
	findx = 0
	lindx = 0
      endelse
      if loaddata eq 1 then begin
        for j = findx, lindx do begin
          newim = ptr_new({idp3im})
          if imsz[0] eq 2 then begin
	    tdata = tempdata 
            if nextn gt 0 then begin
              (*newim).extnam = ename
              if exnum ge 0 then begin
                (*newim).extver = exnum
                num = setnum(exnum,maxver, 1)
                (*newim).name = disk + path + name + '_' + num + extn 
	        (*newim).orgname = filename
              endif else begin
	        (*newim).name = filename
	        (*newim).orgname = filename
	        (*newim).extver = 0
              endelse
            endif else begin
              (*newim).extnam = ''
              (*newim).extver = 0
              (*newim).name = filename
	      (*newim).orgname = filename
            endelse
          endif else begin
	    tdata = tempdata[*,*,j]
	    imsz = size(tempdata)
	    num = setnum(j, imsz[3], 1)
	    (*newim).name = disk + path + name + '_' + num + extn
	    (*newim).extver = j
	    (*newim).extnam = ''
	    (*newim).orgname = filename
          endelse

          ; Set up stuff in the new image structure.
          idp3_imstruct, cinfo, newim, tdata, phdr, ihdr

          ; Save this new image into the image array or structures.
          c = size(*cinfo.images)
          if (c[0] eq 0 and c[1] eq 2) then begin
            tempimages = newim
            if cinfo.autoscale eq 1 then begin
              cinfo.Z1 = (*newim).z1
              cinfo.Z2 = (*newim).z2
            endif
          endif else begin
            tempimages = [*cinfo.images,newim]
            ptr_free,cinfo.images
          endelse
          cinfo.images = ptr_new(tempimages)
        endfor
      endif
    endfor
    Widget_Control, info.idp3Window, Set_UValue=cinfo
    ; Call the ShowIm routine and exit.
    ; If ShowIm is already running, kill it first.
    if (XRegistered('idp3_showim')) then begin
      geo = Widget_Info(cinfo.ShowImBase, /geometry)
      cinfo.wpos.siwp[0] = geo.xoffset - cinfo.xoffcorr
      cinfo.wpos.siwp[1] = geo.yoffset - cinfo.yoffcorr
      Widget_Control, info.idp3Window, Set_UValue=cinfo
      Widget_Control, cinfo.ShowImBase, /Destroy
    endif
    idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,SELECT:0}
    Widget_Control, cinfo.idp3Window, Get_UValue=info
    ; Update graphics display.
    idp3_display,info
  endif else begin
    test = Dialog_Message("Sorry, Invalid format "+filename)
  endelse

  if loaddata eq 0 then begin
    Widget_Control, info.idp3Window, Set_UValue=cinfo
    Widget_Control, info.idp3Window, Get_UValue=info
  endif
 Widget_Control, event.top, Set_UValue=info
end

