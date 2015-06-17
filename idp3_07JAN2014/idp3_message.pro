pro idp3_Message_ev, event
COMMON imsg, stat

  Widget_Control, event.top, Get_UValue=msginfo
  Case event.id of
  msginfo.cancelButton: Begin
   stat = 0
   Widget_Control, event.top, /Destroy
  end
  msginfo.continueButton: Begin
   stat = 1
   Widget_Control, event.top, /Destroy
  end
  endcase
end

function idp3_Message, info, msg 

COMMON imsg, stat
  msgWindow = Widget_base(Title = 'IDP3 Message', /Column, $
			 Group_Leader = info.idp3Window, /Grid_Layout, $
			 XOffset = 10, YOffset = 10, /Modal)
 
  msglabel = Widget_Label(msgWindow, Value = msg)
  dobase = Widget_Base(msgWindow, /Row)
  spclabel = Widget_Label(dobase, Value = '               ')
  continueButton = Widget_Button(dobase, Value = 'Continue')
  spc2label = Widget_Label(dobase, Value='     ')
  cancelButton = Widget_Button(dobase, Value = 'Cancel')

  msginfo = { cancelButton   :   cancelButton,    $
	      continueButton :   continueButton   }

  Widget_Control, msgWindow, Set_UValue = msginfo
  Widget_Control, msgWindow, /Realize
  XManager, 'idp3_Message', msgWindow, /No_Block, $
      Event_Handler='idp3_Message_Ev'

  return, stat
end
