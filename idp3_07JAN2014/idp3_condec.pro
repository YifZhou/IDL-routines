pro idp3_condec,decdeg,decs

;  Procedure:	condec,decdeg,decs
;  Purpose:	To convert a DEC from decimal degrees to
;  		a form of  +DD:MM:SS.S
;  Programer:	E. Malumuth
;  Date written:	7/11/1989
;  Modified for idp3 by B. Stobie 3/11/2003
;  expanded string to +-dd:mm:ss.sss

  if (decdeg gt 0) then p='+' else p='-'
  decdeg=abs(decdeg)
  deg=fix(decdeg)
  decmin=(decdeg-deg)*60.
  min=fix(decmin)
  decsec=(decmin-min)*60.
  if (decsec ge 59.99999) then begin
    decsec = decsec - 60.0
    min = min + 1
  endif
  if (deg lt 10) then pd = '0' else pd=''
  if (min lt 10) then pm = '0' else pm=''
  if (decsec lt 10) then ps = '0' else ps=''
  dd=string(deg)
  mm=string(min)
  ss=string(format = '(f6.3)',decsec)
  if (strmid(ss,0,1) eq '-') then ss = strmid(ss,1,strlen(ss)-1)
  decs=p + pd + strcompress(dd,/remove_all) + ':'
  decs=decs + pm + strcompress(mm,/remove_all) + ':'
  decs=decs + ps + strcompress(ss,/remove_all) 
  decs=strmid(decs,0,13)
  if (p eq '-') then decdeg=decdeg*(-1)
  return

end
