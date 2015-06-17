pro DeleteCancel, event
  Widget_Control, event.top, /Destroy
end

pro MarkAll, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=deleteinfo
  deleteinfo.delvalues[*] = 1
  numimages = n_elements(deleteinfo.delvalues)
  for i = 0, numimages-1 do begin
    Widget_Control, deleteinfo.delbuttons[i], Set_Button=deleteinfo.delvalues[i]
  endfor  
  Widget_Control, event.top, Set_UValue = deleteinfo

end

pro UnmarkAll, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=deleteinfo
  deleteinfo.delvalues[*] = 0
  numimages = n_elements(deleteinfo.delbuttons)
  for i = 0, numimages-1 do begin
    Widget_Control, deleteinfo.delbuttons[i],Set_Button=deleteinfo.delvalues[i]
  endfor  
  Widget_Control, event.top, Set_UValue = deleteinfo

end

pro Deleteimages, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=deleteinfo
  Widget_Control, deleteinfo.info.idp3Window, Get_UValue=info

  if ptr_valid(info.images) then begin
    ims = info.images
    numimages = n_elements(*ims)
    mov = info.moveimage
    templist = 0
    totdel = total(deleteinfo.delvalues)
    if totdel eq 0 then begin
      stat = Widget_Message('Nothing marked for deletion!')
    endif else begin
      if numimages eq totdel then begin
        ; delete all images
        delall = 1
        for i = 0, numimages-1 do begin
	  ptr_free,(*(*ims)[i]).data
	  ptr_free,(*(*ims)[i]).phead
	  ptr_free,(*(*ims)[i]).ihead
	  if ptr_valid((*(*ims)[i]).errs) then ptr_free, (*(*ims)[i]).errs
	  if ptr_valid((*(*ims)[i]).mask) then ptr_free, (*(*ims)[i]).mask
	  if ptr_valid((*(*ims)[i]).xnan) then ptr_free, (*(*ims)[i]).xnan
	  if ptr_valid((*(*ims)[i]).ynan) then ptr_free, (*(*ims)[i]).ynan
	  hname = 'idp3_viewhead' + strtrim(string(i),2)
	  if XRegistered(hname) then $
	     Widget_Control, (*(*ims)[i]).viewwin, /Destroy
          cname = 'idp3_showcntrd' + strtrim(string(i),2)
	  if XRegistered(cname) then $
	     Widget_Control, (*(*ims)[i]).cntrdwin, /Destroy
	  ptr_free,(*ims)[i]
        endfor
        ptr_free,ims
        ptr_free, info.images
        info.images = ptr_new(templist)
        info.moveimage = 0
      endif else begin
        ; delete some of the images
        delall = 0
	if deleteinfo.delvalues[mov] eq 1 then begin
	  stat = Widget_Message('Cannot delete Reference Image')
	  return
        endif else begin
          indx = 0
          for i = 0, numimages-1 do begin
	    if deleteinfo.delvalues[i] eq 1 then begin
	      hname = 'idp3_viewhead' + strtrim(string(i),2)
	      if XRegistered(hname) then $
	         Widget_Control, (*(*ims)[i]).viewwin, /Destroy
              cname = 'idp3_showcntrd' + strtrim(string(i),2)
	      if XRegistered(cname) then $
	         Widget_Control, (*(*ims)[i]).cntrdwin, /Destroy
	    endif else begin
	      if indx eq 0 then begin
	        templist=(*ims)[i] 
	        indx = 1
	      endif else begin
	        templist=[templist,(*ims)[i]]
              endelse
            endelse
          endfor
          ptr_free, ims
          ptr_free, info.images
          info.images = ptr_new(templist)
          for i = 0, mov -1 do begin
	    if deleteinfo.delvalues[i] eq 1 then info.moveimage=info.moveimage-1
          endfor
        endelse
      endelse
      Widget_Control, deleteinfo.info.idp3Window, Set_UValue=info
      deleteinfo.info = info

      ; If ShowIm is running, kill it.
      if (XRegistered('idp3_showim')) then begin
        geo = Widget_Info(info.ShowImBase, /geometry)
        info.wpos.siwp[0] = geo.xoffset - info.xoffcorr
        info.wpos.siwp[1] = geo.yoffset - info.yoffcorr
        Widget_Control, deleteinfo.info.idp3Window, Set_UValue=info
        Widget_Control, info.ShowImBase, /Destroy
        if delall eq 0 then idp3_showim, $
         {WIDGET_BUTTON,ID:0L,TOP:deleteinfo.info.idp3Window,HANDLER:0L,SELECT:0}
        Widget_Control, deleteinfo.info.idp3Window, Get_UValue=info
        deleteinfo.info = info
        Widget_Control, event.top, Set_UValue=deleteinfo
      endif

      ; If AdjustPosition is running, kill it.
      if delall eq 1 then begin
        blnk = $
         '                                                                     '
        if XRegistered('idp3_adjustposition') then begin
          geo = Widget_Info(deleteinfo.info.apWindow, /geometry)
          info.wpos.apwp[0] = geo.xoffset - info.xoffcorr
          info.wpos.apwp[1] = geo.yoffset - info.yoffcorr
          Widget_Control, deleteinfo.info.idp3Window, Set_UValue=info
          Widget_Control, info.apWindow, /Destroy
        endif
        if XRegistered('idp3_roi') then begin
	   Widget_Control, deleteinfo.info.idp3Window, Get_UValue=info
	   closeroi = 0
	   idp3_roiClose, info, closeroi
	   wset, (*info.roi).drawid2
	   xsz = ((*info.roi).roixend-(*info.roi).roixorig+1)*(*info.roi).roizoom
	   ysz = ((*info.roi).roiyend-(*info.roi).roiyorig+1)*(*info.roi).roizoom
	   blank = fltarr(xsz, ysz)
	   tv, blank
	   Widget_Control, info.rwcslab, Set_Value = blnk
	   Widget_Control, info.pixval, Set_Value = blnk
	   Widget_Control, info.pixval2, Set_Value = blnk
	   Widget_Control, deleteinfo.info.idp3Window, Set_UValue=info
        endif
        Widget_Control, info.morientlab, Set_Value = blnk
        Widget_Control, info.mwcslab, Set_Value = blnk
        Widget_Control, info.mpixlab, Set_Value = blnk
        wset, info.drawid1
        im = fltarr(info.drawxsize, info.drawysize)
        tv, im
      endif

      ; save widget position, update graphics display, and destroy widget
      Widget_Control, deleteinfo.info.idp3Window, Set_UValue=info
      Widget_Control, event.top, Set_UValue=deleteinfo
      geo = Widget_Info(event.top, /geometry)
      Widget_Control, event.top, Get_UValue=deleteinfo
      Widget_Control, deleteinfo.info.idp3Window, Get_UValue=info
      info.wpos.diwp[0] = geo.xoffset - info.xoffcorr
      info.wpos.diwp[1] = geo.yoffset - info.yoffcorr
      Widget_Control, deleteinfo.info.idp3Window, Set_UValue=info
      idp3_display,info
      Widget_Control, deleteinfo.info.idp3Window, Get_UValue=info
      deleteinfo.info=info
      Widget_Control, event.top, Set_UValue=deleteinfo
      Widget_Control, event.top, /Destroy
    endelse
  endif else begin
    str = 'Deleteimage: Bad pointer: ' + string(info.images)
    idp3_updatetxt, info, str
    return
  endelse
end

pro Deleteim_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=deleteinfo
  Widget_Control, deleteinfo.info.idp3Window, Get_UValue=tinfo
  deleteinfo.info = tinfo

  ; Look and see which widget produced the event, update appropriately.
  for i = 0, n_elements(*deleteinfo.info.images)-1 do begin
    case event.id of
      deleteinfo.imNames[i]: begin
	; Make that image the 'moving' image.
	oldmove = tinfo.moveimage
	tinfo.moveimage = i
	str = 'Deleteimage: setting Reference Image to ' + $
	    (*(*tinfo.images)[i]).name
        idp3_updatetxt, tinfo, str
        str = '*' + string(i,'$(i3)')
	Widget_Control, deleteinfo.imlabs[i], Set_Value=str
	Widget_Control, deleteinfo.imlabs[oldmove], $
	   Set_Value=string(oldmove,'$(i4)')
	Widget_Control, deleteinfo.info.idp3Window, Set_UValue=tinfo
	Widget_Control, event.top, Set_UValue=deleteinfo

	; Adjust Position widget update.
	if (XRegistered('idp3_adjustposition')) then begin
          geo = Widget_Info(deleteinfo.info.apWindow, /geometry)
          deleteinfo.info.wpos.apwp[0] = geo.xoffset - deleteinfo.info.xoffcorr
          deleteinfo.info.wpos.apwp[1] = geo.yoffset - deleteinfo.info.yoffcorr
          Widget_Control, deleteinfo.info.idp3Window,Set_UValue=deleteinfo.info
	  Widget_Control, deleteinfo.info.apWindow, /Destroy
	  idp3_adjustposition, $
       {WIDGET_BUTTON,ID:0L,TOP:deleteinfo.info.idp3Window,HANDLER:0L,SELECT:0}
	endif
	Widget_Control, deleteinfo.info.idp3Window, Get_UValue=tinfo
	deleteinfo.info = tinfo
	Widget_Control, event.top, Set_UValue=deleteinfo
	end

      deleteinfo.delButtons[i]: begin
	; Toggle on or off.
	if event.select eq 1 then begin
	  if deleteinfo.info.moveimage ne i then begin
	    deleteinfo.delvalues[i] = 1
          endif else begin
	    str = 'Reference Image - Must move before deleting!
	    stat = Widget_Message(str)
            Widget_Control, deleteinfo.delbuttons[i], Set_Button = $
	      deleteinfo.delvalues[i]
          endelse
	endif else if event.select eq 0 then begin
	  deleteinfo.delvalues[i] = 0
	endif
        end

    else:
    endcase
  endfor

;  Widget_Control,deleteinfo.info.idp3Window,Get_UValue=tinfo
;  deleteinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=deleteinfo

end

pro Idp3_DeleteIm, event

; This widget shows the list of images and allows the user to select
; images to delete and move the reference image.

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_deleteim')) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  c = size(*info.images)
  if (c[0] eq 0 and c[1] eq 2) then return

  deleteimWindow = Widget_base(Title='IDP3 Delete Images Window', /Column, $
     Group_Leader = event.top, $
     XOffset = info.wpos.diwp[0], $
     YOffset = info.wpos.diwp[1])

  lab = Widget_Label(deleteimWindow, Value = $
    '                                                             ')

  deleteWindow = Widget_base(deleteimWindow, $
		       Title='IDP3 Delete Images Window', /Column, /scroll, $
		       y_scroll_size = info.delimysize - 1, $
		       x_scroll_size = info.delimxsize - 20, $
		       xsize = info.delimxsize, $
		       ysize = info.delimysize)

  ; Get the number of images.
  numimages = n_elements(*info.images)

  ; Find the maximum length of the image names and set the name field widths.
  ilen = 0
  for i = 0, numimages-1 do begin
    ua_decompose,(*(*info.images)[i]).name,disk,path,name,extn,version

    ; Paths or not, it is the user's preference.
    if info.sip eq 1 then begin
      thisnamelen = strlen((*(*info.images)[i]).name)
      if thisnamelen gt ilen then ilen = thisnamelen
    endif else begin
      thisnamelen = strlen(name+extn)
      if thisnamelen gt ilen then ilen = thisnamelen
    endelse
  endfor

  imBases = lonarr(numimages)
  imlabs = lonarr(numimages)
  imNames = lonarr(numimages)
  delBases = lonarr(numimages)
  delButtons = lonarr(numimages)
  delvalues = intarr(numimages)
  delvalues[*] = 0
  mov = info.moveimage

  ; For each image, make a base and set of widgets.
  for i = 0, numimages-1 do begin
    imBases[i] = Widget_Base(deleteWindow,/Row)
    if i eq mov then begin
      str = '*' + string(i,'$(i3)')
      imlabs[i] = Widget_Label(imBases[i], Value=str)
      ua_decompose, (*(*info.images)[i]).name, disk, path, fname, extn, vers
      str = '* -> Reference:' + string(i,'$(i3)') + ' ' + fname
      Widget_Control, lab, Set_Value=str
    endif else begin
      imlabs[i] = Widget_Label(imBases[i], Value=string(i,'$(i4)'))
    endelse
    ua_decompose,(*(*info.images)[i]).name,disk,path,name,extn,version
    ; Show paths or not, it is the user's preference.
    if info.sip eq 1 then begin
      imNames[i] = Widget_Text(imBases[i], value=(*(*info.images)[i]).name, $
			     xsize=ilen, /All_Events)
    endif else begin
      showname = name + extn
      imNames[i] = Widget_Text(imBases[i], value=showname, $
			     xsize=ilen, /All_Events)
    endelse
    delBases[i] = Widget_Base(imBases[i],/row,/nonexclusive)
    delButtons[i] = Widget_Button(delBases[i], Value='Delete')
    Widget_Control, delButtons[i], Set_Button = delvalues[i] 

  endfor
  donebase = Widget_Base(deleteimWindow, /Row)
  allButton = Widget_Button(doneBase, Value='Mark All', /Align_Center, $
			     Event_Pro = 'markall')
  noneButton = Widget_Button(doneBase, Value='Unmark All', /Align_Center, $
			     Event_Pro = 'unmarkall')
  deleteButton = Widget_Button(doneBase, Value='Delete', /Align_Center, $
			     Event_Pro = 'Deleteimages')
  cancelButton = Widget_Button(donebase, Value='Cancel', /Align_Center, $
			     Event_Pro = 'DeleteCancel')

;  Widget_Control,info.idp3Window, Get_UValue = info

  deleteinfo = {                                $
   	         allButton      : allButton,    $
	         deleteButton   : deleteButton, $
	         imNames        : imNames,      $
		 imLabs         : imLabs,       $
	         delButtons     : delButtons,   $
	         delvalues      : delvalues,    $
	         info           : info          }

  Widget_Control, deleteimWindow, SET_UVALUE=deleteinfo

  Widget_Control, deleteimWindow, /Realize
  XManager, 'idp3_deleteim', deleteimWindow, /No_Block, $
     Event_Handler='DeleteIm_Event'

end
