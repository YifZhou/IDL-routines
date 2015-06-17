; This is program color6.pro  April 5, 1993
; The program is stored in /usr/local/lib/idl/gris/colort.pro
; The program provides six colors for plotting
;
PRO color6
;
; Set up the color table
; white = 1, red = 2, green = 3, blue = 4, yellow = 5
;
RED = [0,1,1,0,0,1]
GREEN = [0,1,0,1,0,1]
BLUE = [0,1,0,0,1,0]
TVLCT, 255*RED, 255*GREEN, 255*BLUE
;
RETURN
END








