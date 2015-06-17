; This is the procedure readintermini_udf.pro  March 24, 2004
;  It reads the mini catalog output of inter_udf.pro
;
PRO readintermini_udf,file,data,catnumber,znum,ebvnum,tnum
OPENR,/XDR,U,file,/GET_LUN
READU,U,cnumber
catnumber = FIX(cnumber)
READU,U,znum
znum = FIX(znum)
READU,U,ebvnum
ebvnum = FIX(ebvnum)
READU,U,tnum
tnum = FIX(tnum)
zv ={ID:0.0,chi: 0.,zsp:99.99,zpf: 99.99, ebvpf: 99.99, apf: 0., area: 0, $
	sig: FLTARR(6), flux: FLTARR(6),hmag: 0., isoflux: FLTARR(6), $
	wt:FLTARR(6), $
	ra: 'a', dec: 'a', x: 0., y: 0.,uv15pf: 0., uv28pf: 0.,tempnum:0., $
	apmag:FLTARR(3,6),apflux:FLTARR(3,6),isomag:FLTARR(6),$
	automag:FLTARR(6), $
	chizero:0.,zzero:0.,uv15zero:0.,aazero:0.,tempzero:0.,ho:0.,om:0.,$
	omlam:0.}
data = REPLICATE(zv,catnumber)
READU,U,data
FREE_LUN,U
RETURN
END

