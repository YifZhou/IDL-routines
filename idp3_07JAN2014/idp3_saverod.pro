
pro saverod_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=saverodinfo
  Widget_Control, saverodinfo.info.idp3Window, Get_UValue=info

  case event.id of

    saverodinfo.selectfile: begin
      Widget_Control, saverodinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)

      info.savepath = disk + path

      ; Get size of roi.
      roixsize = (*saverodinfo.info.roi).roixsize
      roiysize = (*saverodinfo.info.roi).roiysize

      ; Create mask array.
      themask = ptr_new(intarr(roixsize,roiysize))
      (*themask)[*,*] = 1
      (*themask)(*(*saverodinfo.info.roi).roddmask) = 0

      ; Save as FITS file.
      ua_fits_write,filename,(*themask)

      ; Delete Mask array.
      ptr_free,themask

      Widget_Control, event.top, /Destroy
      end  
  endcase
end


pro idp3_saverod, event

@idp3_errors

  if(XRegistered("idp3_saverod")) then return
  Widget_Control, event.top, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Save ROD'
  savebase   = Widget_Base  (Title = title, /Row, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  label      = Widget_Label (savebase, Value='Output file name:') 
  selectfile = Widget_Text  (savebase, Value = path, XSize = 80, /Edit)

  saverodinfo = {selectfile    :     selectfile, $
		info          :     info        }

  Widget_Control, savebase, set_uvalue = saverodinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_saverod", savebase, Event_Handler = "saverod_ev"
          
end
