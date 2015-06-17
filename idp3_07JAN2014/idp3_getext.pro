pro getbase_event, event 

COMMON getdat, getvalue, val

 Widget_Control, getvalue, Get_Value = temp
 val = temp[0]
 Widget_Control, event.top, /Destroy

end

pro idp3_getext, title, wsiz, defstr, value, dimsz

COMMON getdat, getvalue, val

  getextbase = widget_base(Title=title, xoffset=400, yoffset=400, /Row)
  str = 'Index of 3rd dim to load (0 to ' + strtrim(string(dimsz),2) + $
     ' or #:# or *)?'
  getlab = Widget_Label(getextbase, Value = str)
  getvalue =  Widget_Text (getextbase, Value=defstr, XSize=wsiz, /Edit)
  Widget_Control, getextbase, /Realize
  XManager, 'idp3_getext', getextbase, Event_Handler='getbase_event'
  if strlen(val) gt 0 then value = val else value = defstr
end

