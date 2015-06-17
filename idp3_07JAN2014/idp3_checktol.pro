pro idp3_checktol, mask, tol

  low = 1.0 - tol
  high = 1.0 + tol

  a = where(float(mask) gt high, hcount)
  if hcount gt 0 then mask[a] = 0.0

  b = where(float(mask) lt low, lcount)
  if lcount gt 0 then mask[b] = 0.0

end
