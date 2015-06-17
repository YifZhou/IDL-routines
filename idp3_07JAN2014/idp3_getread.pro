pro getbase_event, event 

COMMON getrd, getvalue, val

 Widget_Control, getvalue, Get_Value = temp
 val = temp[0]
 Widget_Control, event.top, /Destroy

end

pro idp3_getread, title, wsiz, defstr, value

COMMON getrd, getvalue, val

  getreadbase = widget_base(Title=title, xoffset=400, yoffset=400, /Column)
  getvalue =  Widget_Text (getreadbase, Value=defstr, XSize=wsiz, /Edit)
  str = 'Syntax:  * = all   # = single               ' 
  ;   #,# = multiple   #:# = range  supported later
  getlab = Widget_Label(getreadbase, Value = str)
  Widget_Control, getreadbase, /Realize
  XManager, 'idp3_getread', getreadbase, Event_Handler='getbase_event'
  if strlen(val) gt 0 then value = val else value = defstr
end

