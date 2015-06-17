function getibadpix, filename, info 

  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin
    getmask = 0
    str = ' '
    openr, lun, filename, /get_lun
    while not eof(lun) do begin
      readf, lun, str
      if strmid(str, 0, 1) NE ";" then begin
	tmpstrs = strsplit(str, /extract)
	if n_elements(xpos) eq 0 then begin
	  xpos = fix(tmpstrs[0])
	  ypos = fix(tmpstrs[1])
        endif else begin
	  xpos = [xpos, fix(tmpstrs[0])]
	  ypos = [ypos, fix(tmpstrs[1])]
        endelse
      endif
    endwhile
    close, lun
    free_lun, lun
    if getmask eq 1 then begin
      return, tempmask
    endif else begin
      return, -1
    endelse
  endif else begin
    stat = Widget_Message('File not found')
    return, -1
  endelse
  end

pro ibadpixload_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=loadbpinfo
  Widget_Control, loadbpinfo.maskinfo.maskWindow, Get_UValue = maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue=info

  ims = info.images
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data
  maskim = maskinfo.cur_mask
  msz = size(maskim)

  case event.id of

    loadmaskinfo.selectfile: begin
      Widget_Control, loadmaskinfo.selectfile, Get_Value = filename
      filename = strtrim(filename[0], 2)
      temp = file_search (filename, Count = fcount)
      if (strlen(filename) le 0 or fcount le 0) then begin
	stat = Widget_Message('File not found')
      endif
    end

    loadbpinfo.browseButton: begin
      inpath = info.imagepath
      infilt = info.imfilter
      filename = Dialog_Pickfile(/Read,Title='Select Mask File', $
	   Get_Path=outpath, Path=inpath, Filter=infilt)
      filename = strtrim(filename[0], 2)
      Widget_Control, loadbpinfo.selectfile, set_value=filename
    end

    loadbpinfo.loadButton: begin
     Widget_Control, loadbpinfo.selectfile, Get_Value = filename
     filename = strtrim(filename[0], 2)
     mask = getibadpix(filename, info)
     if n_elements(mask) le 1 then begin
       str = 'Load BadPix: No mask'
       idp3_updatetxt, info, str
     endif else begin
       Widget_Control, loadbpinfo.gvalField, Get_Value=temp
       goodval=round(temp)
       info.maskpix.mask_good = goodval
       tmsz = size(mask)
       if tmsz[1] ne msz[1] or tmsz[2] ne msz[2] then begin
	 tempmask = intarr(msz[1],msz[2])
	 tempmask[*,*] = goodval
	 if msz[1] lt tmsz[1] then begin
	   dx = msz[1]
	   sx = msz[1]
         endif else begin
	   dx = tmsz[1]
	   sx = tmsz[1]
         endelse
	 if msz[2] lt tmsz[2] then begin
	   dy = msz[2]
	   sy = msz[2]
         endif else begin
	   dy = tmsz[2]
	   sy = tmsz[2]
         endelse
	 tempmask(0:dx-1,0:dy-1) = mask[0:sx-1,0:sy-1]
       endif else tempmask = mask
       good = where(tempmask eq goodval, gcnt)
       bad = where(tempmask ne goodval, bcnt)
       if bcnt gt 0 then maskim[bad] = 0
       str= 'Mask: ' + filename + string(bcnt) +  ' pixels masked'
       idp3_updatetxt, info, str
       zdisplay = bmask_display(maskinfo, im, maskim)
       maskinfo.zdisplay = ptr_new(zdisplay)
       maskinfo.cur_mask = maskim
       Widget_Control, loadmaskinfo.maskinfo.maskWindow, Set_UValue=maskinfo
       if ptr_valid((*imptr).mask) then ptr_free, (*imptr).mask
       (*imptr).mask = ptr_new(maskim)
       (*info.images)[info.moveimage] = imptr
       Widget_Control, maskinfo.info.idp3Window, Set_UValue=info
       if (*imptr).maskvis eq 1 then idp3_display, info
       tempmask = 0
     endelse	 
    end

   loadbpinfo.statsButton: begin
     Widget_Control, loadbpinfo.selectfile, Get_Value = filename
     filename = strtrim(filename[0], 2)
     mask = getibadpix(filename, info)
     if n_elements(mask) le 1 then begin
       str = 'BuildMask: No mask'
       idp3_updatetxt, info, str
     endif else begin
       Widget_Control, loadbpinfo.gvalField, Get_Value=temp
       goodval=round(temp)
       info.maskpix.mask_good = goodval
       good = where(mask eq goodval, gcnt)
       bad = where(mask ne goodval, bcnt)
       str = 'Mask: ' + filename
       idp3_updatetxt, info, str
       str = string(gcnt) + ' pixels good ' + string(bcnt) + ' bad'
       idp3_updatetxt, info, str
     endelse	 
    end

   loadbpinfo.gvalField: begin
     Widget_Control, loadbpinfo.gvalField, Get_Value = temp
   end

   loadbpinfo.doneButton: begin
     Widget_Control, event.top, /Destroy
     return
   end

  endcase
end


pro idp3_ibadpixload, event

@idp3_errors

  if(XRegistered("idp3_ibadpixload")) then return
  Widget_Control, event.top, Get_UValue = maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  goodval = info.maskpix.mask_good

  title      = 'IDP3 Load/Overlay Mask'
  loadbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1])
  load2base = Widget_Base  (loadbase, /Row)
  label      = Widget_Label (load2base, Value='Filename:') 
  selectfile = Widget_Text  (load2base, Value = ' ', XSize = 50, /Edit)
  browseButton = Widget_Button(load2base, Value='Browse')
  load3base = Widget_Base  (loadbase, /Row)
  gvalField = cw_field(load3Base, value=goodval, title='Mask Good Value:', $
      uvalue='gval', xsize=4, /Return_Events, /Floating)
  statsButton = Widget_Button(load3base, Value = 'Mask Statistics')
  loadButton = Widget_Button(load3base, Value = 'Load Bad Pixels')
  doneButton = Widget_Button(load3base, Value = 'Done')

  loadmaskinfo = {gvalField     :     gvalField,    $
		  selectfile    :     selectfile,   $
		  browseButton  :     browseButton, $
		  statsButton   :     statsButton,  $
		  loadButton    :     loadButton,   $
		  doneButton    :     doneButton,   $
		  maskinfo      :     maskinfo      }

  Widget_Control, loadbase, set_uvalue = loadbpinfo
  Widget_Control, loadbase, /Realize

  XManager, "idp3_ibadpixload", loadbase, /NO_Block, Event_Handler = $
     "ibadpixload_ev"
          
end
