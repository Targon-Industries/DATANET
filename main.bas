REM $DYNAMIC
SCREEN _NEWIMAGE(1920, 1080, 32)
_SCREENMOVE (_DESKTOPWIDTH / 2) - (_WIDTH(0) / 2), (_DESKTOPHEIGHT / 2) - (_HEIGHT(0) / 2)

'file list by SMcNeill
DECLARE CUSTOMTYPE LIBRARY "code\direntry"
    FUNCTION load_dir& (s AS STRING)
    FUNCTION has_next_entry& ()
    SUB close_dir ()
    SUB get_next_entry (s AS STRING, flags AS LONG, file_size AS LONG)
END DECLARE
REDIM Dir(0) AS STRING, File(0) AS STRING

'Variables
TYPE internalsettings
    trimstrings AS _BYTE
    fps AS INTEGER
END TYPE
TYPE internal
    setting AS internalsettings
END TYPE
REDIM SHARED internal AS internal

TYPE global
    AS STRING nodepath, internalpath, skinpath
    AS _UNSIGNED _INTEGER64 maxnodeid
    AS _FLOAT margin, padding, round, stroke
END TYPE
REDIM SHARED global AS global

TYPE mouse
    AS _FLOAT x, y
    AS _BYTE left, right
    AS INTEGER scroll
END TYPE
REDIM SHARED mouse AS mouse

'Data structure
TYPE node
    AS STRING id, name, category, date, time
END TYPE
TYPE nodelink
    AS STRING parent, name, child
END TYPE

REDIM SHARED directories(0) AS STRING
REDIM SHARED nodefiles(0) AS STRING

'UI
TYPE element
    AS _BYTE view, acceptinput
    AS STRING x, y, w, h, style, name, text, type, color, hovercolor, shape, angle
    value AS _FLOAT
END TYPE
REDIM SHARED element(0) AS element
TYPE uisum
    AS _FLOAT x, y
    AS STRING f 'determines "focus"
END TYPE
REDIM SHARED uisum(0) AS uisum

TYPE rectangle
    AS _FLOAT x, y, w, h
END TYPE

resetallvalues

'------------- TESTING AREA ------------



'-------------- MAIN AREA --------------

loadui
DO
    CLS
    checkcontrols
    displayview 1
    _LIMIT internal.setting.fps
LOOP
SLEEP

SUB checkcontrols
    checkmouse
END SUB

SUB checkmouse
    mouse.scroll = 0
    DO
        mouse.x = _MOUSEX
        mouse.y = _MOUSEY
        mouse.scroll = mouse.scroll + _MOUSEWHEEL
        mouse.left = _MOUSEBUTTON(1)
        mouse.right = _MOUSEBUTTON(2)
    LOOP WHILE _MOUSEINPUT
END SUB

SUB checkui (arguments AS STRING)
    DO: e = e + 1
        checkelement element(e), arguments
    LOOP UNTIL e = UBOUND(element)
END SUB

SUB checkelement (this AS element, arguments AS STRING)
    IF this.view = -1 AND this.acceptinput = -1 THEN

    END IF
END SUB

SUB displayview (dview AS INTEGER) 'displays a "view"
    LINE (0, 0)-(_WIDTH(0), _HEIGHT(0)), col&("bg1"), BF
    SELECT CASE dview
        CASE 1
            IF UBOUND(element) > 0 THEN
                DO: e = e + 1
                    displayelement element(e), ""
                LOOP UNTIL e = UBOUND(element)
            END IF
    END SELECT
    resetsum
    _DISPLAY
END SUB

SUB displayelement (this AS element, arguments AS STRING) 'parses abstract coordinates into discrete coordinates
    IF this.view = -1 THEN
        DIM AS _FLOAT x, y, w, h, iconsize
        DIM AS LONG drawcolor
        h = VAL(this.h)
        IF LEN(this.shape) THEN iconsize = h - (2 * global.padding) ELSE iconsize = 0
        IF MID$(this.w, 1, 4) = "flex" THEN
            w = VAL(this.w) + (_FONTWIDTH * (LEN(this.text) + 1)) + (2 * global.padding)
        ELSE
            w = VAL(this.w)
        END IF
        IF iconsize THEN w = w + iconsize + global.padding

        IF MID$(this.x, 1, 4) = "flex" THEN
            IF MID$(this.y, 1, 4) = "flex" THEN
                'what the fuck do i do here? difficult to determine because having flex in both positions effectively doesn't position it at all
                'doesn't work like html, stacks elements based on position and not on
            ELSE
                x = findsum("y=" + this.y, w)
                y = VAL(this.y)
            END IF
        ELSE
            x = VAL(this.x)
            IF MID$(this.y, 1, 4) = "flex" THEN
                y = findsum("x=" + this.x, h)
            ELSE
                y = VAL(this.y)
            END IF
        END IF

        IF mouse.x > x AND mouse.y > y AND mouse.x < x + w AND mouse.y < y + h THEN
            drawcolor = col&(this.hovercolor)
        ELSE
            drawcolor = col&(this.color)
        END IF

        SELECT CASE this.type
            CASE "button"
                rectangle "x=" + lst$(x) + ";y=" + lst$(y) + ";w=" + lst$(w) + ";h=" + lst$(h) + ";style=" + this.style + ";angle=" + this.angle, drawcolor
                IF LEN(this.shape) THEN
                    'drawshape "shape=" + this.shape + ";x=" + lst$(x) + ";y=" + lst$(y) + ";w=" + lst$(w) + ";h=" + lst$(h), drawcolor
                    '_PUTIMAGE (x + global.padding, y + global.padding)-(x + global.padding + iconsize, y + global.padding + iconsize), this.icon
                END IF
                COLOR drawcolor, col&("t")
                _PRINTSTRING (x + iconsize + (2 * global.padding), y + global.padding), this.text
            CASE "input"
                rectangle "x=" + lst$(x) + ";y=" + lst$(y) + ";w=" + lst$(w) + ";h=" + lst$(h) + ";style=" + this.style + ";angle=" + this.angle, drawcolor
                IF LEN(this.shape) THEN
                    '_PUTIMAGE (x + global.padding, y + global.padding)-(x + global.padding + iconsize, y + global.padding + iconsize), this.icon
                END IF
        END SELECT
    END IF
END SUB

FUNCTION findsum (arguments AS STRING, addvalue AS _FLOAT) 'finds other objects that
    checksumx = getargumentv(arguments, "x")
    checksumy = getargumentv(arguments, "y")
    IF checksumx > 0 THEN
        IF UBOUND(uisum) > 0 THEN
            DO: u = u + 1
                IF uisum(u).x = checksumx AND uisum(u).f = "x" THEN
                    sumfound = u
                END IF
            LOOP UNTIL u = UBOUND(uisum)
        ELSE
            REDIM _PRESERVE uisum(UBOUND(uisum) + 1) AS uisum
            sumfound = UBOUND(uisum)
        END IF
        IF sumfound = 0 THEN
            REDIM _PRESERVE uisum(UBOUND(uisum) + 1) AS uisum
            sumfound = UBOUND(uisum)
        END IF
        uisum(sumfound).x = checksumx
        uisum(sumfound).y = uisum(sumfound).y + global.margin + addvalue
        uisum(sumfound).f = "x"
        findsum = uisum(sumfound).y - addvalue
        EXIT FUNCTION
    ELSEIF checksumy > 0 THEN
        IF UBOUND(uisum) > 0 THEN
            DO: u = u + 1
                IF uisum(u).y = checksumy AND uisum(u).f = "y" THEN
                    sumfound = u
                END IF
            LOOP UNTIL u = UBOUND(uisum)
        ELSE
            REDIM _PRESERVE uisum(UBOUND(uisum) + 1) AS uisum
            sumfound = UBOUND(uisum)
        END IF
        IF sumfound = 0 THEN
            REDIM _PRESERVE uisum(UBOUND(uisum) + 1) AS uisum
            sumfound = UBOUND(uisum)
        END IF
        uisum(sumfound).x = uisum(sumfound).x + global.margin + addvalue
        uisum(sumfound).y = checksumy
        uisum(sumfound).f = "y"
        findsum = uisum(sumfound).x - addvalue
        EXIT FUNCTION
    ELSE
        findsum = global.margin
        EXIT FUNCTION
    END IF
END FUNCTION

SUB resetsum 'explicitly doesn't use REDIM because that bugs out
    IF UBOUND(uisum) > 0 THEN
        DO: u = u + 1
            uisum(u).x = 0
            uisum(u).y = 0
            uisum(u).f = ""
        LOOP UNTIL u = UBOUND(uisum)
    END IF
    REDIM _PRESERVE uisum(0) AS uisum
END SUB

SUB add.node (arguments AS STRING)
    DIM this AS node
    this.name = getargument$(arguments, "nodename")
    this.category = getargument$(arguments, "nodecategory")
    this.date = DATE$
    this.time = TIME$
    this.id = lst$(global.maxnodeid + 1)
    IF this.name <> "" AND this.category <> "" THEN
        writenode "", this
        getmaxnodeid
    END IF
END SUB

SUB writenode (arguments AS STRING, this AS node)
    filen = FREEFILE
    OPEN path$(this.id) FOR OUTPUT AS #filen
    WRITE #filen, "date=" + this.date
    WRITE #filen, "time=" + this.time
    WRITE #filen, "name=" + this.name
    WRITE #filen, "category=" + this.category
    CLOSE #filen
END SUB

SUB add.nodelink (arguments AS STRING)
    DIM this AS nodelink

END SUB

SUB loadui
    DO: lview = lview + 1
        freen = FREEFILE
        viewfile$ = global.internalpath + "\" + lst$(lview) + ".dui"
        IF _FILEEXISTS(viewfile$) THEN
            OPEN viewfile$ FOR INPUT AS #freen
            IF EOF(freen) = 0 THEN
                DO
                    INPUT #freen, uielement$

                    REDIM _PRESERVE element(UBOUND(element) + 1) AS element
                    eub = UBOUND(element)
                    element(eub).type = getargument$(uielement$, "type")
                    element(eub).name = getargument$(uielement$, "name")
                    element(eub).x = getargument$(uielement$, "x")
                    element(eub).y = getargument$(uielement$, "y")
                    element(eub).w = getargument$(uielement$, "w")
                    element(eub).h = getargument$(uielement$, "h")
                    element(eub).color = getargument$(uielement$, "color")
                    element(eub).hovercolor = getargument$(uielement$, "hovercolor")
                    element(eub).style = getargument$(uielement$, "style")
                    element(eub).text = getargument$(uielement$, "text")
                    element(eub).shape = getargument$(uielement$, "icon")
                    element(eub).angle = getargument$(uielement$, "angle")
                    element(eub).view = -1
                LOOP UNTIL EOF(freen)
            END IF
            CLOSE #freen
            PRINT "Successfully loaded UI for view " + lst$(lview) + "!"
        ELSE
            PRINT "Error loading UI for view " + lst$(lview)
        END IF
    LOOP UNTIL lview = 3
END SUB

FUNCTION getimage& (arguments AS STRING)
    'iwidth = getargumentv(arguments, "w")
    'iheight = getargumentv(arguments, "h")
    ipath$ = getargument$(arguments, "path")
    getimage& = _LOADIMAGE(ipath$, 32)
END FUNCTION

SUB resetallvalues
    'internal settings
    internal.setting.trimstrings = -1
    internal.setting.fps = 20

    'data structure
    global.internalpath = "internal"
    global.nodepath = "nodes"
    skin$ = "default"
    global.skinpath = "skins\" + skin$
    getmaxnodeid
    global.margin = 10
    global.padding = 5
    global.round = 3
    global.stroke = 4
END SUB

SUB GetFileList (SearchDirectory AS STRING, DirList() AS STRING, FileList() AS STRING)
    CONST IS_DIR = 1
    CONST IS_FILE = 2
    DIM flags AS LONG, file_size AS LONG
    REDIM DirList(100), FileList(1000)
    DirCount = 0: FileCount = 0
    IF load_dir(SearchDirectory + CHR$(0)) THEN
        DO
            length = has_next_entry
            IF length > -1 THEN
                nam$ = SPACE$(length)
                get_next_entry nam$, flags, file_size
                IF flags AND IS_DIR THEN
                    DirCount = DirCount + 1
                    IF DirCount > UBOUND(DirList) THEN REDIM _PRESERVE DirList(UBOUND(DirList) + 100)
                    DirList(DirCount) = nam$
                ELSEIF flags AND IS_FILE THEN
                    FileCount = FileCount + 1
                    IF FileCount > UBOUND(filelist) THEN REDIM _PRESERVE FileList(UBOUND(filelist) + 100)
                    FileList(FileCount) = nam$
                END IF
            END IF
        LOOP UNTIL length = -1
        close_dir
    ELSE
    END IF
    REDIM _PRESERVE DirList(DirCount)
    REDIM _PRESERVE FileList(FileCount)
END SUB

SUB getmaxnodeid
    generatefilearrays
    IF UBOUND(nodefiles) > 0 THEN
        DO: f = f + 1
            checkval = VAL(MID$(nodefiles(f), 1, INSTR(nodefiles(f), ".")))
            IF checkval > global.maxnodeid THEN global.maxnodeid = checkval
        LOOP UNTIL f = UBOUND(nodefiles)
    END IF
END SUB

SUB generatefilearrays
    REDIM directories(0) AS STRING
    REDIM nodefiles(0) AS STRING
    GetFileList global.nodepath, directories(), nodefiles()
END SUB

FUNCTION getargument$ (basestring AS STRING, argument AS STRING)
    getargument$ = stringvalue$(basestring, argument)
END FUNCTION

FUNCTION getargumentv (basestring AS STRING, argument AS STRING)
    getargumentv = VAL(stringvalue$(basestring, argument))
END FUNCTION

FUNCTION path$ (nodename AS STRING)
    path$ = global.nodepath + "\" + nodename + ".node"
END FUNCTION

'FUNCTION stringvalue$ (basestring AS STRING, argument AS STRING)
'    DIM buffer AS STRING
'    buffer = MID$(basestring, INSTR(basestring, argument) + LEN(argument))
'    IF INSTR(buffer, ";") THEN
'        buffer = MID$(buffer, 1, INSTR(buffer, ";") - 1)
'    END IF
'    IF INSTR(buffer, "=") THEN
'        buffer = MID$(buffer, INSTR(buffer, "=") + 1)
'    END IF
'    stringvalue$ = _TRIM$(buffer)
'END FUNCTION

FUNCTION stringvalue$ (basestring AS STRING, argument AS STRING)
    IF LEN(basestring) > 0 THEN
        p = 1: DO
            IF MID$(basestring, p, LEN(argument)) = argument THEN
                endpos = INSTR(p + LEN(argument), basestring, ";")
                IF endpos = 0 THEN endpos = LEN(basestring) ELSE endpos = endpos - 1 'means that no comma has been found. taking the entire rest of the string as argument value.

                startpos = INSTR(p + LEN(argument), basestring, "=")
                IF startpos > endpos THEN
                    startpos = p + LEN(argument)
                ELSE
                    IF startpos = 0 THEN startpos = p + LEN(argument) ELSE startpos = startpos + 1 'means that no equal sign has been found. taking value right from the end of the argument name.
                END IF

                IF internal.setting.trimstrings = -1 THEN
                    stringvalue$ = LTRIM$(RTRIM$(MID$(basestring, startpos, endpos - startpos + 1)))
                    EXIT FUNCTION
                ELSE
                    stringvalue$ = MID$(basestring, startpos, endpos - startpos + 1)
                    EXIT FUNCTION
                END IF
            END IF
            finder = INSTR(p + 1, basestring, ";") + 1
            IF finder > 1 THEN p = finder ELSE stringvalue$ = "": EXIT FUNCTION
        LOOP UNTIL p >= LEN(basestring)
    END IF
END FUNCTION

SUB drawshape (arguments AS STRING, clr AS LONG)
    DIM AS _FLOAT x, y, w, h, thickness
    x = getargumentv(arguments, "x")
    y = getargumentv(arguments, "y")
    w = getargumentv(arguments, "w")
    h = getargumentv(arguments, "h")
    thickness = getargumentv(arguments, "thickness")
    IF thickness = 0 THEN thickness = global.stroke
    SELECT CASE getargument$(arguments, "shape")
        CASE "+"
            LINE (x + (w / 2) - (thickness / 2), y)-(x + (w / 2) + (thickness / 2), y + h), clr, BF
            LINE (x, y + (h / 2) - (thickness / 2))-(x + w, y + (h / 2) + (thickness / 2)), clr, BF
        CASE "x"
    END SELECT
END SUB

SUB rectangle (arguments AS STRING, clr AS LONG)
    x = getargumentv(arguments, "x")
    y = getargumentv(arguments, "y")
    w = getargumentv(arguments, "w")
    h = getargumentv(arguments, "h")
    round$ = getargument$(arguments, "round")
    rotation = getargumentv(arguments, "angle")
    rotation = rotation / 180 * _PI
    IF round$ = "" THEN
        round = global.round
    ELSE
        round = VAL(round$)
    END IF
    SELECT CASE UCASE$(getargument$(arguments, "style"))
        CASE "BF"
            rectangleoutline x, y, w, h, round, rotation, clr
            PAINT (x + (w / 2), y + (h / 2)), clr, clr
        CASE "B"
            rectangleoutline x, y, w, h, round, rotation, clr
    END SELECT
END SUB

SUB rectangleoutline (x, y, w, h, round, rotation, clr AS LONG)
    IF w < h THEN min = w ELSE min = h
    IF round > min / 2 THEN round = min / 2
    distance = SQR((w ^ 2) + (h ^ 2)) / 2 'distance to center point
    rotation = rotation - (_PI / 2)
    rounddistance = distance - SQR(round ^ 2 + round ^ 2)
    cx = x + (w / 2)
    cy = y + (h / 2)
    detail = _PI / 2 * round
    angle1 = ATN((h / 2) / (w / 2))
    angle2 = ((_PI) - (2 * angle1)) / 2
    rotation = rotation - angle1
    DO
        corner = corner + 1
        IF corner MOD 2 = 0 THEN
            cangle = angle2 * 2
            offset = -_PI / 4
        ELSE
            cangle = angle1 * 2
            offset = _PI / 4
        END IF

        rcf = rotation + anglebase
        rcfp1 = rotation + anglebase + cangle

        px = cx + (rounddistance * SIN(rcf))
        py = cy - (rounddistance * COS(rcf))

        px1 = cx + (rounddistance * SIN(rcfp1))
        py1 = cy - (rounddistance * COS(rcfp1))

        startangle = -(_PI / 2) + ((cangle / 2))
        endangle = ((cangle / 2))

        'uses endangle of previous corner to connect to startangle of next
        LINE (px + (SIN(endangle + rcf) * round), py - (COS(endangle + rcf) * round))-(px1 + (SIN(startangle + rcfp1 + offset) * round), py1 - (COS(startangle + rcfp1 + offset) * round)), clr

        angle = startangle + rcf
        DO: angle = angle + ((0.5 * _PI) / detail)
            PSET (px + (SIN(angle) * round), py - (COS(angle) * round)), clr
        LOOP UNTIL angle >= startangle + rcf + (_PI / 2)

        anglebase = anglebase + cangle
    LOOP UNTIL corner = 4
END SUB

FUNCTION lst$ (number AS _FLOAT)
    lst$ = LTRIM$(STR$(number))
END FUNCTION

FUNCTION col& (colour AS STRING)
    SELECT CASE colour
        CASE "t"
            col& = _RGBA(0, 0, 0, 0)
        CASE "ui"
            col& = _RGBA(0, 0, 0, 255)
        CASE "ui2"
            col& = _RGBA(150, 150, 150, 255)
        CASE "bg1"
            col& = _RGBA(230, 230, 230, 255)
        CASE "bg2"
            col& = _RGBA(160, 160, 160, 255)
        CASE ELSE
            red$ = MID$(colour, 1, INSTR(colour, ";") - 1)
            green$ = MID$(colour, LEN(red$) + 1, INSTR(LEN(red$) + 1, colour, ";") - 1)
            blue$ = MID$(colour, LEN(red$ + ";" + green$) + 1, INSTR(LEN(red$ + ";" + green$) + 1, colour, ";") - 1)
            alpha$ = MID$(colour, LEN(red$ + ";" + green$ + ";" + blue$) + 1, INSTR(LEN(red$ + ";" + green$ + ";" + blue$) + 1, colour, ";") - 1)
            col& = _RGBA(VAL(red$), VAL(green$), VAL(blue$), VAL(alpha$))
    END SELECT
END FUNCTION