pro idp3_rotupdat, rot, rotcen, xy, cd, xyrot, cdrot

; routine to calculate new position of pixel in image as a result
; of rotation and update the WCS
; rot = rotation angle
; rotcen = center of rotation
; xy = pixel whose new coordinates are desired
; cd = CD matrix
; xyrot = new coordinates of rotated pixel
; cdrot = new values of rotated CD matrix

  theta = rot * (!DPI/180.0d0)
  rot_mat = [ [cos(theta), sin(theta)], $
	      [-sin(theta), cos(theta)] ]

  xyrot = rotcen + transpose(rot_mat) # (xy - rotcen) 
  cdrot = cd # rot_mat

end
