pro getbase_event, event 

@idp3_errors

 Widget_Control, event.top, Get_UValue=getinfo
 case event.id of

   getinfo.get1Field: begin
     Widget_Control, getinfo.get1Field, Get_Value = temp
   end
   getinfo.get2Field: begin
     Widget_Control, getinfo.get2Field, Get_Value = temp
   end
   getinfo.get3Field: begin
     Widget_Control, getinfo.get2Field, Get_Value = temp
   end
   getinfo.acceptButton: begin
     Widget_Control, getinfo.get1Field, Get_Value = temp1
     (*getinfo.ptr).text1 = temp1[0]
     if getinfo.vals ge 2 then begin
       Widget_Control, getinfo.get2Field, Get_Value = temp2
       (*getinfo.ptr).text2 = temp2[0]
     endif
     if getinfo.vals eq 3 then begin
       Widget_Control, getinfo.get3Field, Get_Value = temp3
       (*getinfo.ptr).text3 = temp3[0]
     endif
     (*getinfo.ptr).cancel = 0
     Widget_Control, event.top, /Destroy
   end
   getinfo.cancelButton: begin
;     (*getinfo.ptr).cancel = 1
     Widget_Control, event.top, /Destroy
   end
 endcase
end

function idp3_getvals, title, ds1, ds2=ds2, ds3=ds3, lab1=lab1, lab2=lab2, $
		   lab3=lab3, groupleader=groupleader, ws=ws, xp=xp, yp=yp, $
		   cancel=cancel

  Catch, theError
  if theError ne 0 then begin
    Catch, /Cancel
    cancel = 1
    return, ''
  endif

  if n_elements(ws) eq 0 then ws = 8
  if n_elements(xp) eq 0 then xp = 0
  if n_elements(yp) eq 0 then yp = 0
  vals = 1

  if n_elements(groupleader) gt 0 then $
    getvalbase = widget_base(Title=title, /column, group_leader=groupleader, $
		/modal, xoffset=xp, yoffset=yp) $
    else getvalbase = widget_base(Title=title, /column, xoffset=xp, yoffset=yp)

  gettbase = Widget_Base(getvalbase, /row)
  if n_elements(lab1) gt 0 then glab1 = Widget_Label(gettbase, Value=lab1)
  get1Field =  Widget_Text (gettbase, Value=ds1, XSize=ws, /Edit)
  if n_elements(ds2) gt 0 then begin
    if n_elements(lab2) gt 0 then glab2 = Widget_Label(gettbase, Value=lab2)
    get2Field =  Widget_Text (gettbase, Value=ds2, XSize=ws, /Edit)
    vals = 2
  endif else get2Field = 0L
  if n_elements(ds3) gt 0 then begin
    if n_elements(lab3) gt 0 then glab3 = Widget_label(gettbase, Value=lab3)
    get3Field = Widget_Text(gettbase, Value=ds3, XSize=ws, /Edit)
    vals = 3
  endif else get3Field = 0L
  getybase = Widget_Base(getvalbase, /row)
  cancelButton = Widget_Button(getybase, Value='Cancel')
  space = Widget_Label(getybase, Value='  ')
  acceptButton = Widget_Button(getybase, Value='Accept')
 
  ptr = ptr_new({text1:' ', text2:' ', text3:' ', cancel:1})

  getinfo = {ptr             :  ptr,          $
	     vals            :  vals,         $
	     get1Field       :  get1Field,    $
	     get2Field       :  get2Field,    $
	     get3Field       :  get3Field,    $
	     cancelButton    :  cancelButton, $
	     acceptButton    :  acceptButton  }

  Widget_Control, getvalbase, Set_UValue=getinfo, /no_copy

  Widget_Control, getvalbase, /Realize
  XManager, 'idp3_getvals', getvalbase, Event_Handler='getbase_event'

  if vals eq 1 then begin
    res = (*ptr).text1
  endif else begin
    if vals eq 2 then begin
      res = strarr(2)
      res[0] = (*ptr).text1
      res[1] = (*ptr).text2
    endif else begin
      res= strarr(3)
      res[0] = (*ptr).text1
      res[1] = (*ptr).text2
      res[2] = (*ptr).text3
    endelse
  endelse
  cancel = (*ptr).cancel
  ptr_free, ptr
  return, res
end

