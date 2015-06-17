pro clipmipsmedian_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=cmedianinfo
  Widget_Control, cmedianinfo.info.idp3Window, GET_UValue=cinfo

  case event.id of

    cmedianinfo.selectfile: begin
      ; The user hit return after typing in a file name, get it.
      Widget_Control, cmedianinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then extn = '.fits'
      cinfo.savepath = disk + path
      nfile = disk + path + name + extn
      sfile = disk + path + name + '_sdv' + extn
      temp = file_search (nfile, Count = fcount)
      if fcount gt 0 then begin
	idp3_selectval, event.top, 'Do you wish to overwrite existing file?',$
	  ['no','yes'], savfil
        if savfil eq 0 then begin
	  temp = Widget_Message('Reselect name for output file or Cancel')
        endif else begin
	  ; check if path is valid
	  openw, lun, filename, error=err, /get_lun
	  if err eq 0 then begin
	    close, lun
	    free_lun, lun
	    savfil = 1
          endif else begin
	    savfil = 0
	    temp=Widget_Message('Cannot open file for writing - Invalid Path?')
          endelse
        endelse
      endif else savfil = 1
      if savfil eq 1 then begin
        ims = (*cmedianinfo.info.images)
	xo = cmedianinfo.info.sxoff
	yo = cmedianinfo.info.syoff
        text = 'idp3_clipmipsmedian: ' + nfile
        idp3_updatetxt, cinfo, text
	idp3_clipmipsmedian, cmedianinfo.info, nfile, sfile
        Widget_control, event.top, /Destroy
      endif
    end

  cmedianinfo.browseButton: begin
    Pathvalue = Dialog_Pickfile(Title='Please select output file path')
    ua_decompose, Pathvalue, disk, path, file, extn, version
    fpath = disk + path
    Widget_Control, cmedianinfo.selectfile, set_value=fpath
    end

  cmedianinfo.cancelButton: begin
    Widget_Control, cmedianinfo.info.idp3Window, Set_UValue=cinfo
    Widget_Control, event.top, /Destroy
  end

  endcase
end

pro idp3_clipmipsmedpar, event

@idp3_errors

  ; Pop up a widget so the user can enter a file name, then go save
  ; the display image in that file (with an appropriate header).
  if(XRegistered("idp3_clipmipsmedpar")) then return
  Widget_Control, event.top, Get_UValue = info

  Widget_Control, info.idp3Window, Get_UValue=cinfo
  path = cinfo.savepath

  title      = 'IDP3  clip median task'
  cmedbase    = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     /Modal, XOffset=info.wpos.mpwp[0], $
			     YOffset = info.wpos.mpwp[1])
  med1base = Widget_Base (cmedbase, /Row)
  label      = Widget_Label (med1base, Value='Output file name:') 
  selectfile = Widget_Text  (med1base, Value = ' ', XSize = 80, /Edit)
  med2base = Widget_Base (cmedbase, /Row)
  label2     = Widget_Label (med2base, Value='                             ')
  browseButton = Widget_Button(med2base, Value = ' Browse ')
  label3     = Widget_Label (med2base, Value = '     ')
  cancelButton = Widget_Button(med2base, Value = ' Cancel ')

  cmedianinfo = {selectfile    :     selectfile,   $
		browseButton  :     browseButton, $
		cancelButton  :     cancelButton, $
		info          :     info          }

  Widget_Control, cmedbase, set_uvalue = cmedianinfo
  Widget_Control, cmedbase, /Realize

  XManager, "idp3_clipmipsmedpar", cmedbase, Event_Handler = "clipmipsmedian_ev"
          
end
