pro idp3_showhead_evt, event

Widget_Control, Get_Uvalue = retval, event.id

if (retval eq "exit") then Widget_Control, event.top, /Destroy

end


pro idp3_showhead, text, thename, ysz, group_leader

modal=0
height = ysz
width = 80

; Pop up a widget to show the 'move' image header and allow
; the user to scroll through it.

title = 'IDP3 show header for '+thename
a = text

filebase = Widget_Base(Title = title, /Base_Align_Left, $
		       /Column,group_leader=group_leader, Modal=modal)

; Default Done button name:
done_button = 'Done with header for '+thename
filequit = Widget_Button(filebase, $
		Value = done_button, Uvalue = "exit")

filetext = Widget_Text(filebase, $
	               Xsize = width, $
		       Ysize = height, $
		       /Scroll, $
		       Value = a)


Widget_Control, filebase, /Realize

Xmanager, "idp3_showhead", $
		filebase, $
		Event_Handler = "idp3_showhead_evt", /No_Block

end

