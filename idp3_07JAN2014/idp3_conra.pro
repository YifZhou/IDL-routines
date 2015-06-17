pro idp3_conra,rahour,ras

;  Proceedure:	conra,rahour,ras
;  Purpose:	To convert an RA from decimal hours to
;			a form of  HH:MM:SS.S
;  Programer:	E. Malumuth
;  Date written:	7/11/1989
;  Modified for idp3 by B. Stobie 3/11/2003
;  Expanded string to  hh:mm:ss.sss

  hour=fix(rahour)
  ramin=(rahour-hour)*60.
  min=fix(ramin)
  rasec=(ramin-min)*60.
  if (rasec ge 59.9999) then begin
    rasec = rasec - 60.0
    min = min + 1.0
  endif
  if (hour lt 10) then ph = '0' else ph=''
  if (min lt 10) then pm = '0' else pm=''
  if (rasec lt 10) then ps = '0' else ps=''
  hh=string(hour)
  mm=string(min)
  ss=string(format = '(f6.3)',rasec)
  ras=' ' + ph + strcompress(hh,/remove_all) + ':'
  ras=ras + pm + strcompress(mm,/remove_all) + ':'
  ras=ras + ps + strcompress(ss,/remove_all) 
  ras=strmid(ras,0,13)
  return

end
