pro Clipbottom_Event, event
@idp3_errors

  Widget_Control, event.top, Get_UValue = clipinfo

  imptr = (*clipinfo.tinfo.images)[clipinfo.tinfo.moveimage]

  case event.id of

  clipinfo.clipmintext: begin
    Widget_Control,clipinfo.clipmintext,Get_Value=clipmin
    end

  clipinfo.cminvaltext: begin
    Widget_Control,clipinfo.cminvaltext,Get_Value=cminval
    end

  clipinfo.clipapply: begin
    Widget_Control,clipinfo.clipmintext,Get_Value=clipmin
    (*imptr).clipmin = float(clipmin[0])
    Widget_Control,clipinfo.cminvaltext,Get_Value=cminval
    (*imptr).cminval = float(cminval[0])
    (*imptr).clipbottom = 1
    Widget_Control, clipinfo.tinfo.idp3Window, Set_UValue=clipinfo.tinfo
    end

  clipinfo.clipdone: begin
    Widget_Control, event.top, /Destroy
    end
  endcase
end

pro Idp3_Clipbottom, event
@idp3_errors

  Widget_Control, event.top, Get_UValue = spinfo
  Widget_Control, spinfo.info.idp3Window, Get_UValue = tinfo
  imptr = (*tinfo.images)[tinfo.moveimage]
  clipmin = string((*imptr).clipmin)
  cminval = string((*imptr).cminval)
 
  xo = tinfo.wpos.cfwp[0]
  yo = tinfo.wpos.cfwp[1] + 120

  clipimin = Widget_Base(xoffset=xo, yoffset=yo, /Column, $
	     Title='IDP3 Clip Image Min')
	     ; Title='Clip Image Min' $
	     ; group_leader = event.top)
  c1label = Widget_Label (clipimin, Value=$
     'Minimum Value           Replacement Value')
  c1rowbase = Widget_Base(clipimin, /Row)
  clipmintext = Widget_Text (c1rowbase, Value = clipmin, XSize = 20, /Edit)
  cminvaltext = Widget_Text (c1rowbase, Value = cminval, XSize = 20, /Edit)
  c2rowbase = Widget_Base(clipimin, /Row)
  clipapply = Widget_Button(c2rowbase, Value = 'Apply')
  clipdone = Widget_Button(c2rowbase, Value = 'Done')
  clipinfo = { clipmintext : clipmintext, $
	       cminvaltext : cminvaltext, $
	       clipapply   : clipapply,   $
	       clipdone    : clipdone,    $
	       tinfo       : tinfo        }

  Widget_Control, clipimin, set_uvalue = clipinfo

  Widget_Control, clipimin, /Realize
  Xmanager, 'clipimin', clipimin, /No_Block, $
       Event_Handler='Clipbottom_Event'

end
