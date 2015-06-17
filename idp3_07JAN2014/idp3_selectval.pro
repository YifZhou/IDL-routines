pro selbase_event, event 

COMMON seldat, selection

 selection = event.value
 Widget_Control, event.top, /Destroy

end

pro idp3_selectval, leader, title, items, value

COMMON seldat, selection

  selbase = widget_base(Title=title, /Column, xsize=480, $
	    xoffset=500, yoffset=500, Group_Leader=leader, /Modal)
  selButton = CW_BGroup(selbase, items, row=1, uvalue='selbutton', $ 
  	      exclusive=1, /no_release)
  Widget_Control, selbase, /Realize
  XManager, 'idp3_selectval', selbase, Event_Handler='selbase_event'
  if n_elements(selection) gt 0 then value=selection else value=-1
end

