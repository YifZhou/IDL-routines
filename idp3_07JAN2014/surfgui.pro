PRO SurfGui, zData

; check if the user passed an argument of data, if not then generate
; some sample surface data
; if the user passed a dataset that is not 2D then ask the user
; if the application should generate a default 2D dataset or
; exit

inf = size(zData)
if (n_params() eq 0) then begin
	size = 40
	zData = Shift(Dist(size),size/2+5, size/2-5)
    zData = Exp(-(zData/15)^2)
    ; zdata = BESELJ(SHIFT(DIST(40),20,20)/2,0)
endif else if (inf[0] ne 2) then begin
    message = ['SURFGUI: 2D dataset required', $
               'Input dataset contains '+strtrim(inf[0],2)+'dimensions', $
               'Continue with application generated 2D dataset?']
    status = DIALOG_MESSAGE(message, /QUESTION)
    if (status eq 'Yes') then begin
        size = 40
	    zData = Shift(Dist(size),size/2+5, size/2-5)
        zData = Exp(-(zData/15)^2)
        ; zdata = BESELJ(SHIFT(DIST(40),20,20)/2,0)
    endif else begin
        return
    endelse
endif

; get the total screen x and y dimensions. Use this dims to
; size the draw area that will contain object graphics

device, get_screen_size = scr
if (n_elements(xdim) eq 0) then xdim = fix(scr[0] * 0.6)
if (n_elements(ydim) eq 0) then ydim = fix(scr[1] * 0.6)

; Values used by various droplists and menus in the program

; Color names and their associated RGB triples, for use in the
; background and foreground droplists in the color property sheets.
; To add more colors to the application, simply add the color name
; to colors and the RGB value to colorVals

colors = ['RED', 'GREEN', 'BLUE', 'WHITE', 'BLACK']
colorVals = [[255,0,0],[0,255,0],[0,0,255],[255,255,255],[0,0,0]]

; The names of the property sheets. This number of elements in this
; array is used to dimension the array that will contain the
; property sheet bases. If a new property sheet needs to be added
; to the application the first step is to add the property sheet
; name to the end of this array

surfProps =  [' SKIRT ', ' STYLE ',' ROTATION ', ' COLORS ', $
              ' TEXT ', ' LIGHT SOURCE ', ' CONTOURS ', $
              ' TEXTURE MAPPING ', ' ANIMATION ']

; names of the different surface styles associated with the surface
; object, for use on the styles property sheet, styles droplist.
; Each element number matches up with the value accepted by the
; STYLE property of the surface object

surfStyles = ['Points', 'Wire Mesh', 'Filled', 'RuledXY', $
              'RuleYZ', 'Lego', 'LegoFilled']

; names of the different types of line styles that can be applied
; to surface objects. This position of the elements in this array
; match up with the numbers the LINESTYLE property of the surface
; object accepts. This array will be used as the value to the
; linestyle property sheet on the styles property sheet


lineStyles = ['Solid Line', 'Dotted', 'Dashed', 'Dash Dot', $
			  'Dash Dot Dot Dot', 'Long Dash', 'No Line Drawn']

; Font names of the four fonts that are on all platforms IDL
; supports (except VMS). For use on the font droplists of the
; Text property sheet

fontNames =  ['Helvetica', 'Courier', 'Times', 'Symbol']

; A sampling of possible font sizes. For use in the font size
; droplist in the text property sheet.

fontSizes = ['8', '10', '12', '14', '18', '24', '36', '48']

; The different types of light sources. For use on the light
; source property sheet. The elements in the array match up
; with the number that the TYPE property of the light object
; accepts

lightTypes = ['Ambient', 'Positional', 'Directional','Spotlight']

; The number of property sheet bases that will make up the
; bulletin board base

numbases = n_elements(surfProps)

; define a variable and use it to hold the array of colortable
; names. The color table names will be placed in a droplist in the
; texture mapping property sheet

colortables = ''
loadct, get_names = colortables

; Start Constructing the controls - every GUI application starts
; with a top-level base. The only control that does not require
; a parent as the first argument

tlb = Widget_Base(TITLE = 'IDP3-ROI Surface Manipulation', $
      /COLUMN, $
      APP_MBAR = menubar)

; Create the applications menu bar. The base for the menu buttons
; is created along with the top-level base through the APP_MBAR
; keyword. For this application, menubar is the variable containing
; the base of the menubar. Children of 'menubar' will be the visible
; buttons on the menubar and will be bases for other buttons

; start with the file menu. Place a print, print setup, and Exit
; button underneath

fileMenu = WIDGET_BUTTON(menubar, $
    VALUE = 'File', $
    /HELP)
printMenBut = WIDGET_BUTTON(fileMenu, $
    VALUE = 'Print', $
    UVALUE = 'print')
printsetupMenBut = WIDGET_BUTTON(fileMenu, $
    VALUE = 'Print Setup..', $
    UVALUE = 'printsetup')

; The SEPARATOR keyword places a menu seperator (line) above the
; button

exitMenBut = WIDGET_BUTTON(fileMenu, $
    VALUE = 'Exit', $
    UVALUE = 'exit', $
    /SEPARATOR)


; Help menu - only one button so far

helpMenu = WIDGET_BUTTON(menubar, $
    VALUE = 'Help', $
    /MENU, $
    /HELP)
idlhelpBut = WIDGET_BUTTON(helpMenu, $
    VALUE = 'Help on IDL',  $
    UVALUE = 'IDLhelp')

; Create the first child of the top-level base - a row base to hold
; the property sheet droplist, the reset button and the resize
; text fields

toplineBase = WIDGET_BASE(tlb, $
    /ROW)

optionDrop = WIDGET_DROPLIST(toplineBase, $
    TITLE = 'Surface Properties', $
    VALUE = surfProps, $
    UVALUE = 'surfprop')
startOver = WIDGET_BUTTON(toplineBase, $
    VALUE = 'Reset Surface', $
    UVALUE = 'startover')
sizeLabel = WIDGET_LABEL(toplineBase, $
    VALUE = 'Screen Size')
xsizetext = WIDGET_TEXT(toplineBase, $
    VALUE = strtrim(xdim,2), $
    UVALUE = 'resize', $
    XSIZE = 5, $
    YSIZE = 1, $
    /EDITABLE)
sizexLabel = WIDGET_LABEL(toplineBase, $
    VALUE = ' x ')
ysizetext = WIDGET_TEXT(toplineBase, $
   VALUE = strtrim(ydim,2), $
   UVALUE = 'resize', $
   XSIZE = 5, $
   YSIZE = 1, $
   /EDITABLE)

; The next child of the top-level base will be the bulletin
; board base that will hold the property sheets. Create this base
; with a ROW or COLUMN keyword to make it a BB base.

optionBase = WIDGET_BASE(tlb, /FRAME)

; declare an array that will hold the IDs of the property sheet
; bases. Control IDs are simply long integers so a lonarr will do.
; Use numbases to declare this array so that each time a new base
; is added to the surfProps array above, the number of bases for
; the property sheets will also be increased.

optBase = lonarr(numbases)

; Start creating the property sheet bases one-by-one. Use the
; elements of the optBase array as the containers for the
; property sheets.


;---------------------------------------------------------------
; base 0 - skirt options : events handled by skirt_eh
;          This base will be the default base so set the MAP
;          keyword to 1 so the base is visible. All other
;  	       property sheet bases should have MAP set to 0.

optBase[0] = WIDGET_BASE(optionBase, $
   /ROW, $
   MAP=1, $
   EVENT_PRO = 'skirt_eh')
skirtBase = WIDGET_BASE(optBase[0], $
   /ROW, $
   /NONEXCLUSIVE)
skirtButton = WIDGET_BUTTON(skirtBase, $
    VALUE = 'Show Skirt', $
	UVALUE = 'useskirt')

skirtField = CW_FIELD(optBase[0], $
    /FLOATING, $
    /ROW, $
    XSIZE = 10, $
    YSIZE=1, $
	TITLE = 'Skirt Value: ', $
	UVALUE = 'skirtval', $
	VALUE = min(zData, /NAN), $
	/RETURN_EVENTS)
WIDGET_CONTROL, skirtField, SENSITIVE = 0

;---------------------------------------------------------------
; base 1 - surface styles : events handled by styles_eh
;
; This property sheet will allow the user to change the general style
; of the surface from a wire mesh to a filled surface, etc. The user
; can also change the linestyle of the surface, and the type of shading
; applied to a filled surface with a light source. The abilty to show
; and remove axis will also be included on this property sheet.

optBase[1] = WIDGET_BASE(optionBase, $
   /COLUMN, $
   MAP=0,$
   EVENT_PRO = 'styles_eh')
styleBase = WIDGET_BASE(optBase[1],$
   /ROW)
styleList = WIDGET_DROPLIST(styleBase, $
   VALUE = surfStyles, $
   UVALUE = 'style', $
   TITLE = 'Plot Style')
WIDGET_CONTROL, styleList, SET_DROPLIST_SELECT = 1
shadeBase = WIDGET_BASE(styleBase, /ROW)
shadeEBase =  WIDGET_BASE(shadeBase, $
   /ROW, $
   /EXCLUSIVE)
shadeFlatBut = WIDGET_BUTTON(shadeEBase, $
   VALUE = 'Flat Shading', $
   UVALUE = 'shadeflat')
shadeGourBut = WIDGET_BUTTON(shadeEBase, $
   VALUE = 'Gouraud Shading', $
   UVALUE = 'shadegour')
WIDGET_CONTROL, shadeFlatBut, SET_BUTTON = 1
lineBase = WIDGET_BASE(optBase[1], $
   /ROW, $
   SPACE = 50)
lineList = WIDGET_DROPLIST(lineBase, $
   VALUE = lineStyles, $
   UVALUE = 'linestyle', $
   TITLE = 'Line Style')
axisNEBase = WIDGET_BASE(lineBase, $
   /ROW, $
   /NONEXCLUSIVE)
axisBut = WIDGET_BUTTON(axisNEBase, $
   VALUE = 'Show Axis', $
   UVALUE = 'axis')


;---------------------------------------------------------------
; base 2 - rotation : events handled by rotate_eh
;
; This property sheet will give the user control over rotation of
; all three axis. This prop sheet will also give the user zooming
; capability and the ability to move the surface around the view
; using a control pad

optBase[2] = WIDGET_BASE(optionBase, $
   /ROW, $
   SPACE = 10, $
   MAP=0, $
   EVENT_PRO = 'rotate_eh')

rotationsBase = WIDGET_BASE(optBase[2], /COLUMN)
rotslideBase = WIDGET_BASE(rotationsBase, $
   /ROW, $
   SPACE = 10)
xrotSlide = WIDGET_SLIDER(rotslideBase, $
   MINIMUM = -360, $
   MAXIMUM = 360, $
   VALUE = 0, $
   UVALUE = 'rotate', $
   TITLE = 'X Rotation (Degrees)')
yrotSlide = WIDGET_SLIDER(rotslideBase, MINIMUM = -360, MAXIMUM = 360, $
   VALUE = 0, $
   UVALUE = 'rotate', $
   TITLE = 'Y Rotation (Degrees)')
zrotSlide = WIDGET_SLIDER(rotslideBase, $
   MINIMUM = -360, $
   MAXIMUM = 360, $
   VALUE = 0, $
   UVALUE = 'rotate', $
   TITLE = 'Z Rotation (Degrees)')

rotfieldBase = WIDGET_BASE(rotationsBase, $
   /ROW, $
   SPACE = 5)
scaleLab = WIDGET_LABEL(rotfieldBase, $
   VALUE = 'ZOOM:')
zoomSlider = WIDGET_SLIDER(rotfieldBase, $
   VALUE = 0, $
   /SUPPRESS_VALUE, $
   /ALIGN_CENTER, $
   MINIMUM = -20, $
   MAXIMUM = 20, $
   XSIZE = 300, $
   UVALUE = 'zoomit')

translationsBase = WIDGET_BASE(optBase[2], /COLUMN)
cpad = CW_CTRLPAD(translationsBase, $
   /COLUMN, $
   VALUE = 'Move Surface', $
   UVALUE = 'cpad', $
   /PAD_FRAME)

;---------------------------------------------------------------
; base 3 - color manipulation : events handled by color_eh
;
; The property sheet will allow the user to change the background
; and foreground colors of the surface
;

optBase[3] = WIDGET_BASE(optionBase, $
   /COLUMN, $
   MAP=0, $
   EVENT_PRO = 'color_eh')

colorControl = WIDGET_BASE(optBase[3], $
   /ROW, $
   /EXCLUSIVE, $
   /ALIGN_CENTER)
predefButton = WIDGET_BUTTON(colorControl, $
	VALUE = 'Use Predefined Colors', $
	UVALUE = 'predef')
rgbButton = WIDGET_BUTTON(colorControl, $
    VALUE = 'Use RGB Values', $
    UVALUE = 'rgb')
WIDGET_CONTROL, predefButton, SET_BUTTON = 1

colorBase = WIDGET_BASE(optBase[3], $
   /FRAME, $
   /ALIGN_CENTER)

predefBase = WIDGET_BASE(colorBase, $
   /COLUMN, $
   MAP = 1)
colordropRow = WIDGET_BASE(predefBase, $
   /ROW, $
   SPACE=10)
fcolorList = WIDGET_DROPLIST(colordropRow, $
   VALUE = colors, $
   UVALUE = 'fcolor', $
   TITLE = 'Foreground Color: ')
WIDGET_CONTROL, fcolorList, SET_DROPLIST_SELECT = 0 ; foreground color default red
bcolorList = WIDGET_DROPLIST(colordropRow, $
   VALUE = colors, $
   UVALUE = 'bcolor', $
   TITLE = 'Background Color: ')
WIDGET_CONTROL, fcolorList, SET_DROPLIST_SELECT = 3 ; background color default white

rgbBase = WIDGET_BASE(colorBase, $
   /COLUMN, $
   MAP = 0)

rgbFGBase = WIDGET_BASE(rgbBase, $
   /ROW)
colorLabel = WIDGET_LABEL(rgbFGBase, $
   VALUE = 'Foreground Color:')
redFieldFG = WIDGET_SLIDER(rgbFGBase, $
   TITLE = 'RED: ', $
   UVALUE = 'fgcolor', $
   MINIMUM = 0, $
   MAXIMUM = 255)
greenFieldFG = WIDGET_SLIDER(rgbFGBase, $
   TITLE = 'GREEN: ', $
   UVALUE = 'fgcolor', $
   MINIMUM = 0, $
   MAXIMUM = 255)
blueFieldFG = WIDGET_SLIDER(rgbFGBase, $
   TITLE = 'BLUE: ', $
   UVALUE = 'fgcolor', $
   MINIMUM = 0, $
   MAXIMUM = 255)

rgbBGBase = WIDGET_BASE(rgbBase, $
   /ROW)
colorLabel = WIDGET_LABEL(rgbBGBase, $
   VALUE = 'Background Color:')
redFieldBG = WIDGET_SLIDER(rgbBGBase, $
   TITLE = 'RED: ', $
   UVALUE = 'bgcolor', $
   MINIMUM = 0, $
   MAXIMUM = 255)
greenFieldBG = WIDGET_SLIDER(rgbBGBase, $
   TITLE = 'GREEN: ', $
   UVALUE = 'bgcolor', $
   MINIMUM = 0, $
   MAXIMUM = 255)
blueFieldBG = WIDGET_SLIDER(rgbBGBase, $
   TITLE = 'BLUE: ', $
   UVALUE = 'bgcolor', $
   MINIMUM = 0, $
   MAXIMUM = 255)

;---------------------------------------------------------------
; base 4 - text manipulation : events handled by text_eh
;
; This base will give the user the ability to add text to the surface
;

optBase[4] = WIDGET_BASE(optionBase, $
   /COLUMN, $
   MAP=0, $
   EVENT_PRO = 'text_eh')

text1Row = WIDGET_BASE(optBase[4], $
   /ROW)
addtextField = CW_FIELD(text1Row, $
   TITLE = 'Text to Add: ', $
   /STRING, $
   XSIZE = 30)
fontDrop = WIDGET_DROPLIST(text1Row, $
   TITLE = 'Font Name', $
   VALUE = fontNames, $
   UVALUE = 'choosefont')
sizeDrop = WIDGET_DROPLIST(text1Row, $
   TITLE = 'Size:', $
   VALUE = fontSizes, $
   UVALUE = 'fontsize')

text2Row = WIDGET_BASE(optBase[4], $
   /ROW)
locLabel = WIDGET_LABEL(text2Row, $
   VALUE = 'Location - ')
locXField = CW_FIELD(text2Row, $
   /ROW, $
   TITLE = 'X: ', $
   VALUE = 0.0, $
   /FLOAT, $
   UVALUE = 'Xtext', $
   /RETURN_EVENTS, $
   XSIZE = 10)
locYField = CW_FIELD(text2Row, $
   /ROW, $
   TITLE = 'Y: ', $
   VALUE = 0.0, $
   /FLOAT, $
   UVALUE = 'Ytext', $
   /RETURN_EVENTS, $
   XSIZE = 10)
locZField = CW_FIELD(text2Row, $
   /ROW, $
   TITLE = 'Z: ', $
   VALUE = 0.0, $
   /FLOAT, $
   UVALUE = 'Ztext', $
   /RETURN_EVENTS, $
   XSIZE = 10)

textNERow = WIDGET_BASE(text2Row, $
   /NONEXCLUSIVE, $
   /ROW)
threedBut = WIDGET_BUTTON(textNERow, $
   VALUE='3D Text', $
   UVALUE='threed')
addBut = WIDGET_BUTTON(text2Row, $
   VALUE = 'Add Text', $
   UVALUE = 'addtext')


;---------------------------------------------------------------
; base 5 - light source manipulation : events handled by light_eh
;
; This property sheet will allow the user to manipulate the properties
; of the light source that is applied to the surface
;

optBase[5] = WIDGET_BASE(optionBase, $
    /COLUMN, $
    MAP=0, $
    EVENT_PRO = 'light_eh')
lightActionBase = WIDGET_BASE(optBase[5], $
    /ROW,$
    SPACE = 20)
lightDrop = WIDGET_DROPLIST(lightActionBase, $
    VALUE = lightTypes, $
    UVALUE = 'light')
WIDGET_CONTROL, lightDrop, SET_DROPLIST_SELECT = 1  ; default light is positional

lightActionNEBase = WIDGET_BASE(lightActionBase, $
    /ROW, $
    /NONEXCLUSIVE)
lightOnOffButton = WIDGET_BUTTON(lightActionNEBase, $
    VALUE = 'Light Source On', $
	UVALUE = 'lighttoggle')
lightIntensity = CW_FSLIDER(lightActionBase, $
    MINIMUM = 0.0, $
    MAXIMUM = 1.0, $
	VALUE = 1.0, $
	UVALUE = 'intensity', $
	TITLE = 'Intensity')

lightcolorBase = WIDGET_BASE(optBase[5], $
   /ROW)
lightLabel = WIDGET_LABEL(lightcolorBase, $
   VALUE = 'Light Color:')
redLight = WIDGET_SLIDER(lightcolorBase, $
    TITLE = 'RED: ', $
    VALUE = 255, $
    UVALUE = 'lightcolor', $
    MINIMUM = 0, $
    MAXIMUM = 255)
greenLight = WIDGET_SLIDER(lightcolorBase, $
    TITLE = 'GREEN: ', $
    VALUE = 255, $
    UVALUE = 'lightcolor', $
    MINIMUM = 0, $
    MAXIMUM = 255)
blueLight = WIDGET_SLIDER(lightcolorBase, $
    TITLE = 'BLUE: ', $
    VALUE = 255, $
    UVALUE = 'lightcolor', $
    MINIMUM = 0, $
    MAXIMUM = 255)
WIDGET_CONTROL, lightOnOffButton, SET_BUTTON = 1 ; default has the light on

lightLocLabel = WIDGET_LABEL(lightcolorBase, $
    VALUE = 'LOCATION X/Y/Z:')
lightLocX = WIDGET_TEXT(lightcolorBase, $
    XSIZE=5, $
    YSIZE=1, $
	UVALUE = 'lightLocation', $
	/EDITABLE, $
	VALUE = '-0.5')
lightLocY = WIDGET_TEXT(lightcolorBase, $
    XSIZE=5, $
    YSIZE=1, $
	UVALUE = 'lightLocation', $
	/EDITABLE, $
	VALUE = '-0.5')
lightLocZ = WIDGET_TEXT(lightcolorBase, $
    XSIZE=5, $
    YSIZE=1,  $
	UVALUE = 'lightLocation', $
	/EDITABLE, $
	VALUE = '1.0')

;---------------------------------------------------------------
; base 6 - contours : events handled by contour_eh
;
; This prop sheet allows the user the generate contour plots
; of the surface and overlay them
;

optBase[6] = WIDGET_BASE(optionBase, $
   /COLUMN, $
   MAP = 0, $
   EVENT_PRO = 'contour_eh', $
   /BASE_ALIGN_CENTER)
contourBase = WIDGET_BASE(optBase[6],$
   /ROW, $
    SPACE=10)
contourField = CW_FIELD(contourBase, $
    TITLE = '  Number of Levels  ', $
    VALUE = 10, $
    /INTEGER, $
    /ROW, $
    XSIZE = 3, $
    UVALUE = 'contournlevels')
aloneButton = WIDGET_BUTTON(contourBase, $
    VALUE = 'Contour Alone', $
    UVALUE = 'contour')
overlayButton = WIDGET_BUTTON(contourBase, $
    VALUE = 'Overlay Surface', $
    UVALUE = 'contouroverlay')
removeButton = WIDGET_BUTTON(contourBase, $
    VALUE = 'Remove Contour Plot', $
	UVALUE = 'remove')

zposBase = WIDGET_BASE(optBase[6], $
    /ROW, $
    /BASE_ALIGN_CENTER)
zposLabel = WIDGET_LABEL(zposBase, $
    VALUE = 'Contour Z Position:  -')
zposSlider = WIDGET_SLIDER(zposBase, $
    MINIMUM = -20, $
    MAXIMUM = 20, $
	/SUPPRESS_VALUE, $
	UVALUE = 'zpos', $
	VALUE = 0, $
	XSIZE = xdim - 200)
zpos2Label = WIDGET_LABEL(zposBase, $
    VALUE = '+')

; desensitize the control pad until a contour plot is overlaid

WIDGET_CONTROL, zposSlider, SENSITIVE = 0

;---------------------------------------------------------------
; base 7 - texture mapping : events handled by texture_eh
;
; this base allows a image to be overlaid as a texture map on the surface
;

optbase[7] = WIDGET_BASE(optionBase, $
   /COLUMN, $
   MAP = 0, $
   EVENT_PRO = 'texture_eh')
fileBase = WIDGET_BASE(optBase[7], $
   /ROW, $
   SPACE=10)
fileField = CW_FIELD(fileBase, $
   TITLE = 'Image File Name: ', $
   XSIZE = 30, $
   /ROW)
fileButton = WIDGET_BUTTON(fileBase, $
   VALUE = 'Browse', $
   UVALUE = 'filebrowse')
sizeBase = WIDGET_BASE(optBase[7], $
   /ROW, $
   SPACE = 5)
xsizeField = CW_FIELD(sizeBase, $
   TITLE = 'X Dim: ', $
   XSIZE = 5, $
   /ROW, $
   /INTEGER)
ysizeField = CW_FIELD(sizeBase, $
   TITLE = 'Y Dim: ', $
   XSIZE = 5, $
   /ROW, $
   /INTEGER)
colorDroplist = WIDGET_DROPLIST(sizebase, $
   TITLE = 'Color Table', $
   VALUE = colortables, $
   UVALUE = 'colortable')

imageBase = WIDGET_BASE(optBase[7], $
   /COLUMN)
imageButton = WIDGET_BUTTON(imageBase, $
   VALUE = 'Apply Image to Surface', $
   UVALUE = 'goimage')

;---------------------------------------------------------------
; base 8 - animation of rotation : events handled by animate_eh
;
; This base will allow the user to view rotation through animation
;

optbase[8] = WIDGET_BASE(optionBase, $
    /COLUMN, $
    MAP = 0, $
    EVENT_PRO = 'animate_eh')
animBase = WIDGET_BASE(optBase[8], $
    /ROW, $
    UVALUE = 'animTimer')
anim1Lab = WIDGET_LABEL(animBase, $
    VALUE = 'Animate ')
animEBase = WIDGET_BASE(animBase, $
    /ROW, $
    /NONEXCLUSIVE)
xanimBut = WIDGET_BUTTON(animEBase, $
    VALUE = ' X ', $
    UVALUE = 'xanim')
yanimBut = WIDGET_BUTTON(animEBase, $
    VALUE = ' Y ', $
    UVALUE = 'yanim')
zanimBut = WIDGET_BUTTON(animEBAse, $
    VALUE = ' Z ', $
    UVALUE = 'zanim')
anim2Lab = WIDGET_LABEL(animBase, $
    VALUE = ' Axis In ')
animincText = WIDGET_TEXT(animBase, $
    XSIZE = 5, $
    YSIZE = 1, $
    /EDITABLE, $
	UVALUE = 'startanim')
anim3Lab = WIDGET_LABEL(animBase, $
    VALUE = ' Degree Increments')
animctlBase = WIDGET_BASE(optBase[8], $
    /ROW, $
    SPACE = 10)
delayField = CW_FIELD(animctlBase, $
    TITLE = 'Animation Delay (sec): ', $
    /ROW, $
    XSIZE=5, $
    /FLOAT, $
    VALUE = 0.1, $
    UVALUE = 'startanim')
animgoBut = WIDGET_BUTTON(animctlBase, $
    VALUE = ' Start Animation ', $
    UVALUE = 'startanim')
animstopBut = WIDGET_BUTTON(animctlBase, $
    VALUE =' Stop Animation ', $
    UVALUE = 'stopanim')

WIDGET_CONTROL, xanimBut, SET_BUTTON = 1  ; set x axis for default

; end of property sheet bases
;---------------------------------------------------------------

; create the draw area that will contain the object graphics

objectDraw = WIDGET_DRAW(tlb, $
     XSIZE = xdim, $
     YSIZE = ydim, $
	 GRAPHICS_LEVEL = 2, $
	 UVALUE = 'draw', $
	 COLOR_MODEL = 0, $
	 /EXPOSE_EVENTS,$
	 /BUTTON_EVENTS)

; realize the control heirarchy

WIDGET_CONTROL, tlb, /REALIZE

; get the value of the window object contained within the draw area

WIDGET_CONTROL, objectDraw, GET_VALUE = oWindow

; call create_surface to set up the surface objects

Create_Surface, zData, $
  VIEW = oSurfaceView, $
  MODEL = oSurfaceModel, $
  SURFACE = oSurface

; create a light object for the surface

oLight = Obj_New('IDLgrLight', $
  TYPE = 1, $
  LOCATION = [-.5,-.5,1])

oSurfaceModel->Add, oLight

; create axis objects for the surface

oSurface->GetProperty, XRANGE = xrange, $
                       YRANGE = yrange, $,
                       ZRANGE = zrange, $
                       XCOORD_CONV = xs, $
                       YCOORD_CONV = ys, $
                       ZCOORD_CONV = zs

oXAxis = Obj_New('IDLgrAxis', 0, COLOR = colorVals[4], $
        RANGE = xrange, $
        LOCATION = [xrange[0],yrange[0],zrange[0]], $
        XCOORD_CONV = xs, $
        YCOORD_CONV = ys, $
        ZCOORD_CONV = zs, $
        HIDE = 1)
oYAxis = Obj_New('IDLgrAxis', 1, COLOR = colorVals[4], $
        RANGE = yrange, $
        LOCATION = [xrange[0],yrange[0],zrange[0]], $
        XCOORD_CONV = xs, $
        YCOORD_CONV = ys, $
        ZCOORD_CONV = zs, $
        HIDE = 1)
oZAxis = Obj_New('IDLgrAxis', 2, COLOR = colorVals[4], $
        RANGE = zrange, $
        LOCATION = [xrange[0],yrange[1],zrange[0]], $
        XCOORD_CONV = xs, $
        YCOORD_CONV = ys, $
        ZCOORD_CONV = zs, $
        HIDE = 1)

oSurfaceModel->Add, oXAxis
oSurfaceModel->Add, oYAxis
oSurfaceModel->Add, oZAxis

; translate the surface to a new center

oSurfaceModel->Translate, 0.0, -0.25, 0.0

; get the default transformation

oSurfaceModel->GetProperty, TRANSFORM = defTrans

; render the graphics in the draw widget

WIDGET_CONTROL, tlb, /HOURGLASS
oWindow->Draw, oSurfaceView
WIDGET_CONTROL, tlb, HOURGLASS = 0

; create the default printer object for the application

oPrinter = obj_new('IDLgrPrinter')

; create the default image object

oImage = Obj_New('IDLgrImage')

; create the default palette object

c_table = getct(0)
oPalette = Obj_New('IDLgrPalette', $
	c_table[*,0], c_table[*,1], c_table[*,2])
oWindow->SetProperty, PALETTE = oPalette

; create a contour view and model for contour plots (if called)

oContourView = Obj_NEW('IDLgrView')
oContourModel = Obj_New('IDLgrModel')

; set up a trackball object
oTrack = obj_new('Trackball',[xdim/2, ydim/2.], xdim/2.)

; set up the default mode to surface

Mode = 'surface'

; set up the information structures

; animation property sheet info

animate = {base:animBase, loop:0, inctext:animincText, $
          position:0, increment:0, delay:delayField, $
          xaxis:1, yaxis:0, zaxis:0, reset:0}

; rotation property sheet info

rotate = {xrot:xrotSlide, yrot:yrotSlide, zrot:zrotSlide, $
          zoomsliderval:0}

; light source shading prop sheet info

light = {redLight:redLight, greenLight:greenLight, blueLight:blueLight, $
	     lightLocX:lightLocX, lightLocY:lightLocY, lightLocZ:lightLocZ}

; skirt prop sheet info

skirt = {skirtField:skirtField}

; color manipulation prop sheet info

color = {redFieldBG:redFieldBG, greenFieldBG:greenFieldBG, $
         blueFieldBG:blueFieldBG, $
         redFieldFG:redFieldFG, greenFieldFG:greenFieldFG, $
         blueFieldFG:blueFieldFG, $
         predefBase:predefBase, rgbBase:rgbBase, $
         colorVals:colorVals, colortables:colortables}

; contour prop sheet info

contour = {contourField:contourField, zposSlider:zposSlider, $
		   zsliderVal:0}

; texture mapping prop sheet info

texture = {fileField:fileField, xsizeField:xsizeField, ysizeField:ysizeField}

; text manipulation info

text = {locX:locXField, locY:locYField, locZ:locZField, threed:threedBut, $
       onglass:1, addtext:addtextField, fontNames:fontNames, $
       fontSizes:fontSizes, fontsize:12, font:0}

; object references

obj = {oSurfaceView:oSurfaceView, oSurfaceModel:oSurfaceModel, $
        oSurface:oSurface, oPrinter:oPrinter, oPalette:oPalette, $
	    oWindow:oWindow, oLight:oLight, oImage:oImage, oTrack:oTrack, $
        oContourView:oContourView, oContourModel:oContourModel, $
        oXAxis:oXAxis, oYAxis:oYAxis, oZAxis:oZAxis}

; miscellaneous data

data = {optBase:optBase, numbases:numbases, xdim:xdim, ydim:ydim, Mode:Mode, $
        objectDraw:objectDraw, MouseButton:0b, optionDrop:optionDrop, $
        defTrans:defTrans, xsizeText:xsizeText, ysizeText:ysizeText}

; package all the info structures up into one nice package

info = {obj:obj, data:data, animate:animate, rotate:rotate, light:light,  $
        skirt:skirt, color:color, contour:contour, texture:texture, text:text}

; move the info structure to a heap variable referenced but ptr

ptr = ptr_new(info,/NO_COPY)

; put the reference into the top-level base

Widget_Control, tlb, SET_UVALUE=ptr

; call Xmanager to start up the event loop, use NO_BLOCK to
; return an active command line

Xmanager, 'SurfGui', tlb, /NO_BLOCK

return
end

