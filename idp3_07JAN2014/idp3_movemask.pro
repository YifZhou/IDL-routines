
pro MoveMask_Done, event
  ; Kill the move-rod widget.

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=mminfo
  Widget_Control, mminfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.mmwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.mmwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, mminfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end


pro MoveMask_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=mminfo
  Widget_Control, mminfo.info.idp3Window, Get_UValue=info
  mminfo.info = info
  Widget_Control, event.top, Set_UValue=mminfo

  case event.id of
    mminfo.mmmvAmountField: begin
      ; Don't do anything here.
      end
    mminfo.mmmvUpButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      if temp ge 0 then begin
        (*info.roi).msk_yoff = (*info.roi).msk_yoff + temp
        Widget_Control, mminfo.mmyoffField, Set_Value=(*info.roi).msk_yoff
      endif
      end
    mminfo.mmmvLeftButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      if temp ge 0 then begin
	(*info.roi).msk_xoff = (*info.roi).msk_xoff - temp
        Widget_Control, mminfo.mmxoffField, Set_Value=(*info.roi).msk_xoff
      endif
      end
    mminfo.mmmvRightButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      temp=temp[0]
      if temp ge 0 then begin
	(*info.roi).msk_xoff = (*info.roi).msk_xoff + temp
        Widget_Control, mminfo.mmxoffField, Set_Value=(*info.roi).msk_xoff
      endif
      end
    mminfo.mmmvDownButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      temp=temp[0]
      if temp ge 0 then begin
	(*info.roi).msk_yoff = (*info.roi).msk_yoff - temp
        Widget_Control, mminfo.mmyoffField, Set_Value=(*info.roi).msk_yoff
      endif
      end
    mminfo.mmxoffField: begin
      Widget_Control, mminfo.mmxoffField, Get_Value = temp
      temp = temp[0]
      (*info.roi).msk_xoff = temp
      end
    mminfo.mmyoffField: begin
      Widget_Control, mminfo.mmyoffField, Get_Value = temp
      temp = temp[0]
      (*info.roi).msk_yoff = temp
      end
    mminfo.mmalignButton: begin
      (*info.roi).msk_xoff = (*info.roi).roixorig
      (*info.roi).msk_yoff = (*info.roi).roiyorig
      Widget_Control, mminfo.mmxoffField, Set_Value=(*info.roi).msk_xoff
      Widget_Control, mminfo.mmyoffField, Set_Value=(*info.roi).msk_yoff
      end
  else:
  endcase

  Widget_Control, event.top, Set_UValue=mminfo
  Widget_Control, mminfo.info.idp3Window, Set_UValue=info

  roi_display,info

end

pro Idp3_MoveMask, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_movemask')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  if (*info.roi).msk ne 1 then return

  mmWindow = Widget_base(Title = 'IDP3-ROI Move Mask', /Column, $
			 Group_Leader = event.top, /Base_Align_Center, $
			 XOffset = info.wpos.mmwp[0], $
			 YOffset = info.wpos.mmwp[1])

  mmoffLabel = Widget_Label(mmWindow, Value='Mask Shifts:')
  mmoffbase = Widget_Base(mmWindow, /row)
  mmxoffField = CW_Field(mmoffbase, Value=(*info.roi).msk_xoff, xsize=8, $
		/Integer, Title='   X: ', /Return_Events, UValue='mxoff')
  mmyoffField = CW_Field(mmoffbase, Value=(*info.roi).msk_yoff, xsize=8, $
		/Integer, Title='   Y: ', /Return_Events, UValue='myoff')

  mmmvAmountField=CW_Field(mmWindow, Value=1, XSize=4, /Integer, $
			       Title='Move Amt:', /Return_Events, $
			       UValue='mmmoveamount')

  space44         = Widget_Label (mmWindow,Value='  ')

  mmmvButtonBase1 = Widget_Base  (mmWindow,/row,/Align_Center)
  mmmvButtonBase2 = Widget_Base  (mmWindow,/row,/Align_Center)
  mmmvButtonBase3 = Widget_Base  (mmWindow,/row,/Align_Center)
  mmmvUpButton    = Widget_Button(mmmvButtonBase1,UValue='mmmvup',Value='^')
  mmmvLeftButton  = Widget_Button(mmmvButtonBase2,UValue='mmmvleft',Value='<')
  space2          = Widget_Label (mmmvButtonBase2,Value='  ')
  mmmvRightButton = Widget_Button(mmmvButtonBase2,UValue='mmmvright',Value='>')
  mmmvDownButton  = Widget_Button(mmmvButtonBase3,UValue='mmmvdown',Value='v')

  space55         = Widget_Label (mmWindow,Value='  ')

  mmalignButton     = Widget_Button(mmWindow,Value='Align with ROI')
  mmdoneButton    = Widget_Button(mmWindow,Value='Done', $
				  Event_Pro='movemask_done')

  mminfo = { mmmvAmountField  : mmmvAmountField,   $
	     mmxoffField      : mmxoffField,       $
	     mmyoffField      : mmyoffField,       $
             mmmvUpButton     : mmmvUpButton,      $
             mmmvLeftButton   : mmmvLeftButton,    $
             mmmvRightButton  : mmmvRightButton,   $
             mmmvDownButton   : mmmvDownButton,    $
	     mmalignButton    : mmalignButton,     $
	     info             : info               }

  Widget_Control, mmWindow, Set_UValue=mminfo

  Widget_Control, mmWindow, /Realize
  Widget_Control, info.idp3Window, Set_UValue=info

  XManager, 'idp3_movemask', mmWindow, /No_Block,  $
	    Event_Handler='Movemask_Event'

  Widget_Control, info.idp3Window, Set_UValue=info
end
