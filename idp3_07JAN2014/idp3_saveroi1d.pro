pro save1d_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savemdinfo
  Widget_Control, savemdinfo.info.idp3Window, Get_UValue = info
;  info = savemdinfo.info

  case event.id of

    savemdinfo.selectfile: begin

      ; Get the file name the user typed in.
      Widget_Control, savemdinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      Widget_Control, savemdinfo.fillButton, Get_Value=barray
      if barray[0] eq 0 then fillarr = 0 else fillarr = 1
      info.roifillarr = fillarr
      roi = info.roi
      x1 = (*roi).roixorig
      y1 = (*roi).roiyorig
      x2 = (*roi).roixend
      y2 = (*roi).roiyend
      if fillarr eq 1 then begin
        ref = info.moveimage
	m = (*info.images)[ref]
	collapsim = (*info.rcollapsim)
	osz = size(collapsim)
        dir = (*info.roi).collapse_dir
	if dir eq 0 then begin
	  y1 = 0
	  y2 = (*m).ysiz-1
	  newroi = fltarr(osz[1], y2+1)
	  for i = 0, osz[1]-1 do begin
	    newroi[i,*] = collapsim[i,0]
          endfor
        endif else begin
	  x1 = 0
	  x2 = (*m).xsiz-1
	  newroi = fltarr(x2+1, osz[2])
	  for i = 0, osz[2]-1 do begin
	    newroi[*,i] = collapsim[0,i]
          endfor
	endelse
	ptr_free, info.rcollapsim
	info.rcollapsim = ptr_new(newroi)
      endif
      ok = idp3_saveimage(event, info, filename, x1, x2, y1, y2, rmsave=1)
      if ok eq 0 then begin
	; save path
	ua_decompose, filename, disk, path, name, extn, version
	info.savepath = disk + path
	Widget_Control, info.idp3Window, Set_UValue=info
	Widget_Control, event.top, /Destroy
      endif else begin
	if ok lt 0 then $
	  test = Dialog_Message('Error in path/filename specification')
      endelse
    end

    savemdinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savemdinfo.selectfile, set_value=fpath
    end

    savemdinfo.saveButton: begin
      Widget_Control, savemdinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      Widget_Control, savemdinfo.fillButton, Get_Value=barray
      if barray[0] eq 0 then fillarr = 0 else fillarr = 1
      info.roifillarr = fillarr
      roi = info.roi
      x1 = (*roi).roixorig
      y1 = (*roi).roiyorig
      x2 = (*roi).roixend
      y2 = (*roi).roiyend
      if fillarr eq 1 then begin
        ref = info.moveimage
	m = (*info.images)[ref]
	collapsim = (*info.rcollapsim)
	osz = size(collapsim)
        dir = (*info.roi).collapse_dir
	if dir eq 0 then begin
	  y1 = 0
	  y2 = (*m).ysiz-1
	  newroi = fltarr(osz[1], y2+1)
	  for i = 0, osz[1]-1 do begin
	    newroi[i,*] = collapsim[i,0]
          endfor
        endif else begin
	  x1 = 0
	  x2 = (*m).xsiz-1
	  newroi = fltarr(x2+1, osz[2])
	  for i = 0, osz[2]-1 do begin
	    newroi[*,i] = collapsim[0,i]
          endfor
	endelse
	ptr_free, info.rcollapsim
	info.rcollapsim = ptr_new(newroi)
      endif
      ok = idp3_saveimage(event,info,filename,x1,x2,y1,y2,rmsave=1)
      if ok eq 0 then begin
        ; save path
        ua_decompose, filename, disk, path, name, extn, version
        info.savepath = disk + path
        Widget_Control, info.idp3Window, Set_UValue=info
        Widget_Control, event.top, /Destroy
      endif else begin
        if ok lt 0 then $
          test = Dialog_Message('Error in path/filename specification')
      endelse
    end

    savemdinfo.fillButton: begin
      Widget_Control, savemdinfo.fillButton, Get_Value=fill
    end

    savemdinfo.cancelButton: begin
      Widget_Control, savemdinfo.info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_saveroi1d, info

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_saveroi1d")) then return

  path = info.savepath
  dir = (*info.roi).collapse_dir
  if dir eq 0 then fstr = 'Fill Y-axis' else fstr = 'Fill X-axis'
  title      = 'IDP3 Save ROI 1D Image'
  savemdbase   = Widget_Base(Title = title, /Column, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1])
  save1base = Widget_Base (savemdbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (savemdbase, /Row)
  label1     = Widget_Label (save2base, Value='                        ')
  fillButton  = cw_bgroup(save2Base,[fstr], row = 1,  $
    set_value = [info.roifillarr], /nonexclusive)
  label2     = Widget_Label (save2base, Value = '     ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savemdinfo = { selectfile    :     selectfile,   $
		 fillButton    :     fillButton,   $
		 browseButton  :     browseButton, $
		 saveButton    :     saveButton,   $
		 cancelButton  :     cancelButton, $
		 info          :     info          }

  Widget_Control, savemdbase, set_uvalue = savemdinfo
  Widget_Control, savemdbase, /Realize

  XManager, "idp3_saveroi1d", savemdbase, Event_Handler = "save1d_ev"
          
end
