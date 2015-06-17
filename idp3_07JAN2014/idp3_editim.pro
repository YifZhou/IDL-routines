pro edittable_done, event
  Widget_Control, event.top, Get_UValue = etinfo
  Widget_Control, etinfo.editinfo.editWindow, Get_UValue = editinfo
  Widget_Control, editinfo.info.idp3Window, Get_UValue = info
  Widget_Control, etinfo.wTable, Get_Value = editarr
  if ptr_valid(info.edit.eregion) then ptr_free, info.edit.eregion
  info.edit.eregion = ptr_new(editarr)
  Widget_Control, editinfo.info.idp3Window, Set_UValue = info
  Widget_Control, etinfo.editinfo.editWindow, Set_UValue = editinfo
  Widget_Control, event.top, Set_UValue = etinfo
  Widget_Control, event.top, /Destroy
end

pro edittable_setval, event
  Widget_Control, event.top, Get_UValue = etinfo
  Widget_Control, etinfo.editinfo.editWindow, Get_UValue = editinfo
  Widget_Control, editinfo.info.idp3Window, Get_UValue = info
    Widget_Control, etinfo.setvalField, Get_Value = temp
    setval = float(strtrim(temp[0],2))
    if XRegistered('idp3_edittable') then begin
      xsz = info.edit.bx1 - info.edit.bx0 + 1
      ysz = info.edit.by1 - info.edit.by0 + 1
      earr = fltarr(xsz, ysz)
      earr[*,*] = setval
      Widget_Control, info.etable, Set_Value=earr
    endif
end

pro edittable_update, event
  Widget_Control, event.top, Get_UValue = etinfo
  Widget_Control, etinfo.editinfo.editWindow, Get_UValue = editinfo
  Widget_Control, editinfo.info.idp3Window, Get_UValue = info
    ims = info.images
    imptr = (*ims)[info.moveimage]
    im = *(*imptr).data
    imsz = size(im)
    z1 = info.edit.z1
    z2 = info.edit.z2
    if ptr_valid((*imptr).xedit) then begin
      xedit = *(*imptr).xedit
      yedit = *(*imptr).yedit
      zedit = *(*imptr).zedit
      num = n_elements(xedit)
    endif else num = 0
    if XRegistered('idp3_edittable') then begin
      Widget_Control, info.etable, Get_Value=edits
      esz = size(edits)
      if esz[0] eq 2 then edits = reverse(edits, 2)
      x0 = info.edit.bx0
      x1 = info.edit.bx1
      y0 = info.edit.by0
      y1 = info.edit.by1
      eindx = where(edits ne im[x0:x1,y0:y1], count)
      if count gt 0 then begin
        editx = intarr(count)
        edity = intarr(count)
        editz = fltarr(count)
        esz = size(edits)
        for i = 0, count-1 do begin
          editx[i] = eindx[i] MOD esz[1]
	  edity[i] = eindx[i] / esz[1]
          editz[i] = edits[editx[i],edity[i]]
        endfor
        if num gt 0 then begin
  	  xe = intarr(num + count)
	  ye = intarr(num + count)
	  ze = fltarr(num + count)
	  xe[0:num-1] = xedit
	  xe[num:num+count-1] = editx + x0
	  ye[0:num-1] = yedit
	  ye[num:num+count-1] = edity + y0
	  ze[0:num-1] = zedit
	  ze[num:num+count-1] = editz
        endif else begin
	  xe = editx + x0
	  ye = edity + y0
	  ze = editz
        endelse
      endif else begin
	if num gt 0 then begin
	  xe = xedit
	  ye = yedit
	  ze = zedit
        endif
      endelse
    endif else begin
      count = 0
      if num gt 0 then begin
        xe = xedit
        ye = yedit
        ze = zedit
      endif
    endelse
    zm = etinfo.zm
    bits = etinfo.bits
    if bits eq 0 then edit_color = 200 else edit_color = 2
    drawid = etinfo.drawid
    if ptr_valid((*imptr).xedit) then ptr_free, (*imptr).xedit
    if ptr_valid((*imptr).yedit) then ptr_free, (*imptr).yedit
    if ptr_valid((*imptr).zedit) then ptr_free, (*imptr).zedit
    if num+count gt 0 then begin
      (*(*info.images)[info.moveimage]).xedit = ptr_new(xe)
      (*(*info.images)[info.moveimage]).yedit = ptr_new(ye)
      (*(*info.images)[info.moveimage]).zedit = ptr_new(ze)
      tempim = im
      for i = 0, n_elements(xe)-1 do begin
        tempim[xe[i], ye[i]] = ze[i]
      endfor
      if zm eq 1 then zdat = tempim else zdat = congrid(tempim, imsz[1]*zm, $
                     imsz[2]*zm)
      bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits
      wset, etinfo.drawid
      erase
      tv, bdat
      if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
      if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
      editinfo.zim = ptr_new(zdat)
      editinfo.bim = ptr_new(bdat)
      idp3_display, info
    endif else print, 'Nothing to update'
    ims = 0
    imptr = 0
    im = 0
    zdat = 0
    bdat = 0
    Widget_Control, editinfo.info.idp3Window, Set_UValue = info
    Widget_Control, etinfo.editinfo.editWindow, Set_UValue = editinfo
    Widget_Control, event.top, Set_UValue = etinfo
    Widget_Control, event.top, /Destroy
end

pro edit_do, event
  Widget_Control, event.top, Get_UValue=etinfo
  if event.type eq 4 then begin
    ; draw box around point/points selected
    if event.sel_left ge 0 and event.sel_bottom ge 0 then begin
      zm = etinfo.zm
      x0 = (event.sel_left + etinfo.xorg) * zm
      x1 = (event.sel_right + etinfo.xorg + 1) * zm
      y0 = (etinfo.ytop - event.sel_bottom)  * zm
      y1 = (etinfo.ytop - event.sel_top + 1)  * zm
      if etinfo.bits eq 0 then begin
	ac = 200 
	ec = 200
      endif else begin
	ac = 3
	ec = 2
      endelse
      wset, etinfo.drawid
      tv, etinfo.bdat
      plots, etinfo.xorg*zm, etinfo.yorg*zm, color=ec, /device
      plots, etinfo.xorg*zm,(etinfo.ytop+1)*zm,color=ec,/device,/continue
      plots, (etinfo.xend+1)*zm, (etinfo.ytop+1)*zm, color=ec,/device,/continue
      plots, (etinfo.xend+1)*zm, etinfo.yorg*zm, color=ec, /device, /continue
      plots, etinfo.xorg*zm, etinfo.yorg*zm, color=ec, /device, /continue
      plots, x0, y0, color=ac, /device
      plots, x0, y1, color=ac, /device, /continue
      plots, x1, y1, color=ac, /device, /continue
      plots, x1, y0, color=ac, /device, /continue
      plots, x0, y0, color=ac, /device, /continue
    endif
  endif
end

pro editim_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=editinfo
  Widget_Control, editinfo.info.idp3Window, Get_UValue = info

  ims = info.images
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data
  imsz = size(im)
  if ptr_valid((*imptr).xedit) then begin
    xedit = *(*imptr).xedit
    yedit = *(*imptr).yedit
    zedit = *(*imptr).zedit
    num = n_elements(xedit)
    if num gt 0 then begin
      for i = 0, num-1 do begin
	im[xedit[i], yedit[i]] = zedit[i]
      endfor
    endif
  endif
  bits = info.color_bits
  if bits eq 0 then edit_color=200 else edit_color=2
  zm = info.edit.zoomfact
  zdat = *editinfo.zim
  bdat = *editinfo.bim
  z1 = info.edit.z1
  z2 = info.edit.z2

  case event.id of

  editinfo.doneButton: begin
     info.edit.bx0 = -1
     info.edit.bx1 = -1
     info.edit.by0 = -1
     info.edit.by1 = -1
     Widget_Control, editinfo.info.idp3Window, Set_UValue = info
     Widget_Control, event.top, Set_UValue = editinfo
     Widget_Control, event.top, /Destroy
     return
  end

  editinfo.helpbutton: begin
    tmp = idp3_findfile('idp3_editimage.hlp')
    xdisplayfile, tmp
  end

  editinfo.z1button: begin
    info.edit.zoomfact = 1
    if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    bdat = bytscl(im, top=info.d_colors-bits-1, min=z1, max=z2) + bits
    wset, info.edit.drawid
    erase
    tv, bdat
    editinfo.zim = ptr_new(im)
    editinfo.bim = ptr_new(bdat)
    bdat = 0
    if info.edit.bx0 gt 0 then begin
      zm = info.edit.zoomfact
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (info.edit.bx1 + 1) * zm
      ty1 = (info.edit.by1 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
    endif
  end

  editinfo.z2button: begin
    info.edit.zoomfact = 2
    if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    zdat = congrid(im, imsz[1]*2, imsz[2]*2)
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits
    wset, info.edit.drawid
    erase
    tv, bdat
    editinfo.zim = ptr_new(zdat)
    editinfo.bim = ptr_new(bdat)
    zdat = 0
    bdat = 0
    if info.edit.bx0 gt 0 then begin
      zm = info.edit.zoomfact
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (info.edit.bx1 + 1) * zm
      ty1 = (info.edit.by1 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
    endif
  end

  editinfo.z4button: begin
    info.edit.zoomfact = 4
    if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    zdat = congrid(im, imsz[1]*4, imsz[2]*4)
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits
    wset, info.edit.drawid
    erase
    tv, bdat
    editinfo.zim = ptr_new(zdat)
    editinfo.bim = ptr_new(bdat)
    zdat = 0
    bdat = 0
    if info.edit.bx0 gt 0 then begin
      zm = info.edit.zoomfact
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (info.edit.bx1 + 1) * zm
      ty1 = (info.edit.by1 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
    endif
  end

  editinfo.z8button: begin
    info.edit.zoomfact = 8
    if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    zdat = congrid(im, imsz[1]*8, imsz[2]*8)
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits 
    wset, info.edit.drawid
    erase
    tv, bdat
    editinfo.zim = ptr_new(zdat)
    editinfo.bim = ptr_new(bdat)
    zdat = 0
    bdat = 0
    if info.edit.bx0 gt 0 then begin
      zm = info.edit.zoomfact
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (info.edit.bx1 + 1) * zm
      ty1 = (info.edit.by1 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
    endif
  end

  editinfo.z1field: begin
    Widget_Control, editinfo.z1field, Get_Value=z1
    Widget_Control, editinfo.z2field, Get_Value=z2
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1,max=z2) + bits
    wset, info.edit.drawid
    erase
    tv, bdat
    editinfo.bim = ptr_new(bdat)
    bdat = 0
    info.edit.z1 = z1
    info.edit.z2 = z2
    if info.edit.bx0 gt 0 then begin
      zm = info.edit.zoomfact
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (info.edit.bx1 + 1) * zm
      ty1 = (info.edit.by1 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
    endif
    end

  editinfo.z2field: begin
    Widget_Control, editinfo.z1field, Get_Value=z1
    Widget_Control, editinfo.z2field, Get_Value=z2
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits 
    wset, info.edit.drawid
    erase
    tv, bdat
    editinfo.bim = ptr_new(bdat)
    bdat = 0
    info.edit.z1 = z1
    info.edit.z2 = z2
    if info.edit.bx0 gt 0 then begin
      zm = info.edit.zoomfact
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (info.edit.bx1 + 1) * zm
      ty1 = (info.edit.by1 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
    endif
    end

  editinfo.undolast: begin
  if ptr_valid((*imptr).xedit) then begin
    im = *(*imptr).data
    num = n_elements(xedit)
    if num eq 1 then begin
      ptr_free, (*imptr).xedit
      ptr_free, (*imptr).yedit
      ptr_free, (*imptr).zedit
    endif else begin
      xedit = *(*imptr).xedit
      yedit = *(*imptr).yedit
      zedit = *(*imptr).zedit
      xedit = xedit[0:num-2]
      yedit = yedit[0:num-2]
      zedit = zedit[0:num-2]
      (*imptr).xedit = ptr_new(xedit)
      (*imptr).yedit = ptr_new(yedit)
      (*imptr).zedit = ptr_new(zedit)
    endelse
    if num gt 1 then begin
      xe = xedit
      ye = yedit
      ze = zedit
      for i = 0, n_elements(xe)-1 do begin
        im[xe[i], ye[i]] = ze[i]
      endfor
      xe = 0
      ye = 0
      ze = 0
    endif
    if zm eq 1 then zdat = im else zdat = congrid(im, imsz[1]*zm, $
                   imsz[2]*zm)
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits
    wset, info.edit.drawid
    erase
    tv, bdat
    if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    editinfo.zim = ptr_new(zdat)
    editinfo.bim = ptr_new(bdat)
    idp3_display, info
    bdat = 0
    zdat = 0
  endif else begin
    str = 'UndoEdits: Nothing to undo!'
    idp3_updatetxt, info, str
  endelse
  end

  editinfo.undoall: begin
  if ptr_valid((*imptr).xedit) then begin
    im = *(*imptr).data
    ptr_free, (*imptr).xedit
    ptr_free, (*imptr).yedit
    ptr_free, (*imptr).zedit
    if zm eq 1 then zdat = im else zdat = congrid(im, imsz[1]*zm, $
                   imsz[2]*zm)
    bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits
    wset, info.edit.drawid
    erase
    tv, bdat
    if ptr_valid(editinfo.zim) then ptr_free, editinfo.zim
    if ptr_valid(editinfo.bim) then ptr_free, editinfo.bim
    editinfo.zim = ptr_new(zdat)
    editinfo.bim = ptr_new(bdat)
    idp3_display, info
    bdat = 0
    zdat = 0
  endif else begin
    str = 'UndoEdits: Nothing to undo!'
    idp3_updatetxt, info, str
  endelse
  end

  editinfo.editdraw: begin
    x = fix(event.x/zm) > 0 
    y = fix(event.y/zm) > 0 
    if x lt imsz[1] and y lt imsz[2] then z = im[x,y] else z = 0.0
    str = 'X: ' + string(x, '$(i4)') + '  Y: ' + string(y, '$(i4)') + $
	  '  Value: ' + string(z)
    Widget_Control, editinfo.lab4, Set_Value=str
    if x ge imsz[1] or y ge imsz[2] then begin
      ims = 0
      imptr = 0
      im = 0
      zdat = 0
      bdat = 0
      return
    endif
    if event.press eq 1 then begin
      if XRegistered('edit_table') then begin
        wset, info.edit.drawid
	tv, bdat
      endif
      info.edit.bx0 = x 
      info.edit.by0 = y
      editinfo.pressed = 1
    endif
    if editinfo.pressed eq 1 then begin
      if info.edit.bx0 ge 0 then begin
        wset, info.edit.drawid
        tv, bdat 
      endif
      tx0 = info.edit.bx0 * zm
      ty0 = info.edit.by0 * zm
      tx1 = (x + 1) * zm
      ty1 = (y + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
      info.edit.bx1 = x
      info.edit.by1 = y
    endif
    if event.release eq 1 then begin
      editinfo.pressed = 0
      wset, info.edit.drawid
      tv, bdat 
      if x lt info.edit.bx0 then begin
	x1 = x
	x2 = info.edit.bx0
      endif else begin
	x1 = info.edit.bx0
	x2 = x
      endelse
      if y lt info.edit.by0 then begin
	y1 = y
	y2 = info.edit.by0
      endif else begin
	y1 = info.edit.by0
	y2 = y
      endelse
      tx0 = x1 * zm
      ty0 = y1 * zm
      tx1 = (x2 + 1) * zm
      ty1 = (y2 + 1) * zm
      plots, tx0, ty0, color=edit_color, /device
      plots, tx0, ty1, color=edit_color, /device, /continue
      plots, tx1, ty1, color=edit_color, /device, /continue
      plots, tx1, ty0, color=edit_color, /device, /continue
      plots, tx0, ty0, color=edit_color, /device, /continue
      editarr = im[x1:x2,y1:y2]
      info.edit.bx0 = x1
      info.edit.bx1 = x2
      info.edit.by0 = y1
      info.edit.by1 = y2
      esz = size(editarr)
      if esz[0] eq 2 then editarr = reverse(editarr,2)
      xstrings = strarr(esz[1])
      ystrings = strarr(esz[2])
      for i = 0, esz[1]-1 do begin
	xstrings[i] = string(i, '$(i3)') + '/' + string(i+x1, '$(i4)')
      endfor
      for i = esz[2]-1, 0, -1 do begin
	ystrings[i] = string(i, '$(i3)') + '/' + string(y2-i, '$(i4)')
      endfor
      if XRegistered('idp3_edittable') then begin
	Widget_Control, info.etBase, /Destroy
      endif
      etbase = Widget_Base(group_leader=event.top, /column, $
		 Title = 'IDP3 Edit Table Widget')
      labbase = Widget_Base(etbase, /row)
      str = 'File: ' + strtrim(string(editinfo.mov),2) + '  ' + $
         editinfo.name
      labl = Widget_Label(labbase, Value=str)
      lab2 = Widget_Label(labbase, Value='Set Values to:')
      setvalField = Widget_Text(labbase, Value='0.', XSize=8, /Edit, $
	 Event_Pro='edittable_setval')
      updatebutton = Widget_Button(labbase, value='Update', $
	 Event_Pro = 'edittable_update')
      donebutton = Widget_Button(labbase, value='Cancel', $
	 Event_Pro = 'edittable_done')
      if editinfo.flipy eq 1 then begin
        str = '    Data flipped in Y in non-edit Displays'
	labf = Widget_Label(etbase, Value = str)
      endif
      wTable = Widget_Table(etbase, xsize=esz[1], ysize=esz[2], $
		 /all_events, /editable, value=editarr, row_labels=ystrings, $
		 column_labels=xstrings, column_widths = 0.90, units=1, $
		 alignment=1, Event_Pro='edit_do')
      Widget_Control, etbase, /Realize
      drawid = info.edit.drawid
      bits = info.color_bits
      zm = info.edit.zoomfact
      xorg = info.edit.bx0
      yorg = info.edit.by0
      xend = info.edit.bx1
      ytop = info.edit.by1
      etinfo = { wTable      :   wTable,    $
		 drawid      :   drawid,    $
		 bits        :   bits,      $
		 setvalField : setvalField, $
		 zm          :   zm,        $
		 bdat        :   bdat,      $
		 xorg        :   xorg,      $
		 yorg        :   yorg,      $
		 xend        :   xend,      $
		 ytop        :   ytop,      $
                 editinfo    :   editinfo   }
      info.etBase = etbase
      info.etable = wTable
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, etbase, Set_UValue = etinfo
      XManager, 'idp3_edittable', etbase, /No_Block
    endif
  end

  endcase

  ims = 0
  imptr = 0
  im = 0
  zdat = 0
  bdat = 0
  Widget_Control, editinfo.info.idp3Window, Set_UValue=info
  Widget_Control, event.top, Set_UValue=editinfo

end  

pro idp3_editim, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  ims = info.images

  ; If there are no images, return
  if n_elements(*ims) lt 1 then return

  ; get reference image if on
  imptr = (*ims)[info.moveimage]
  if (*imptr).vis ne 1 then begin
    stat = Widget_Message('Cannot edit, Reference Image not ON')
    return
  endif
  im = *(*imptr).data
  bits = info.color_bits
  if bits eq 0 then edit_color=200 else edit_color=2
  maxim = 2048
  scrollim = 512
  
  if XRegistered('idp3_edit') then return
  zdat = im
  z1 = info.z1
  z2 = info.z2
  bdat = bytscl(zdat, top=info.d_colors-bits-1, min=z1, max=z2) + bits
  info.edit.eregion = ptr_new(zdat)
  info.edit.zoomfact = 1
  info.edit.bx0 = -1
  info.edit.bx1 = -1
  info.edit.by0 = -1
  info.edit.by1 = -1
  if info.edit.z1 le -999. then info.edit.z1 = z1
  if info.edit.z2 le -999. then info.edit.z2 = z2
  pressed = 0
  name = (*imptr).name
  if info.sip eq 0 then begin
    ua_decompose, name, disk, path, fname, extn, version
    name = fname + extn
  endif
  mov = info.moveimage
  flipy = (*imptr).flipy
  if ptr_valid(zim) then ptr_free, zim
  if ptr_valid(bim) then ptr_free, bim
  zim = ptr_new(zdat)
  bim = ptr_new(bdat)
  bdat = 0
  zdat = 0

  editWindow = Widget_Base(Title='IDP3 Image Edit Window', /Column, $
      Group_Leader = event.top, $
      XOffset = info.wpos.rpwp[0], $
      YOffset = info.wpos.rpwp[1])

  buttonbase = Widget_Base(editWindow, /Row)
  lab1 = Widget_Label(buttonbase, Value='Zoom:')
  z1Button = Widget_Button(buttonbase, Value = ' 1 ', /align_center)
  z2Button = Widget_Button(buttonbase, Value = ' 2 ', /align_center)
  z4Button = Widget_Button(buttonbase, Value = ' 4 ', /align_center)
  z8Button = Widget_Button(buttonbase, Value = ' 8 ', /align_center)
  spc = Widget_Label(buttonbase, Value = '     ')
  undolast = Widget_Button(buttonbase, Value = 'Undo Last Edit', $
   /align_center)
  undoall = Widget_Button(buttonbase, Value = 'Undo All Edits', $
   /align_center)
  helpButton = Widget_Button(buttonbase, Value = 'Help', /align_center)
  doneButton = Widget_Button(buttonbase, Value = 'Done', /align_center)
  zfieldbase = Widget_Base(editWindow, /Row)
  z1field = cw_field(zfieldbase, Value=info.z1, title='Z1:', $
             UValue='z1f', xsize=8, /Return_Events, /Float)
  z2field = cw_field(zfieldbase, Value=info.z2, title='Z2:', $
	    UValue='z2f', xsize=8, /Return_Events, /Float)
  str = 'File: ' + strtrim(string(mov),2) + '  ' + name
  lab2 = Widget_Label(editWindow, Value = str)
  if flipy eq 1 then begin
    str = '    Data flipped in Y in non-edit Displays'
    lab3 = Widget_Label(editWindow, Value = str)
  endif

  editDraw = Widget_Draw(editWindow, XSize = maxim, YSize = maxim, $
	      x_scroll_size = scrollim, y_scroll_size = scrollim, $
	      /scroll, /Motion_Events, /Button_Events,retain=info.retn)

  lab4 = Widget_Label(editWindow, Value = $
     '                                                    ')

  Widget_Control, editWindow, /Realize

  Widget_Control, editDraw, Get_Value = editid

  editinfo = { z1Button   :   z1Button,   $
	       z2Button   :   z2Button,   $
               z4Button   :   z4Button,   $
	       z8Button   :   z8Button,   $
	       undolast   :   undolast,   $
	       undoall    :   undoall,    $
	       z1field    :   z1field,    $
	       z2field    :   z2field,    $
	       helpButton :   helpButton, $
	       doneButton :   doneButton, $
	       editDraw   :   editDraw,   $
	       lab4       :   lab4,       $
	       zim        :   zim,        $
	       bim        :   bim,        $
	       name       :   name,       $
	       mov        :   mov,        $
	       flipy      :   flipy,      $
	       pressed    :   pressed,    $
               editWindow :   editWindow, $
	       info       :   info        }

  info.editBase = editWindow
  info.editlabel = lab2
  info.edit.drawid = editid

  wset, editid
  tv, *bim

  Widget_Control, info.idp3Window, Set_UValue = info
  Widget_Control, editWindow, Set_UValue = editinfo
  XManager, 'idp3_edit', editWindow, /No_Block, Event_Handler='editim_ev'

end

