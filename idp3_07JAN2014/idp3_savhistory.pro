pro idp3_savhistory, ims, phead, lim1, lim2, ref
@idp3_structs

   ; Add information about the image that contributed to this output image.

   counter = 0
   for i = lim1, lim2 do begin
     if (*ims[i]).vis eq 1 then begin
       if lim1 eq lim2 then ct='0' else ct=string(format='(I2.2)',counter)
       if strlen((*ims[i]).name) lt 64 then begin
         sxaddpar, phead, 'IMAGE'+ct, (*ims[i]).name, 'data image'
       endif else begin
         ua_decompose, (*ims[i]).name, disk, path, name, extn, ver
         sxaddpar, phead, 'PATH'+ct, disk+path, 'data path'
         sxaddpar, phead, 'IMAGE'+ct, name, 'data image'
       endelse
       sxaddpar,phead,'SCL'+ct,(*ims[i]).scl,'data image multiplier'
       sxaddpar,phead,'BIAS'+ct,(*ims[i]).bias,'bias applied to data'
      
       case (*ims[i]).dispf of
         ADD: sxaddpar,phead,'DFUNC'+ct,'ADD','data image function'
         SUB: sxaddpar,phead,'DFUNC'+ct,'SUB','data image function'
         DIV: sxaddpar,phead,'DFUNC'+ct,'DIV','data image function'
         INV: sxaddpar,phead,'DFUNC'+ct,'INV','data image function'
         AVE: sxaddpar,phead,'DFUNC'+ct,'AVE','data image function'
         MUL: sxaddpar,phead,'DFUNC'+ct,'MUL','data image function'
         MIN: sxaddpar,phead,'DFUNC'+ct,'MIN','data image function'
	 INV: sxaddpar,phead,'DFUNC'+ct,'INV','data image function'
         POS: sxaddpar,phead,'DFUNC'+ct,'POS','data image function'
         NEG: sxaddpar,phead,'DFUNC'+ct,'NEG','data image function'
         ABS: sxaddpar,phead,'DFUNC'+ct,'ABS','data image function'
       endcase

       sxaddpar,phead,'ZOOM'+ct,(*ims[i]).zoom,'data image zoom'
       sxaddpar,phead,'ROT'+ct,(*ims[i]).rot,'data image rotation'
       sxaddpar,phead,'ROTX'+ct,(*ims[i]).rotcx,'data image rotation X center'
       sxaddpar,phead,'ROTY'+ct,(*ims[i]).rotcy,'data image rotation Y center' 
       xo = (*ims[i]).xoff + (*ims[i]).xpoff
       sxaddpar,phead,'XOFF'+ct,xo,'data image X offset'
       yo = (*ims[i]).yoff + (*ims[i]).ypoff
       sxaddpar,phead,'YOFF'+ct,yo,'data image Y offset'
       if lim1 ne lim2 then begin
         sxaddpar,phead,'OXPLAT'+ct,(*ims[i]).oxplate, $
		 'X Pixel Scale of Original Data' 
         sxaddpar,phead,'OYPLAT'+ct,(*ims[i]).oyplate, $
		 'Y Pixel Scale of Original Data'
         if (*ims[i]).oxplate ne (*ims[i]).xplate OR $
		(*ims[i]).oyplate ne (*ims[i]).yplate then begin
                sxaddpar,phead,'NXPLAT'+ct, (*ims[i]).nxplate, $
		 'X Pixel Scale of Final Data' 
                sxaddpar,phead,'NYPLAT'+ct, (*ims[i]).nyplate, $
		 'Y Pixel Scale of Final Data'
         endif
       endif
       if (*ims[i]).xpscl ne 1.0 OR (*ims[i]).ypscl ne 1.0 then begin
         sxaddpar,phead,'XPFACT'+ct,(*ims[i]).xpscl, $
		 'X Pixel Scale Factor Final Data' 
         sxaddpar,phead,'YPFACT'+ct,(*ims[i]).ypscl, $
		 'Y Pixel Scale Factor Final Data'
       endif
       if (*ims[i]).rotxpad ne 0 OR (*ims[i]).rotypad ne 0 then begin
         sxaddpar,phead,'XRPAD'+ct,(*ims[i]).rotxpad,'X padding before rotation'
         sxaddpar,phead,'YRPAD'+ct,(*ims[i]).rotypad,'Y padding before rotation'
       endif
       if (*ims[i]).flipy eq 1 then begin
         sxaddpar, phead, 'HISTORY', 'Data has been flipped in Y'
       endif
       counter = counter + 1
     endif
   endfor
   if lim1 ne lim2 then begin
     refstr = 'Header taken from reference image:' 
     sxaddpar, phead, 'HISTORY', refstr
     if strlen((*ims[ref]).name) lt 64 then begin
       sxaddpar, phead, 'HISTORY', (*ims[ref]).name
     endif else begin
       ua_decompose, (*ims[ref]).name, disk, path, name, extn, ver
       sxaddpar, phead, 'HISTORY', disk+path
       sxaddpar, phead, 'HISTORY', name
     endelse
   endif
end
