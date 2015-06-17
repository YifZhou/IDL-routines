pro idp3_getcolor, ncolors, color_table

  loadct, color_table
  tvlct, r, g, b, /get
  loadct, 0
  colors = intarr(ncolors, 3)
  colors[*,*] = 255
  num = n_elements(r)-1
  dist = num / (ncolors-1)
  indx = num - dist * (ncolors-1)
  for i = 0, ncolors-1 do begin
    loc = i * dist + indx
    colors[i,*] = [r[loc],g[loc],b[loc]]
  endfor
  tvlct, colors[*,0], colors[*,1], colors[*,2]
end
