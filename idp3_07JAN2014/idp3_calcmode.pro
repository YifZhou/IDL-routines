function idp3_calcmode, data

 maxdata = max(data)
 mindata = min(data)
 delta = maxdata - mindata
 if (delta LT 1000.) then bz = delta/500000. else bz = delta/5000000.
 hist = histogram(data, min=mindata, max=maxdata, binsize=bz)
 maxhist = max(hist)
 pk = where(hist EQ maxhist, count)
 peak = float(pk(0)) + 0.5
 cmode = mindata + peak * bz
 return, cmode

end
