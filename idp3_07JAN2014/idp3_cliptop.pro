pro Cliptop_Event, event
@idp3_errors

  Widget_Control, event.top, Get_UValue = clipinfo

  imptr = (*clipinfo.tinfo.images)[clipinfo.tinfo.moveimage]

  case event.id of

  clipinfo.clipmaxtext: begin
    Widget_Control,clipinfo.clipmaxtext,Get_Value=clipmax
    end

  clipinfo.cmaxvaltext: begin
    Widget_Control,clipinfo.cmaxvaltext,Get_Value=cmaxval
    end

  clipinfo.clipapply: begin
    Widget_Control,clipinfo.clipmaxtext,Get_Value=clipmax
    (*imptr).clipmax = float(clipmax[0])
    Widget_Control,clipinfo.cmaxvaltext,Get_Value=cmaxval
    (*imptr).cmaxval = float(cmaxval[0])
    (*imptr).cliptop = 1
    Widget_Control, clipinfo.tinfo.idp3Window, Set_UValue = clipinfo.tinfo
    end

  clipinfo.clipdone: begin
    Widget_Control, event.top, /Destroy
    end
  endcase
end

pro Idp3_Cliptop, event
@idp3_errors

  Widget_Control, event.top, Get_UValue = spinfo
  Widget_Control, spinfo.info.idp3Window, Get_UValue = tinfo
  imptr = (*tinfo.images)[tinfo.moveimage]

  clipmax = string((*imptr).clipmax)
  cmaxval = string((*imptr).cmaxval)
  xo = tinfo.wpos.cfwp[0]
  yo = tinfo.wpos.cfwp[1]
  
  clipitop = Widget_Base(xoffset=xo, yoffset=yo, $
		 /Column, Title='IDP3 Clip Image Max')
  c1label = Widget_Label (clipitop, Value=$
     'Maximum Value           Replacement Value')
  c1rowbase = Widget_Base(clipitop, /Row)
  clipmaxtext = Widget_Text (c1rowbase, Value = clipmax, XSize = 20, /Edit)
  cmaxvaltext = Widget_Text (c1rowbase, Value = cmaxval, XSize = 20, /Edit)
  c2rowbase = Widget_Base(clipitop, /Row)
  clipapply = Widget_Button(c2rowbase, Value = 'Apply')
  clipdone = Widget_Button(c2rowbase, Value = 'Done')
  clipinfo = { clipmaxtext : clipmaxtext, $
	       cmaxvaltext : cmaxvaltext, $
	       clipapply   : clipapply,   $
	       clipdone    : clipdone,    $
	       tinfo       : tinfo        }

  Widget_Control, clipitop, set_uvalue = clipinfo

  Widget_Control,clipitop,/Realize
  Xmanager,'clipimax',clipitop, /No_Block, $
      Event_Handler='Cliptop_Event'

end
