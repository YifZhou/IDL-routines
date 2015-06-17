pro idp3_setimstruct, newim, phead, ihead, ref, mem
@idp3_structs
@idp3_errors

    if n_elements(ihead) gt 2 then head = ihead else head = phead
    (*newim).phead = ptr_new(phead)
    (*newim).ihead = ptr_new(ihead)

;   get values from reference image structure
    (*newim).extnam = (*ref).extnam
    (*newim).extver = (*ref).extver
    (*newim).xplate = (*ref).xplate
    (*newim).yplate = (*ref).yplate
    (*newim).oxplate = (*ref).oxplate
    (*newim).oyplate = (*ref).oyplate
    (*newim).nxplate = (*ref).nxplate
    (*newim).nyplate = (*ref).nyplate
    (*newim).instrume = (*ref).instrume
    (*newim).valid_wcs = (*ref).valid_wcs
    (*newim).detector = (*ref).detector

;   set relevant values to default
    (*newim).xpscl = 1.0
    (*newim).ypscl = 1.0
    (*newim).viewtext = 0L
    (*newim).viewwin = 0L
    (*newim).cntrdtext = 0L
    (*newim).cntrdwin = 0L
    (*newim).memory_only = (mem + 1) MOD 2
    (*newim).rotxpad = 0
    (*newim).rotypad = 0
    (*newim).clipbottom = 0
    (*newim).cliptop = 0
    (*newim).dispf = ADD
    (*newim).vis = 1
    (*newim).zoom = 1
    (*newim).scl = 1.0
    (*newim).bias = 0.0
    (*newim).rot = 0.0
    (*newim).sclamt = 0.0
    (*newim).movamt = 1.0
    (*newim).rotamt = 0.0
    (*newim).topad = 0
    (*newim).pad = 0

;   get remaining values from image header
    (*newim).crval1 = sxpar(head, 'CRVAL1')
    (*newim).crval2 = sxpar(head, 'CRVAL2')
    (*newim).cd11 = sxpar(head, 'CD1_1')
    (*newim).cd12 = sxpar(head, 'CD1_2')
    (*newim).cd21 = sxpar(head, 'CD2_1')
    (*newim).cd22 = sxpar(head, 'CD2_2')
    (*newim).crpix1 = sxpar(head, 'CRPIX1')
    (*newim).crpix2 = sxpar(head, 'CRPIX2')
    (*newim).acrval1 = (*newim).crval1
    (*newim).acrval2 = (*newim).crval2
    (*newim).acd11 = (*newim).cd11
    (*newim).acd12 = (*newim).cd12
    (*newim).acd21 = (*newim).cd21
    (*newim).acd22 = (*newim).cd22
    (*newim).acrpix1 = (*newim).crpix1
    (*newim).acrpix2 = (*newim).crpix2
    (*newim).lccx = sxpar(phead, 'CNTRDX')
    (*newim).lccy = sxpar(phead, 'CNTRDY')
    (*newim).olccx = sxpar(phead, 'CNTRDX')
    (*newim).olccy = sxpar(phead, 'CNTRDY')
    (*newim).rotcx = sxpar(phead, 'ROTCX')
    (*newim).rotcy = sxpar(phead, 'ROTCY')

end
