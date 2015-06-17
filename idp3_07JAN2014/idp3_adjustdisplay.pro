pro AdjustDisplay_Done, event

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=adinfo
  Widget_Control, adinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.adwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.adwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, adinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end

pro AdjustDisplay_Help, event
  Widget_Control, event.top, Get_UValue=adinfo
  Widget_Control, adinfo.info.idp3Window, Get_UValue = info
  if info.pdf_viewer eq '' then begin
    tmp = idp3_findfile('idp3_adjustdisplay.hlp')
    xdisplayfile, tmp
  endif else begin
    tmp = idp3_findfile('idp3_adjustdisplay.pdf')
    str = info.pdf_viewer + ' ' + tmp
    if !version.os eq 'darwin' then str = 'open -a ' + str
    spawn, str
  endelse
end

pro AdjustDisplay_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=adinfo
  Widget_Control, adinfo.info.idp3Window, Get_UValue=tempinfo
  adinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=adinfo

  case event.id of
    adinfo.plotminField: begin
      ; Just read the value and save it.
      Widget_Control, adinfo.plotminField, Get_Value = temp1
      adinfo.info.Z1 = temp1
      adinfo.info.autoscale = 0
      Widget_Control, adinfo.autoButton, Set_Value = adinfo.info.autoscale 
      Widget_Control, adinfo.plotmaxField, Get_Value = temp2
      adinfo.info.Z2 = temp2
      if XRegistered('idp3_roidisplay') then begin
	Widget_Control, adinfo.info.rdbase, Get_UValue = temprdinfo
	Widget_Control, temprdinfo.plotminField, Set_Value = temp1
	Widget_Control, temprdinfo.plotmaxField, Set_Value = temp2
	if adinfo.info.zoomflux eq 0 then begin
	  rz1 = temp1 
	  rz2 = temp2 
        endif else begin
	  case adinfo.info.imscl of
	    0: begin
	       rz1 = temp1 / ((*adinfo.info.roi).roizoom) ^ 2
	       rz2 = temp2 / ((*adinfo.info.roi).roizoom) ^ 2
	       end
	    1: begin 
	       rz1 = temp1 - alog10((*adinfo.info.roi).roizoom ^ 2)
	       rz2 = temp2 - alog10((*adinfo.info.roi).roizoom ^ 2)
	       end
	    2: begin
	       rz1 = temp1 / (*adinfo.info.roi).roizoom
	       rz2 = temp2 / (*adinfo.info.roi).roizoom
	       end
	    else:
          endcase
        endelse
        Widget_Control, temprdinfo.rplotminField, Set_Value = rz1
        Widget_Control, temprdinfo.rplotmaxField, Set_Value = rz2
      endif
      end

    adinfo.plotmaxField: begin
      Widget_Control, adinfo.plotmaxField, Get_Value = temp2
      adinfo.info.Z2 = temp2
      adinfo.info.autoscale = 0
      Widget_Control, adinfo.autoButton, Set_Value = adinfo.info.autoscale
      Widget_Control, adinfo.plotminField, Get_Value = temp1
      adinfo.info.Z1 = temp1
      if XRegistered('idp3_roidisplay') then begin
	Widget_Control, adinfo.info.rdbase, Get_UValue = temprdinfo
	Widget_Control, temprdinfo.plotminField, Set_Value = temp1
	Widget_Control, temprdinfo.plotmaxField, Set_Value = temp2
	if adinfo.info.zoomflux eq 0 then begin
	  rz1 = temp1 
	  rz2 = temp2 
        endif else begin
	  case adinfo.info.imscl of
	    0: begin
	       rz1 = temp1 / ((*adinfo.info.roi).roizoom) ^ 2
	       rz2 = temp2 / ((*adinfo.info.roi).roizoom) ^ 2
	       end
	    1: begin 
	       rz1 = temp1 - alog10((*adinfo.info.roi).roizoom ^ 2)
	       rz2 = temp2 - alog10((*adinfo.info.roi).roizoom ^ 2)
	       end
	    2: begin
	       rz1 = temp1 / (*adinfo.info.roi).roizoom
	       rz2 = temp2 / (*adinfo.info.roi).roizoom
	       end
	    else:
          endcase
        endelse
        Widget_Control, temprdinfo.rplotminField, Set_Value = rz1
        Widget_Control, temprdinfo.rplotmaxField, Set_Value = rz2
      endif
      end

    adinfo.dispbiasField: begin
      Widget_Control, adinfo.dispbiasField, Get_Value = temp
      adinfo.info.Dispbias = temp[0]
      end

    adinfo.sxoffField: begin
      Widget_Control, adinfo.sxoffField, Get_Value = temp
      adinfo.info.sxoff = temp[0]
      end

    adinfo.syoffField: begin
      Widget_Control, adinfo.syoffField, Get_Value = temp
      adinfo.info.syoff = temp[0]
      end

    adinfo.colorButton: begin
      clrs = adinfo.info.color_bits
      xloadct,group=adinfo.info.idp3Window, bottom=clrs, updatecallback='idp3_refresh', $
               updatecbdata=tempinfo
      if adinfo.info.color_bits gt 0 then color6
      end
;    adinfo.lcolorButton: begin
;      if XRegistered('XCOLORS:Load Color Tables') then begin
;        str = 'XColors already loaded'
;	idp3_updatetxt, adinfo.info, str
;      endif else begin
;        proname = 'idp3_refresh'
;        xcolors, NotifyPro=proname, Data=tempinfo, $
;		 group_leader=adinfo.info.idp3Window, /Drag
;        if adinfo.info.color_bits gt 0 then color6
;      endelse
;      end

    adinfo.sButtons: begin
      ; scale display toggle.
      sclmethod = event.value
      tmp1 = adinfo.info.Z1
      tmp2 = adinfo.info.Z2
      case sclmethod of
      0: begin
	if adinfo.info.imscl eq 1 then begin
	  tmp1 = 10.0^tmp1
	  tmp2 = 10.0^tmp2
        endif else if adinfo.info.imscl eq 2 then begin
	  tmp1 = tmp1 ^ 2
	  tmp2 = tmp2 ^ 2
        endif 
        adinfo.info.Z1 = tmp1
	adinfo.info.Z2 = tmp2
	Widget_Control, adinfo.plotminField, Set_Value = tmp1
	Widget_Control, adinfo.plotmaxField, Set_Value = tmp2
        if XRegistered('idp3_roidisplay') then begin
	  Widget_Control, adinfo.info.rdbase, Get_UValue = temprdinfo
	  Widget_Control, temprdinfo.plotminField, Set_Value = tmp1
	  Widget_Control, temprdinfo.plotmaxField, Set_Value = tmp2
	  if adinfo.info.zoomflux eq 1 then begin
	    tmp1 = tmp1 / (*adinfo.info.roi).roizoom ^ 2
	    tmp2 = tmp2 / (*adinfo.info.roi).roizoom ^ 2
          endif
	  Widget_Control, temprdinfo.rplotminField, Set_Value = tmp1
	  Widget_Control, temprdinfo.rplotmaxField, Set_Value = tmp2
        endif
        adinfo.info.imscl = sclmethod
	end
      1: begin
	if adinfo.info.imscl eq 2 then begin
	  tmp1 = tmp1 ^ 2
	  tmp2 = tmp2 ^ 2
        endif
	tmp = tmp1 > 0.0000001
	tmp1 = alog10(tmp)
	adinfo.info.Z1 = tmp1
	Widget_Control, adinfo.plotminField, Set_Value = tmp1
	tmp = tmp2 > 0.0000001
	tmp2 = alog10(tmp)
	adinfo.info.Z2 = tmp2
	Widget_Control, adinfo.plotmaxField, Set_Value = tmp2
	if XRegistered('idp3_roidisplay') then begin
	  Widget_Control, adinfo.info.rdbase, Get_UValue = temprdinfo
	  Widget_Control, temprdinfo.plotminField, Set_Value = tmp1
	  Widget_Control, temprdinfo.plotmaxField, Set_Value = tmp2
	  if adinfo.info.zoomflux eq 1 then begin
	    tmp1 = tmp1 - alog10((*adinfo.info.roi).roizoom ^ 2)
	    tmp2 = tmp2 - alog10((*adinfo.info.roi).roizoom ^ 2)
          endif
	  Widget_Control, temprdinfo.rplotminField, Set_Value = tmp1
	  Widget_Control, temprdinfo.rplotmaxField, Set_Value = tmp2
        endif
        adinfo.info.imscl = sclmethod
        end
      2: begin
        if adinfo.info.imscl eq 1 then begin
	  tmp1 = 10.0^tmp1
	  tmp2 = 10.0^tmp2
        endif
        tmp = tmp1 > 0.0
        tmp1 = sqrt(tmp)
        adinfo.info.Z1 = tmp1
        Widget_Control, adinfo.plotminField, Set_Value = tmp1
        tmp = tmp2 > 0.0
        tmp2 = sqrt(tmp)
        adinfo.info.Z2 = tmp2
        Widget_Control, adinfo.plotmaxField, Set_Value = tmp2
        if XRegistered('idp3_roidisplay') then begin
	  Widget_Control, adinfo.info.rdbase, Get_UValue = temprdinfo
	  Widget_Control, temprdinfo.plotminField, Set_Value = tmp1
	  Widget_Control, temprdinfo.plotmaxField, Set_Value = tmp2
	  if adinfo.info.zoomflux eq 1 then begin
	    tmp1 = tmp1 / (*adinfo.info.roi).roizoom
	    tmp2 = tmp2 / (*adinfo.info.roi).roizoom
          endif
	  Widget_Control, temprdinfo.rplotminField, Set_Value = tmp1
	  Widget_Control, temprdinfo.rplotmaxField, Set_Value = tmp2
        endif
        adinfo.info.imscl = sclmethod
        end
      else:
    endcase
    end

    adinfo.redispButton: begin
      ; Clear the screen first, then drop through to redisplay.
      dxs = adinfo.info.drawxsize
      dys = adinfo.info.drawysize
      clearim = ptr_new(bytarr(dxs,dys))
      tv,*clearim
      ptr_free,clearim
      if adinfo.info.color_bits gt 0 then color6
      end

    adinfo.autoButton: begin
      ; Toggle auto-scale.
      Widget_Control, adinfo.autoButton, Get_Value = barray
      if barray(0) eq 0 then begin
	adinfo.info.AutoScale = 0
      endif else begin
	adinfo.info.AutoScale = 1
      endelse
      end

  else:
  endcase

  ; Make sure we've got a fresh copy of the 'info' structure to pass to display.
  Widget_Control, event.top, Set_UValue=adinfo
  Widget_Control, adinfo.info.idp3Window, Set_UValue=adinfo.info

  ; Update the display.
  idp3_display,adinfo.info

  ; Make sure we save the updated 'info' structure back into this widget's
  ; 'adinfo' structure.
  Widget_Control, adinfo.info.idp3Window, Get_UValue=tempinfo
  adinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=adinfo

end


pro Idp3_AdjustDisplay, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_adjustdisplay')) then return

  Widget_Control, event.top, Get_UValue=info

  adWindow = Widget_base(Title = 'IDP3 Adjust Display Window', /Column, $
			 Group_Leader = event.top, /Grid_Layout, $
			 XOffset = info.wpos.adwp[0], $
			 YOffset = info.wpos.adwp[1])
  zBase = Widget_Base(adWindow,/Row)
  plotminField = cw_field(zBase,value=info.Z1,title='Display Min', $
                    uvalue='plotmin', xsize=10, /Return_Events, /Floating)
  plotmaxField = cw_field(zBase,value=info.Z2,title='Max', $
                    uvalue='plotmax', xsize=10, /Return_Events, /Floating)
  autoButton  = cw_bgroup(zBase,['Auto'], row = 1,  $
                         set_value = [info.AutoScale], /nonexclusive)
  lBase = Widget_Base(adWindow,/Row)
  snames = ['Linear', 'Log', 'Square Root']
  sButtons = cw_bgroup(lbase, snames, row=1, label_left='Scaling:', $
    uvalue='sbutton', set_value=info.imscl, exclusive=1, /no_release)
  bBase = Widget_Base(adWindow,/Row)
  dispbiasField = cw_field(bBase,value=info.Dispbias,title=$
		 'Display Bias (linear units):', $
		  uvalue='dispbias',xsize=10, /Return_Events, /Floating)
  oBase = Widget_Base(adWindow,/Row)
  sofflabel = Widget_Label(oBase,value = 'Screen: ')
  sxoffField = cw_field(oBase,value=info.sxoff,title='xoff:', $
                        uvalue='asxoff', xsize=6, /Return_Events)
  syoffField = cw_field(oBase,value=info.syoff,title='yoff:', $
                        uvalue='asyoff', xsize=6, /Return_Events)
  o2Base = Widget_Base(adWindow,/Row)
  colorButton = Widget_Button(o2Base, Value='Color')
;  lcolorButton = Widget_Button(o2Base, Value='Color (Linux)')
  redispButton = Widget_Button(o2Base, Value='Redisplay')
  helpButton = Widget_Button(o2Base, Value='Help', $
	       Event_Pro='AdjustDisplay_Help')
  doneButton = Widget_Button(o2Base, Value='Done', $
	       Event_Pro='AdjustDisplay_Done')

  adinfo = { plotminField   : plotminField,  $
             plotmaxField   : plotmaxField,  $
	     dispbiasField  : dispbiasField, $
             sxoffField     : sxoffField,    $
             syoffField     : syoffField,    $
             colorButton    : colorButton,   $
;	     lcolorButton   : lcolorButton,  $
	     sButtons       : sButtons,      $
             autoButton     : autoButton,    $
             redispButton   : redispButton,  $
	     info           : info           }

  Widget_Control, adWindow, Set_UValue=adinfo

  ; Remember the main base widget ID so we can update this widget from
  ; elsewhere.
  info.adBase = adWindow
  Widget_Control, info.idp3Window, Set_UValue=info

  Widget_Control, adWindow, /Realize
  XManager, 'idp3_adjustdisplay', adWindow, /No_Block,  $
	    Event_Handler='AdjustDisplay_Event'

  Widget_Control, info.idp3Window, Set_UValue=info
end


