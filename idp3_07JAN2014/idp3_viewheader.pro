pro viewhead_done, event
  Widget_Control, event.top, /Destroy
  end

pro idp3_viewheader_evt, event

  Widget_Control, event.top, Get_UValue = vhinfo
  theheader = vhinfo.hdr
  nlines = vhinfo.height

  Case event.id of

  vhinfo.findkeyfield: begin
    Widget_Control, vhinfo.findkeyfield, Get_Value=thiskey
    thiskey = strtrim(strupcase(thiskey[0]),2)
    num = n_elements(theheader)
    if num gt 0 then begin
      whereitis = where(strpos(theheader[0:num-1], thiskey) ne -1, count)
      if count lt 1 then begin
	str = 'Cannot find keyword ' + thiskey
	stat = Widget_Message(str)
      endif else begin
	loc = whereitis[0] + nlines-1 
	os = Widget_Info(vhinfo.wheader, Text_XY_To_offset=[0,loc])
	Widget_Control, vhinfo.wheader, Set_Text_Select=[os,80]
	os = Widget_Info(vhinfo.wheader, Text_XY_To_offset=[0,whereitis[0]])
	Widget_Control, vhinfo.wheader, Set_Text_SELECT=[os,80]
	Widget_Control, vhinfo.wheader, Set_Value=theheader[whereitis[0]], $
		 /Use_Text_Select, /No_Newline
       Widget_Control, vhinfo.wheader, /Input_Focus
      endelse
    endif
  end

  vhinfo.applybutton: begin
    Widget_Control, vhinfo.findkeyfield, Get_Value=thiskey
    thiskey = strupcase(thiskey[0])
    num = n_elements(theheader)
    if num gt 0 then begin
      whereitis = where(strpos(theheader[0:num-1], thiskey) ne -1, count)
      if count lt 1 then begin
	str = 'Cannot find keyword ' + thiskey
	stat = Widget_Message(str)
      endif else begin
	loc = whereitis[0] + nlines-1 
	os = Widget_Info(vhinfo.wheader, Text_XY_To_offset=[0,loc])
	Widget_Control, vhinfo.wheader, Set_Text_Select=[os,80]
	os = Widget_Info(vhinfo.wheader, Text_XY_To_offset=[0,whereitis[0]])
	Widget_Control, vhinfo.wheader, Set_Text_SELECT=[os,80]
	Widget_Control, vhinfo.wheader, Set_Value=theheader[whereitis[0]], $
		 /Use_Text_Select, /No_Newline
       Widget_Control, vhinfo.wheader, /Input_Focus
      endelse
    endif
  end

  vhinfo.wheader: begin
   z=1  ; no op
  end

  endcase
end

pro idp3_viewheader, info, ii

@idp3_structs
@idp3_errors

  imptr = (*info.images)[ii]
  hdr = [*(*imptr).phead, *(*imptr).ihead]
  ua_decompose, (*imptr).name, disk, path, fname, extn, version

  wname = 'idp3_viewhead' + strtrim(string(ii),2)
  if XRegistered(wname) then begin
    Widget_Control, (*imptr).viewtext, Set_Value = hdr
    return
  endif 

; Pop up a widget to show the reference image header and allow
; the user to scroll through it.

  height = info.viewhdrysize
  thename = fname + extn
  width = 80

  title = 'IDP3 header for '+thename

  vhWindow = Widget_Base(group_leader=info.idp3Window, $
			 Title = title, /Base_Align_Left, /Column)
  headerbase = Widget_Base(vhWindow, /Row)
  findkeyfield = CW_Field(headerbase, value=' ', row=1, return_events=1, $
	   title='Find Keyword:', xsize=11)
  applybutton = Widget_Button(headerbase, uvalue='apply', Value='Search')
  donebutton = Widget_Button(headerbase, uvalue='exit', Value='Done', $
	       Event_Pro = 'viewhead_done')

  wheader = Widget_Text(vhWindow, xsize=width, ysize=height, value=hdr, $
	  /scroll, /all_events)

  (*imptr).viewtext = wheader
  (*imptr).viewwin = vhWindow
  (*info.images)[ii] = imptr

  vhinfo = { $
	   wHeader      :  wHeader,     $
	   findkeyfield : findkeyfield, $
	   applybutton  : applybutton,  $
	   hdr          : hdr,          $
	   height       : height,       $
	   info         : info          $
	   }
  
  Widget_Control, vhWindow, Set_UValue=vhinfo
  Widget_Control, vhWindow, /Realize
 
  XManager, wname, vhWindow, /No_Block, $
		Event_Handler = "idp3_viewheader_evt"

end

