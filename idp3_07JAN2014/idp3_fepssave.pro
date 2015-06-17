pro idp3_fepssave, event

@idp3_structs 
@idp3_errors

  Widget_Control, event.top, Get_UValue=pinfo
  Widget_Control, pinfo.info.idp3Window, Get_UValue=cinfo

    tmpstr = '                    '
    Widget_Control, pinfo.commentField, Get_Value = comment
    comment = strtrim(comment[0],2)
    if strlen(comment) gt 0 then begin
      strput, tmpstr, comment, 0
      cinfo.phot.comment = tmpstr
    endif
    title = 'Enter Quality Flags'
    valstr = idp3_getvals(title, cinfo.phot.qualflag, groupleader=event.top, $
	     cancel=cancel, ws=25, xp=cinfo.wpos.phwp[0]-100, $
	     yp=cinfo.wpos.phwp[1])
    if cancel eq 1 then begin
      str = 'FEPSSave: Save aborted'
      idp3_updatetxt, cinfo, str
      return
    endif
    cinfo.phot.qualflag = strtrim(valstr,2)
    Widget_Control, pinfo.info.idp3Window, Set_UValue=cinfo
    Widget_Control, pinfo.outnameField, Get_Value = outname
    outname = strtrim(outname[0],2)
    if strlen(outname) gt 0 then begin
      cinfo.phot.outname = outname
      moveim = cinfo.moveimage
      m = (*cinfo.images)[moveim]
      ua_decompose, (*m).orgname, dsk2, pth2, nam2, ex2, ver2
      nam = nam2 + ex2
      exts = (*m).extver
      if strlen(nam) gt 22 then lim=38 else lim=22
      name = idp3_getname(nam, lim)
      dohdr = 1
      idp3_prntphot, cinfo, name, exts, dohdr
      allon = 1 
      idp3_prntfeps, cinfo, nam, moveim, exts, dohdr, allon
    endif
end
