
pro idp3_roisurfplay,  event

@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  roi = info.roi
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend

  bits = info.color_bits
  ; Write out a GIF of the area in case the user wants to texture map the data.
;  write_gif,'idp3temp.gif', $
;      bytscl( $
;      (*info.dispim)[x1+info.sxoff:x2+info.sxoff,y1+info.syoff:y2+info.syoff], $
;      top=!d.n_colors-bits-1,min=info.z1, max=info.z2)+bits
  dat = bytscl((*info.dispim)[x1:x2,y1:y2], $
    top=info.d_colors-bits-1,min=info.z1, max=info.z2)
  dat = byte(dat + bits)
  write_jpeg,'idp3temp.jpg', dat, quality=100

  ; Call surfgui on the data.
  surfgui, $
	(*info.dispim)[x1+info.sxoff:x2+info.sxoff,y1+info.syoff:y2+info.syoff]
  surfgui, (*info.dispim)[x1:x2,y1:y2]
end
