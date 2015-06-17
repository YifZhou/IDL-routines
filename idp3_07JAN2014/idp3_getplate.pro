pro idp3_getplate, instr, sdet, xscale, yscale, odate=odate, otime=otime

 c1_plate = strarr(37)
 c2_plate = strarr(37)
 c3_plate = strarr(37)

 c1_plate = [ $
  'Mar  4 1997    63.8502    0.0431237    0.0429497', $   
  'Mar 12 1997    71.5709    0.0433716    0.0431966', $
  'Mar 19 1997    78.6316    0.0434394    0.0432642', $
  'Mar 28 1997    87.2269    0.0434488    0.0432735', $
  'Apr  5 1997    95.2919    0.0434427    0.0432674', $
  'Apr 15 1997    105.608    0.0434133    0.0432382', $
  'Apr 22 1997    112.922    0.0433772    0.0432022', $
  'Apr 29 1997    119.365    0.0433561    0.0431811', $
  'May  6 1997    126.223    0.0433351    0.0431602', $
  'May 13 1997    133.153    0.0433292    0.0431544', $
  'May 20 1997    140.544    0.0433011    0.0431265', $
  'May 26 1997    146.804    0.0432965    0.0431218', $
  'Jun  9 1997    160.190    0.0432959    0.0431212', $
  'Jun 30 1997    181.550    0.0432610    0.0430865', $
  'Jul 14 1997    195.929    0.0432664    0.0430918', $
  'Jul 28 1997    209.630    0.0432593    0.0430848', $
  'Aug 13 1997    225.051    0.0432511    0.0430767', $
  'Aug 25 1997    237.949    0.0432331    0.0430587', $
  'Sep  8 1997    251.858    0.0432380    0.0430636', $
  'Sep 24 1997    267.912    0.0432417    0.0430672', $
  'Oct 22 1997    295.825    0.0432125    0.0430382', $
  'Nov  5 1997    309.869    0.0432136    0.0430393', $
  'Nov 19 1997    323.789    0.0432141    0.0430398', $
  'Dec  1 1997    335.346    0.0432002    0.0430259', $
  'Feb  1 1998    397.885    0.0432263    0.0430519', $
  'Feb 18 1998    414.807    0.0432025    0.0430282', $
  'Apr 17 1998    472.140    0.0431903    0.0430161', $
  'Jun  4 1998    520.196    0.0431862    0.0430120', $
  'Aug  6 1998    583.843    0.0431920    0.0430177', $
  'Sep 24 1998    632.838    0.0431969    0.0430227', $
  'Nov 16 1998    685.648    0.0432227    0.0430484', $
  'Nov 27 1998    696.663    0.0432189    0.0430445', $
  'Dec  4 1998    703.445    0.0432177    0.0430433', $
  'Dec 12 1998    710.363    0.0432182    0.0430438', $
  'Dec 18 1998    717.432    0.0432130    0.0430386', $
  'Dec 25 1998    724.707    0.0432182    0.0430439', $
  'Jan  4 1999    734.698    0.0432125    0.0430382']

 c2_plate = [ $
  'Mar  4 1997    63.8502    0.0758667    0.0751852', $    
  'Mar 12 1997    71.5709    0.0763059    0.0756204', $
  'Mar 19 1997    78.6316    0.0764262    0.0757396', $
  'Mar 28 1997    87.2269    0.0764428    0.0757561', $
  'Apr  5 1997    95.2919    0.0764319    0.0757453', $
  'Apr 15 1997    105.608    0.0763799    0.0756938', $
  'Apr 22 1997    112.922    0.0763159    0.0756303', $
  'Apr 29 1997    119.365    0.0762785    0.0755932', $
  'May  6 1997    126.223    0.0762413    0.0755564', $
  'May 13 1997    133.153    0.0762309    0.0755461', $
  'May 20 1997    140.544    0.0761812    0.0754968', $
  'May 26 1997    146.804    0.0761730    0.0754887', $
  'Jun  9 1997    160.190    0.0761718    0.0754875', $
  'Jun 30 1997    181.550    0.0761101    0.0754264', $
  'Jul 14 1997    195.929    0.0761195    0.0754357', $
  'Jul 28 1997    209.630    0.0761070    0.0754233', $
  'Aug 13 1997    225.051    0.0760926    0.0754090', $
  'Aug 25 1997    237.949    0.0760607    0.0753774', $
  'Sep  8 1997    251.858    0.0760693    0.0753859', $
  'Sep 24 1997    267.912    0.0760758    0.0753924', $
  'Oct 22 1997    295.825    0.0760242    0.0753412', $
  'Nov  5 1997    309.869    0.0760261    0.0753431', $
  'Nov 19 1997    323.789    0.0760270    0.0753440', $
  'Dec  1 1997    335.346    0.0760024    0.0753196', $
  'Feb  1 1998    397.885    0.0760485    0.0753653', $
  'Feb 18 1998    414.807    0.0760063    0.0753235', $
  'Apr 17 1998    472.140    0.0759848    0.0753022', $
  'Jun  4 1998    520.196    0.0759775    0.0752949', $
  'Aug  6 1998    583.843    0.0759877    0.0753051', $
  'Sep 24 1998    632.838    0.0759965    0.0753138', $
  'Nov 16 1998    685.648    0.0760422    0.0753591', $
  'Nov 27 1998    696.663    0.0760353    0.0753523', $
  'Dec  4 1998    703.445    0.0760333    0.0753503', $
  'Dec 12 1998    710.363    0.0760341    0.0753511', $
  'Dec 18 1998    717.432    0.0760249    0.0753420', $
  'Dec 25 1998    724.707    0.0760342    0.0753511', $
  'Jan  4 1999    734.698    0.0760242    0.0753412'  ]
  
 c3_plate = [ $ 
  'Mar  4 1997    63.8502     0.201724     0.200985', $
  'Mar 12 1997    71.7025     0.204607     0.203858', $
  'Mar 19 1997    78.7672     0.205821     0.205068', $
  'Mar 28 1997    87.3530     0.206450     0.205694', $
  'Apr 15 1997    105.729     0.205782     0.205029', $
  'Apr 18 1997    108.770     0.205524     0.204771', $
  'Apr 23 1997    113.113     0.205356     0.204605', $
  'Apr 26 1997    116.356     0.205135     0.204384', $
  'Apr 29 1997    119.525     0.205031     0.204280', $
  'May  2 1997    122.888     0.204891     0.204142', $
  'May  6 1997    126.564     0.204816     0.204067', $
  'May  9 1997    129.172     0.204680     0.203931', $
  'May 13 1997    133.363     0.204750     0.204000', $
  'May 16 1997    136.652     0.204601     0.203852', $
  'May 20 1997    140.868     0.204608     0.203859', $
  'May 23 1997    143.444     0.204555     0.203806', $
  'May 28 1997    148.756     0.204475     0.203727', $
  'Jun  1 1997    152.318     0.204416     0.203668', $
  'Jun  9 1997    160.261     0.204263     0.203516', $
  'Jun 30 1997    181.627     0.204188     0.203441', $
  'Jul 15 1997    196.016     0.204251     0.203503', $
  'Jul 28 1997    209.716     0.204366     0.203618', $
  'Aug 13 1997    225.051     0.204154     0.203407', $
  'Aug 26 1997    238.035     0.204054     0.203308', $
  'Sep  8 1997    251.940     0.204039     0.203292', $
  'Sep 25 1997    268.001     0.203977     0.203230', $
  'Oct 22 1997    295.909     0.203794     0.203048', $
  'Nov  5 1997    309.947     0.203718     0.202972', $
  'Nov 19 1997    323.867     0.203828     0.203082', $
  'Dec  1 1997    335.401     0.203758     0.203012', $
  'Dec 17 1997    351.895     0.203824     0.203078', $
  'Jan  3 1998    368.766     0.203793     0.203047', $
  'Jan 12 1998    377.361     0.203814     0.203068', $
  'Feb  1 1998    397.954     0.203829     0.203083', $
  'Feb 18 1998    414.741     0.203809     0.203063', $
  'Mar 19 1998    443.248     0.203812     0.203066', $
  'Apr 17 1998    472.095     0.203809     0.203063', $
  'May 25 1998    510.195     0.203838     0.203092', $
  'Jun  4 1998    520.139     0.203775     0.203029', $
  'Jun 28 1998    544.852     0.203859     0.203113', $
  'Aug  6 1998    583.798     0.203755     0.203009', $
  'Sep  4 1998    612.061     0.203710     0.202965', $
  'Sep 24 1998    632.773     0.203678     0.202933', $
  'Oct 28 1998    666.771     0.203647     0.202901', $
  'Nov 16 1998    685.587     0.203656     0.202911', $
  'Nov 27 1998    696.609     0.203659     0.202914', $
  'Dec  4 1998    703.404     0.203696     0.202950', $
  'Dec 12 1998    710.322     0.203687     0.202942', $
  'Dec 18 1998    717.411     0.203659     0.202914', $
  'Dec 25 1998    724.686     0.203718     0.202972', $
  'Jan  4 1999    734.646     0.203707     0.202962'  ]

 CASE instr of

 'NICMOS': begin
   det = fix(sdet)
   if n_elements(odate) gt 0 then begin
     test = strpos(odate, '/')
     if test ge 0 then begin
       dfields = float(strsplit(odate, '/', /extract))
       dayyr = ymd2dn(dfields[2],dfields[1],dfields[0])
       if dfields[2] eq 98. then dayyr = dayyr + 365.
       if dfields[2] eq 99. then dayyr = dayyr + 730.
     endif else begin
       test = strpos(odate, '-')
       if test ge 0 then begin
	 dfields = float(strsplit(odate, '-', /extract))
	 dayyr = ymd2dn(dfields[0],dfields[1],dfields[2])
	 dayyr = dayyr + (dfields[0] - 1997.) * 365.
	 if dfields[0] ge 2000. then dayyr = dayyr + 1.
	 if dfields[0] ge 2004. then dayyr = dayyr + 1.
       endif else begin
	 print, 'Getplate, cannot resolve date, setting plate scale to 0.'
	 xscale = 0.d0
	 yscale = 0.d0
	 return
       endelse
     endelse
     tfields = float(strsplit(otime, ':', /extract))
     fractday = (tfields[0] + tfields[1]/60. + tfields[2]/3600.) / 24.
     dayyr = dayyr + fractday

     CASE det of

     1: BEGIN
       for i = 1, n_elements(c1_plate)-1 do begin
         day1 = float(strmid(c1_plate[i-1],15,7))
         day2 = float(strmid(c1_plate[i],15,7))
         if dayyr ge day1 and dayyr le day2 then begin
           delta = double(dayyr - day1) / double(day2 - day1) 
           xscal1 = double(strmid(c1_plate[i-1],27,8))
           xscal2 = double(strmid(c1_plate[i],27,8))
           yscal1 = double(strmid(c1_plate[i-1],40,8))
           yscal2 = double(strmid(c1_plate[i],40,8))
           xscale = xscal1 + delta * (xscal2 - xscal1)
           yscale = yscal1 + delta * (yscal2 - yscal1)
           return
         endif
       endfor
       print, 'No match found for day ', dayyr, '  setting to default values'
       xscale = 0.043190d0
       yscale = 0.043016d0
       end

     2: BEGIN
       numplate = n_elements(c2_plate)-1
       lastdate = double(strmid(c2_plate[numplate],15,7))
       if dayyr ge lastdate then begin
	 xscale = 0.07595
	 yscale = 0.07542
	 return
       endif
       for i = 1, numplate do begin
         day1 = double(strmid(c2_plate[i-1],15,7))
         day2 = double(strmid(c2_plate[i],15,7))
         if dayyr ge day1 and dayyr le day2 then begin
           delta = double(dayyr - day1) / double(day2 - day1) 
           xscal1 = double(strmid(c2_plate[i-1],27,8))
           xscal2 = double(strmid(c2_plate[i],27,8))
           yscal1 = double(strmid(c2_plate[i-1],40,8))
           yscal2 = double(strmid(c2_plate[i],40,8))
           xscale = xscal1 + delta * (xscal2 - xscal1)
           yscale = yscal1 + delta * (yscal2 - yscal1)
           return
         endif
       endfor
       print, 'No match found for day ', dayyr, '  setting to default values'
       xscale = 0.075985d0
       yscale = 0.075302d0
       end

     3: BEGIN
       for i = 1, n_elements(c3_plate)-1 do begin
         day1 = double(strmid(c3_plate[i-1],15,7))
         day2 = double(strmid(c3_plate[i],15,7))
         if dayyr ge day1 and dayyr le day2 then begin
           delta = double(dayyr - day1) / double(day2 - day1) 
           xscal1 = double(strmid(c3_plate[i-1],27,8))
           xscal2 = double(strmid(c3_plate[i],27,8))
           yscal1 = double(strmid(c3_plate[i-1],40,8))
           yscal2 = double(strmid(c3_plate[i],40,8))
           xscale = xscal1 + delta * (xscal2 - xscal1)
           yscale = yscal1 + delta * (yscal2 - yscal1)
           return
         endif
       endfor
       print, 'No match found for day ', dayyr, '  setting to default values'
       xscale = 0.203308d0
       yscale = 0.202707d0
       end

     else: begin
       print, 'Incorrect value for camera in header'
       xscale = -1.0d0
       yscale = -1.0d0
       end
     endcase
   endif else begin
     case det of
     1: begin
       xscale = 0.043190d0
       yscale = 0.043016d0
       end
     2: begin
       xscale = 0.075985d0
       yscale = 0.075302d0
       end
     3: begin
       xscale = 0.203308d0
       yscale = 0.202707d0
       end
     else: begin
       xscale = -1.0d0
       yscale = -1.0d0
       end
     endcase
   endelse
 end

 'WFPC2': begin
   det = fix(sdet)
   case det of
   1: begin 
     xscale = 0.045528d0 
     yscale = 0.045507d0 
     end
   2: begin
     xscale = 0.099500d0
     yscale = 0.099596d0
     end
   3: begin
     xscale = 0.099573d0
     yscale = 0.099480d0
     end
   4: begin
     xscale = 0.099539d0
     yscale = 0.099635d0
     end
   else: begin
     xscale = -1.0d0
     yscale = -1.0d0
     end
   endcase
 end

 'STIS': begin
   if sdet eq 'CCD' then begin
     xscale = 0.05072d0
     yscale = 0.05072d0
   endif else begin
     xscale = -1.0d0
     yscale = -1.0d0
   endelse
 end

 'MIPS': begin
   det = fix(sdet)
   CASE det of
   1: begin
     xscale = 2.55d0
     yscale = 2.55d0
     end
   2: begin
     xscale = 9.84d0
     yscale = 9.84d0
     end
   3: begin
     xscale = 4.99d0
     yscale = 4.99d0
     end
   4: begin
     xscale = 15.99d0
     yscale = 15.99d0
     end
   5: begin
     xscale = 10.1d0
     yscale = 10.1d0
     end
   else: begin
     xscale = -1.0d0
     yscale = -1.0d0
     end
   endcase
 end

 'IRAC': begin
   det = fix(sdet)
   CASE det of
   1: begin
     xscale = 1.21d0
     yscale = 1.21d0
     end
   2: begin
     xscale = 1.207d0
     yscale = 1.207d0
     end
   3: begin
     xscale = 1.213d0
     yscale = 1.213d0
     end
   4: begin
     xscale = 1.209d0
     yscale = 1.209d0
     end
   else: begin
     xscale = -1.0d0
     yscale = -1.0d0
     end
   endcase
 end
 else: begin
   xscale = -1.0d0
   yscale = -1.0d0
 end
 endcase
    
 end
