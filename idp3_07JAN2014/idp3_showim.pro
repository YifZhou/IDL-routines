pro ShowIm_Done, event

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.siwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.siwp[1] = geo.yoffset - tempinfo.yoffcorr
  tempinfo.proshold = 0
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end

pro ShowIm_Help, event
  tmp = idp3_findfile('idp3_showim.hlp')
  xdisplayfile, tmp
end

Function ShowIm_Hold, event

  ; Toggle process hold, if set to no, redo display
  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo
  Widget_Control, showinfo.holdButton, Get_Value = barray
  if barray[0] eq 0 then begin
    tempinfo.proshold = 0
    idp3_display,tempinfo
  endif else begin
    tempinfo.proshold = 1
  endelse
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo

end

pro ShowIm_AllOff, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images visibility functions to off.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).vis = 0
    Widget_Control, showinfo.onoffButtons[i], Set_Button=(*(*ims)[i]).vis
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro ShowIm_AllOn, Event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images visibility functions to on.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).vis = 1
    Widget_Control, showinfo.onoffButtons[i], Set_Button=(*(*ims)[i]).vis
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro ShowIm_AllmaskOff, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the masks for all images visibility functions to off.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).maskvis = 0
    Widget_Control, showinfo.maskonoffButtons[i],Set_Button=(*(*ims)[i]).maskvis
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro ShowIm_AllmaskOn, Event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images mask visibility functions to on.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).maskvis = 1
    Widget_Control, showinfo.maskonoffButtons[i],Set_Button=(*(*ims)[i]).maskvis
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro ShowIm_AllAdd, Event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images function to add.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).dispf = ADD
    Widget_Control, showinfo.dispfBases[i], Set_Value = '  Add   '
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  

end

pro ShowIm_AllSub, Event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images function to subtract.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).dispf = SUB
    Widget_Control, showinfo.dispfBases[i], Set_Value='  Sub  '
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
End

pro ShowIm_AllAve, Event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images function to average.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).dispf = AVE 
    Widget_Control, showinfo.dispfBases[i], Set_Value='  Ave  '
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  

end

pro Showim_AllPad, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return
  pstr = strtrim(string(tempinfo.apad),2)

  ; get pad value
  title = 'Border Pad'
  valstr = idp3_getvals(title, pstr, groupleader=event.top, $
     cancel=cancel, xp=tempinfo.wpos.siwp[0]-120, yp=tempinfo.wpos.siwp[1])
  if cancel eq 1 then begin
    str ='AllPad: No pad entered'
    idp3_updatetxt, tempinfo, str
    return
  endif
  pad = fix(valstr)
  tempinfo.apad = pad
  
  ; Set pad for all the images.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).topad = 1 
    (*(*ims)[i]).pad = pad
  endfor

  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro Showim_AllDepad, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set the pad for all images to 0.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).topad = 0 
    (*(*ims)[i]).pad = 0
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro Showim_AllMin, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images function to average.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).dispf = MIN 
    Widget_Control, showinfo.dispfBases[i], Set_Value='  Min  '
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro Showim_AllFlipy, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ;Reverse the state of FlipY for all the images.
  for i = 0, n_elements(*ims)-1 do begin
    if (*(*ims)[i]).flipy eq 0 then (*(*ims)[i]).flipy = 1 $
      else (*(*ims)[i]).flipy = 0
    Widget_Control, showinfo.flipyButtons[i], Set_Button=(*(*ims)[i]).flipy
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro Showim_AllPos, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images function to average.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).dispf = POS 
    Widget_Control, showinfo.dispfBases[i], Set_Value='  Pos  '
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro Showim_AllNeg, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ;If there are no images, then return
  ims = tempinfo.images
  if n_elements(*ims) lt 1 then return

  ; Set all the images function to average.
  for i = 0, n_elements(*ims)-1 do begin
    (*(*ims)[i]).dispf = NEG 
    Widget_Control, showinfo.dispfBases[i], Set_Value='abs(Neg)'
  endfor

  Widget_control, showinfo.info.idp3Window, Get_UValue=tempinfo

  ; Update graphics display
  idp3_display, tempinfo

  ims = 0
  Widget_Control, event.top, Set_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Set_UValue=tempinfo
  
end

pro Showim_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo
  showinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=showinfo

  nim = n_elements(*showinfo.info.images)
  ; Look and see which widget produced the event, update appropriately.
  for i = 0, nim-1 do begin
    print, i, event.id, showinfo.imNames[i]
    case event.id of
      showinfo.imNames[i]: begin
	; Make that image the 'moving' image.
        oldmove = showinfo.info.moveimage
	showinfo.info.moveimage = i
	Widget_Control, showinfo.info.idp3Window, Set_UValue=showinfo.info
        Widget_Control, showinfo.imlabs[oldmove], Set_Value = $
	   string(oldmove,'$(i4)')
        str = '*' + string(i,'$(i3)')	    
        Widget_Control, showinfo.imlabs[i],Set_Value=str
	str = '* -> Reference:' + string(i,'$(i3)') + ' ' + $
	     (*(*showinfo.info.images)[i]).name
        Widget_Control, showinfo.info.showreflabel, Set_Value=str
	str = 'Showimages: setting Reference Image to ' + $
	  (*(*showinfo.info.images)[i]).name
        idp3_updatetxt, showinfo.info, str

	; Adjust Position widget update.
	if (XRegistered('idp3_adjustposition')) then begin
          geo = Widget_Info(showinfo.info.apWindow, /geometry)
          showinfo.info.wpos.apwp[0] = geo.xoffset - showinfo.info.xoffcorr
          showinfo.info.wpos.apwp[1] = geo.yoffset - showinfo.info.yoffcorr
          Widget_Control, showinfo.info.idp3Window, Set_UValue=showinfo.info
	  Widget_Control, showinfo.info.apWindow, /Destroy
	  idp3_adjustposition, $
	{WIDGET_BUTTON,ID:0L,TOP:showinfo.info.idp3Window,HANDLER:0L,SELECT:0}
	endif
	  
	; Edit Widget update.
	if XRegistered('idp3_edit') then begin
	  idp3_editim, $
	  {WIDGET_BUTTON,ID:0L,TOP:showinfo.info.idp3Window,HANDLER:0L,SELECT:0}
        endif

	Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo
	showinfo.info = tempinfo
	Widget_Control, event.top, Set_UValue=showinfo
	end

      showinfo.onoffButtons[i]: begin
	; Toggle on or off.
	if event.select eq 1 then begin
	  (*(*showinfo.info.images)[i]).vis = 1
	endif else if event.select eq 0 then begin
	  if showinfo.info.moveimage eq i and nim gt 1 and $
	    showinfo.info.ref_warn eq 1 then begin
	    idp3_selectval, event.top, $
	      'Do you wish to turn off the Reference Image?', ['no','yes'], val
            if val eq 0 then Widget_Control, showinfo.onoffButtons[i], $
	       Set_Button=(*(*showinfo.info.images)[i]).vis $
	    else (*(*showinfo.info.images)[i]).vis = 0
          endif	else (*(*showinfo.info.images)[i]).vis = 0
	endif
        end

      showinfo.maskonoffButtons[i]: begin
	; Toggle on or off.
	if event.select eq 1 then begin
	  (*(*showinfo.info.images)[i]).maskvis = 1
        endif else begin
	  (*(*showinfo.info.images)[i]).maskvis = 0
        endelse
        end

      showinfo.flipyButtons[i]: begin
	; Toggle flip y on or off.
	if event.select eq 1 then begin
	  (*(*showinfo.info.images)[i]).flipy = 1
	endif else if event.select eq 0 then begin
	  (*(*showinfo.info.images)[i]).flipy = 0
	endif
        end

      showinfo.hdrButtons[i]: begin
	; show header for this image
	idp3_viewheader, tempinfo, i
	Widget_Control, showinfo.info.idp3Window, get_UValue=tempinfo
	showinfo.info = tempinfo
	end

      showinfo.cntrdButtons[i]: begin
	; show centroid x and y values for this image
	idp3_showcntrd, tempinfo, i
	Widget_Control, showinfo.info.idp3Window, Get_UValue=tempinfo
	showinfo.info = tempinfo
	end

      showinfo.addButtons[i]: begin
	; Set this image's display function to add.
	(*(*showinfo.info.images)[i]).dispf = ADD
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Add   '
        end

      showinfo.subButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = SUB
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Sub   '
        end

      showinfo.aveButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = AVE
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Ave   '
        end

      showinfo.minButtons[i]: begin
	; Set this image's display function to minimum.
	(*(*showinfo.info.images)[i]).dispf = MIN
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Min   '
        end

      showinfo.invButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = INV
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Inv   '
        end

      showinfo.divButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = DIV
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Div   '
        end

      showinfo.mulButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = MUL
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  Mul   '
        end

      showinfo.posButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = POS
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = '  POS   '
        end

      showinfo.negButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = NEG
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = 'abs(Neg)'
        end

      showinfo.absButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = ABS
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = 'ABS'
        end

      showinfo.magButtons[i]: begin
	(*(*showinfo.info.images)[i]).dispf = MAG
	; Update graphics display.
	Widget_Control, showinfo.dispfBases[i], Set_Value = 'MAG'
        end

    else:
    endcase
  endfor

;  Widget_Control, showinfo.info.idp3Window, Set_UValue=showinfo.info
  if showinfo.info.proshold eq 0 then begin
    idp3_display,showinfo.info
  endif
;  Widget_Control,showinfo.info.idp3Window,Get_UValue=tinfo
;  showinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=showinfo

end

pro Idp3_ShowIm, event

; This widget shows the list of images and allows the user to select
; the 'move' image, turn images on or off, and adjust the display functions.

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_showim')) then return

  Widget_Control, event.top, Get_UValue=info

  c = size(*info.images)
  if (c[0] eq 0 and c[1] eq 2) then return

  ; Adjust the characteristics of this widget based on IDP3 preferences.
  ; To scroll or not to scroll, that is the question.
  showimWindow = Widget_base(Title = 'IDP3 Show Images Window', /Column, $
			 Group_Leader = event.top, $
			 XOffset = info.wpos.siwp[0], $
			 YOffset = info.wpos.siwp[1])

  button0base = Widget_Base(showimWindow, /Row)
  laball = Widget_Label(button0base, Value='Functions for ALL Images:')
  labsp = Widget_Label(button0base, Value=$
      '                                   ')
  holdButton = cw_bgroup(button0base, ['Hold Processing'], row=1, $
	 set_value = [info.proshold], /nonexclusive, Event_Funct='ShowIm_Hold')
  helpButton = Widget_Button(button0Base, Value='Help', /Align_Center, $
			     Event_Pro='ShowIm_Help')
  doneButton = Widget_Button(button0Base, Value='Done', /Align_Center, $
  			     Event_Pro = 'ShowIm_Done')
  buttonbase = Widget_Base(showimWindow, /Row)
  allon = Widget_Button(buttonbase, Value='ON', $
		   Event_Pro = 'Showim_AllOn')
  alloff = Widget_Button(buttonbase, Value='OFF', $
		   Event_Pro = 'Showim_AllOff')
  allmaskon = Widget_Button(buttonbase, Value='MaskON', $
		   Event_Pro = 'Showim_AllmaskOn')
  allmaskoff = Widget_Button(buttonbase, Value='MaskOFF', $
		   Event_Pro = 'Showim_AllmaskOff')
  allflipy = Widget_Button(Buttonbase, Value='Flip Y', $
                   Event_Pro = 'Showim_AllFlipy')
  alladd = Widget_Button(buttonbase, Value='Add', $
		   Event_Pro = 'Showim_AllAdd')
  allsub = Widget_Button(buttonbase, Value='Subtract', $
		   Event_Pro = 'Showim_AllSub') 
  allave = Widget_Button(buttonbase, Value='Ave', $
		   Event_Pro = 'Showim_AllAve')
  allmin = Widget_Button(buttonbase, Value='Min', $
                   Event_Pro = 'Showim_AllMin')
  allpos = Widget_Button(Buttonbase, Value='Pos', $
		   Event_Pro = 'Showim_AllPos')
  allneg = Widget_Button(Buttonbase, Value='ABS(Neg)', $
		   Event_Pro = 'Showim_AllNeg')
  allresamp = Widget_Button(buttonbase, Value='Resample', $
		   Event_Pro = 'idp3_AllResamp')
  allpad = Widget_Button(Buttonbase, Value='Pad', $
                   Event_Pro = 'Showim_AllPad')
  alldepad = Widget_Button(Buttonbase, Value='Rm Pad', $
                   Event_Pro = 'Showim_AllDepad')
  lab = Widget_Label(showimWindow, Value=$
   '                                                                          ')
  xscroll = info.showimscxsize > 570
  xsz = info.showimxsize > 570
  showWindow = Widget_Base(showimWindow, /Column, /scroll, $
				y_scroll_size = info.showimscysize,$
				x_scroll_size = xscroll, $
				xsize = xsz, $
				ysize = info.showimysize)

  ; Get the number of images.
  numimages = n_elements(*info.images)

  ; Find the maximum length of the image names and set the name field widths.
  ilen = 0
  for i = 0, numimages-1 do begin
    ua_decompose,(*(*info.images)[i]).name,disk,path,name,extn,version
    ; Paths or not, it is the user's preference.
    if info.sip eq 1 then begin
      totalname = (*(*info.images)[i]).name 
      if strlen((*(*info.images)[i]).extnam) gt 0 then totalname = $
	 totalname + '[' + (*(*info.images)[i]).extnam + ']'
      thisnamelen = strlen(totalname)
      if thisnamelen gt ilen then ilen = thisnamelen
    endif else begin
      totalname = name 
      if strlen((*(*info.images)[i]).extnam) gt 0 then totalname = $
	 totalname + '[' + (*(*info.images)[i]).extnam + ']'
      thisnamelen = strlen(totalname+extn)
      if thisnamelen gt ilen then ilen = thisnamelen
    endelse
  endfor

  imBases = lonarr(numimages)
  imlabs = lonarr(numimages)
  imNames = lonarr(numimages)
  onoffBases = lonarr(numimages)
  onoffButtons = lonarr(numimages)
  maskonoffBases = lonarr(numimages)
  maskonoffButtons = lonarr(numimages)
  flipyBases = lonarr(numimages)
  flipyButtons = lonarr(numimages)
  dispfBases = lonarr(numimages)
  addButtons = lonarr(numimages)
  subButtons = lonarr(numimages)
  aveButtons = lonarr(numimages)
  minButtons = lonarr(numimages)
  invButtons = lonarr(numimages)
  divButtons = lonarr(numimages)
  posButtons = lonarr(numimages)
  absButtons = lonarr(numimages)
  negButtons = lonarr(numimages)
  mulButtons = lonarr(numimages)
  magButtons = lonarr(numimages)
  hdrButtons = lonarr(numimages)
  cntrdButtons = lonarr(numimages)
  mov = info.moveimage

  ; For each image, make a base and set of widgets.
  for i = 0, numimages-1 do begin
    imBases[i] = Widget_Base(showWindow,/Row)
    if i eq mov then begin
      str = '*' + string(i,'$(i3)')
      imlabs[i] = Widget_Label(imBases[i], Value=str)
      str = '* -> Reference:' + string(i,'$(i3)') + ' ' + $
	    (*(*info.images)[i]).name
      Widget_Control, lab, Set_Value=str
    endif else begin
      imlabs[i] = Widget_Label(imBases[i], Value=string(i,'$(i4)'))
    endelse
    ua_decompose,(*(*info.images)[i]).name,disk,path,name,extn,version
    ; Show paths or not, it is the user's preference.
    if info.sip eq 1 then begin
      showname = (*(*info.images)[i]).name 
      if strlen((*(*info.images)[i]).extnam) gt 0 then showname = showname + $
	'[' + (*(*info.images)[i]).extnam + ']'
      imNames[i] = Widget_Text(imBases[i], value=showname, $
			     xsize=ilen, /All_Events)
    endif else begin
      showname = name + extn
      if strlen((*(*info.images)[i]).extnam) gt 0 then showname = showname + $
	'[' + (*(*info.images)[i]).extnam + ']'
      imNames[i] = Widget_Text(imBases[i], value=showname, $
			     xsize=ilen, /All_Events)
    endelse
    onoffBases[i] = Widget_Base(imBases[i],/row,/nonexclusive)
    onoffButtons[i] = Widget_Button(onoffBases[i], Value='On')
    Widget_Control, onoffButtons[i], Set_Button = (*(*info.images)[i]).vis
    maskonoffBases[i] = Widget_Base(imBases[i],/row,/nonexclusive)
    maskonoffButtons[i] = Widget_Button(maskonoffBases[i], Value='MaskOn')
    Widget_Control,maskonoffButtons[i],Set_Button=(*(*info.images)[i]).maskvis

    flipyBases[i] = Widget_Base(imBases[i],/row,/nonexclusive)
    flipyButtons[i] = Widget_Button(flipyBases[i], Value='Flip Y')
    Widget_Control, flipyButtons[i], Set_Button = (*(*info.images)[i]).flipy

    dispfBases[i] = Widget_Button(imBases[i],/menu, /align_center)
    case (*(*info.images)[i]).dispf of
      ADD: Widget_Control, dispfBases[i], Set_Value = '  Add   '
      SUB: Widget_Control, dispfBases[i], Set_Value = '  Sub   '
      AVE: Widget_Control, dispfBases[i], Set_Value = '  Ave   '
      MIN: Widget_Control, dispfBases[i], Set_Value = '  Min   '
      DIV: Widget_Control, dispfBases[i], Set_Value = '  Div   '
      MUL: Widget_Control, dispfBases[i], Set_Value = '  Mul   '
      INV: Widget_Control, dispfBases[i], Set_Value = '  INV   '
      POS: Widget_Control, dispfBases[i], Set_Value = '  Pos   '
      NEG: Widget_Control, dispfBases[i], Set_Value = 'abs(Neg)'
      ABS: Widget_Control, dispfBases[i], Set_Value = '  ABS   '
      MAG: Widget_Control, dispfBases[i], Set_Value = 'Magnitudes'
    endcase

    addButtons[i] = Widget_Button(dispfBases[i], Value='Add', /align_center)
    subButtons[i] = Widget_Button(dispfBases[i], Value='Sub', /align_center)
    aveButtons[i] = Widget_Button(dispfBases[i], Value='Ave', /align_center)
    minButtons[i] = Widget_Button(dispfBases[i], Value='Min', /align_center)
    invButtons[i] = Widget_Button(dispfBases[i], Value='Inv', /align_center)
    divButtons[i] = Widget_Button(dispfBases[i], Value='Div', /align_center)
    mulButtons[i] = Widget_Button(dispfBases[i], Value='Mul', /align_center)
    posButtons[i] = Widget_Button(dispfBases[i], Value='Pos', /align_center)
    negButtons[i] = Widget_Button(dispfBases[i], Value='abs(Neg)',/align_center)
    absButtons[i] = Widget_Button(dispfBases[i], Value='Abs', /align_center)
    magButtons[i] = Widget_Button(dispfBases[i], Value='Mag', /align_Center)
    hdrButtons[i] = Widget_Button(imBases[i], Value='Hdr', /align_center)
    cntrdButtons[i] = Widget_Button(imBases[i], Value='CrdXY', /align_center)
  endfor

  Widget_Control,info.idp3Window, Get_UValue = info
  info.ShowImBase = showimWindow
  info.showreflabel = lab
  Widget_Control,info.idp3Window, Set_UValue = info

  showinfo = { doneButton       : doneButton,       $
	       addButtons       : addButtons,       $
	       subButtons       : subButtons,       $
	       aveButtons       : aveButtons,       $
	       minButtons       : minButtons,       $
	       invButtons       : invButtons,       $
	       divButtons       : divButtons,       $
	       mulButtons       : mulButtons,       $
	       posButtons       : posButtons,       $
	       negButtons       : negButtons,       $
	       absButtons       : absButtons,       $
               magButtons       : magButtons,       $
	       dispfBases       : dispfBases,       $
	       imlabs           : imlabs,           $
	       imNames          : imNames,          $
	       onoffButtons     : onoffButtons,     $
	       maskonoffButtons : maskonoffButtons, $
	       flipyButtons   : flipyButtons,       $
	       hdrButtons     : hdrButtons,         $
	       cntrdButtons   : cntrdButtons,       $
	       holdButton     : holdButton,         $   
	       info           : info                }

  Widget_Control, showimWindow, SET_UVALUE=showinfo

  Widget_Control, showimWindow, /Realize
  XManager, 'idp3_showim', showimWindow, /No_Block, Event_Handler='ShowIm_Event'

end
