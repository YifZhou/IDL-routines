
pro MoveRod_Done, event
  ; Kill the move-rod widget.

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=mminfo
  Widget_Control, mminfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.mmwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.mmwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, mminfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end


pro MoveRod_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=mminfo
  Widget_Control, mminfo.info.idp3Window, Get_UValue=info
  mminfo.info = info
  Widget_Control, event.top, Set_UValue=mminfo

  ; Extract information from the ROI structure.  The 'info' structure
  ; contains a pointer to the ROI structure.  The size of the roi
  ; and the lower left and upper right corner pixels are saved in
  ; local variables.

  roixsize = (*info.roi).roixsize
  roiysize = (*info.roi).roiysize
  x1 = (*info.roi).roixorig
  y1 = (*info.roi).roiyorig
  x2 = (*info.roi).roixend
  y2 = (*info.roi).roiyend


  case event.id of
    mminfo.mmmvAmountField: begin
      ; Don't do anything here.
      end
    mminfo.mmmvUpButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      temp=temp[0]
      if temp gt 0 then begin

	; Make a temporary array and a pointer to it, set all pixels to one.

	newmask = ptr_new(intarr(roixsize,roiysize))
	(*newmask)[*,*] = 1

	; "newmask" is a pointer to an integer array.
	; First, dereference the pointer so we have just an array (*newmask).
	; Then, subscript this array with the array of indices pointed to by
	; "roddmask". "roddmask" is contained in the structure pointed to by
	; "roi", which is contained in the structure "info".

	; I keep two set of indices associated with the "Region of Disinterest",
	; the indices of all the masked pixels and the indices of all the
	; unmasked pixels.  Both of these arrays are used when doing the 'mask'
	; stuff.

	(*newmask)[*(*info.roi).roddmask] = 0

	; Shift newmask "move-amount" up.

	(*newmask) = shift((*newmask),0,temp)

	; Set the mask bits to one in the area out of which the mask has moved,
	; about which we have no information. (unmask them)

	(*newmask)[*,0:temp-1] = 1

        ; Free the old mask arrays.

	ptr_free,(*info.roi).rodmask
	ptr_free,(*info.roi).roddmask

	; Create the new index arrays and create pointers to them.

	(*info.roi).rodmask = ptr_new( $
	      where(congrid((*newmask),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
	(*info.roi).roddmask = ptr_new(where((*newmask) ne 1))

	; Free the temporary array, "newmask"

	ptr_free,newmask
      endif
      end
    mminfo.mmmvLeftButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      temp=temp[0]
      if temp gt 0 then begin
	newmask = ptr_new(intarr(roixsize,roiysize))
	(*newmask)[*,*] = 1
	(*newmask)[*(*info.roi).roddmask] = 0
	(*newmask) = shift((*newmask),-temp,0)
	(*newmask)[roixsize-temp:roixsize-1,*] = 1
	ptr_free,(*info.roi).rodmask
	ptr_free,(*info.roi).roddmask
	(*info.roi).rodmask = ptr_new( $
	      where(congrid((*newmask),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
	(*info.roi).roddmask = ptr_new(where((*newmask) ne 1))
	ptr_free,newmask
      endif
      end
    mminfo.mmmvRightButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      temp=temp[0]
      if temp gt 0 then begin
	newmask = ptr_new(intarr(roixsize,roiysize))
	(*newmask)[*,*] = 1
	(*newmask)[*(*info.roi).roddmask] = 0
	(*newmask) = shift((*newmask),temp,0)
	(*newmask)[0:temp-1,*] = 1
	ptr_free,(*info.roi).rodmask
	ptr_free,(*info.roi).roddmask
	(*info.roi).rodmask = ptr_new( $
	      where(congrid((*newmask),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
	(*info.roi).roddmask = ptr_new(where((*newmask) ne 1))
	ptr_free,newmask
      endif
      end
    mminfo.mmmvDownButton: begin
      Widget_Control, mminfo.mmmvAmountField, Get_Value = temp
      temp=temp[0]
      if temp gt 0 then begin
	newmask = ptr_new(intarr(roixsize,roiysize))
	(*newmask)[*,*] = 1
	(*newmask)[*(*info.roi).roddmask] = 0
	(*newmask) = shift((*newmask),0,-temp)
	(*newmask)[*,roiysize-temp:roiysize-1] = 1
	ptr_free,(*info.roi).rodmask
	ptr_free,(*info.roi).roddmask
	(*info.roi).rodmask = ptr_new( $
	      where(congrid((*newmask),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
	(*info.roi).roddmask = ptr_new(where((*newmask) ne 1))
	ptr_free,newmask
      endif
      end
    mminfo.flipvButton: begin
      newmask = ptr_new(intarr(roixsize,roiysize))
      (*newmask)[*,*] = 1
      (*newmask)[*(*info.roi).roddmask] = 0
      (*newmask) = reverse((*newmask),2)
      ptr_free,(*info.roi).rodmask
      ptr_free,(*info.roi).roddmask
      (*info.roi).rodmask = ptr_new( $
	    where(congrid((*newmask),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
      (*info.roi).roddmask = ptr_new(where((*newmask) ne 1))
      ptr_free,newmask
      end
    mminfo.fliphButton: begin
      newmask = ptr_new(intarr(roixsize,roiysize))
      (*newmask)[*,*] = 1
      (*newmask)[*(*info.roi).roddmask] = 0
      (*newmask) = reverse((*newmask),1)
      ptr_free,(*info.roi).rodmask
      ptr_free,(*info.roi).roddmask
      (*info.roi).rodmask = ptr_new( $
	    where(congrid((*newmask),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
      (*info.roi).roddmask = ptr_new(where((*newmask) ne 1))
      ptr_free,newmask
      end
  else:
  endcase

  Widget_Control, event.top, Set_UValue=mminfo
  Widget_Control, mminfo.info.idp3Window, Set_UValue=info

  roi_display,info

end


pro Idp3_MoveRod, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_movemask')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  if (*info.roi).rod ne 1 then return

  mmWindow = Widget_base(Title = 'IDP3 Move ROD', /Column, $
			 Group_Leader = event.top, $
			 XOffset = info.wpos.mmwp[0], $
			 YOffset = info.wpos.mmwp[1])

  mmmvAmountBase =Widget_Base(mmWindow,/column,/Align_Center)
  mmmvAmountLabel=Widget_Label(mmmvAmountBase,Value='Move Amount',/Align_Center)
  mmmvamst       =string(format='(i8)',1)
  mmmvAmountField=Widget_Text(mmmvAmountBase,Value=mmmvamst,XSize=8,/Editable, $
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

  flipvButton     = Widget_Button(mmWindow,Value='Flip Vert')
  fliphButton     = Widget_Button(mmWindow,Value='Flip Horiz')
  mmdoneButton    = Widget_Button(mmWindow,Value='Done', $
				  Event_Pro='moverod_done')

  mminfo = { mmmvAmountField  : mmmvAmountField,   $
             mmmvUpButton     : mmmvUpButton,      $
             mmmvLeftButton   : mmmvLeftButton,    $
             mmmvRightButton  : mmmvRightButton,   $
             mmmvDownButton   : mmmvDownButton,    $
	     flipvButton      : flipvButton,       $
	     fliphButton      : fliphButton,       $
	     info             : info               }

  Widget_Control, mmWindow, Set_UValue=mminfo

  Widget_Control, mmWindow, /Realize
  Widget_Control, info.idp3Window, Set_UValue=info

  XManager, 'idp3_moverod', mmWindow, /No_Block,  $
	    Event_Handler='MoveRod_Event'

  Widget_Control, info.idp3Window, Set_UValue=info
end

