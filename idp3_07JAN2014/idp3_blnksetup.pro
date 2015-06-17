pro idp3_blnksetup, event

@idp3_structs
@idp3_errors
  
   Widget_Control, event.top, Get_UValue=info
   str1 = string(info.fdelay)
   str2 = string(info.sdelay)
   str3 = string(info.btimes)
   title = 'IDP3 Blink Control'
   lab1='Blink: Frame Delay:'
   lab2='Series Delay:'
   lab3='Count:'
   valstr = idp3_getvals(title, str1, ds2=str2, ds3=str3, $
       lab1=lab1, lab2=lab2, lab3=lab3, groupleader=event.top, $
       cancel=cancel, ws=6, xp=400, yp=400)
   if cancel eq 1 then begin
     str = 'BlinkSetup: Entries cancelled'
     idp3_updatetxt, info, str
     return
   endif
   info.fdelay = float(valstr[0])
   info.sdelay = float(valstr[1])
   info.btimes = fix(valstr[2])
   Widget_Control, info.idp3Window, Set_UValue = info
end
