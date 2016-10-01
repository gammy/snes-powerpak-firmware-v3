;==========================================================================================
;
;   UNOFFICIAL SNES POWERPAK FIRMWARE V3.00 (CODENAME: "MUFASA")
;   (c) 2012-2016 by ManuLöwe (http://manuloewe.de/)
;
;	*** VIDEO SETUP & NMI HANDLER ***
;	Code in this file based on v1.0X code written by:
;	- bunnyboy (SNES PowerPak creator), (c) 2009
;
;==========================================================================================



VBlank:
	AccuIndex16

	pha					; preserve 16 bit registers
	phx
	phy

	phk					; set Data Bank = Program Bank
	plb

	lda	temp+6				; push temp variables on the stack (used in scrolling routines)
	pha
	lda	temp+4
	pha
	lda	temp+2
	pha
	lda	temp
	pha

	Accu8

	jsr	DoScrolling



; -------------------------- move cursor
	lda	cursorX
	sta	SpriteBuf1.Cursor
	lda	cursorY
	sec
	sbc	#$10
	; clc
	; adc	#$08
	sta	SpriteBuf1.Cursor+1



; -------------------------- refresh sprites
	stz	$2102				; reset OAM address
	stz	$2103

	; DMA parameters:
	; Mode: $00, CPU -> PPU, auto increment, write 1 byte
	; source bank: $00 (lower 8K of WRAM)
	; source offset: SpriteBuf1
	; B bus register: $2104 (OAM data write)
	; number of bytes to transfer: 512 + 32 (OAM size)

	DMA_CH0 $00, $00, SpriteBuf1, $04, 544



; -------------------------- refresh BG1
	lda	#$00				; VRAM address increment mode: increment address by one word
	sta	$2115				; after accessing the low byte ($2118)

	ldx	#ADDR_VRAM_BG1_TILEMAP		; set VRAM address to BG1 tile map
	stx	$2116

	; DMA parameters:
	; Mode: $00, CPU -> PPU, auto increment, write 1 byte
	; source bank: $7E (WRAM)
	; source offset: TextBuffer.BG1 (get lower 16 bit)
	; B bus register: $2118 (VRAM low byte)
	; number of bytes to transfer: 2048 (tile map size)

	DMA_CH0 $00, $7E, (TextBuffer.BG1 & $FFFF), $18, 2048



; -------------------------- refresh BG2
	lda	#$00				; VRAM address increment mode: increment address by one word
	sta	$2115				; after accessing the low byte ($2118)

	ldx	#ADDR_VRAM_BG2_TILEMAP		; set VRAM address to BG2 tile map
	stx	$2116

	; DMA parameters:
	; Mode: $00, CPU -> PPU, auto increment, write 1 byte
	; source bank: $7E (WRAM)
	; source offset: TextBuffer.BG2 (get lower 16 bit)
	; B bus register: $2118 (VRAM low byte)
	; number of bytes to transfer: 2048 (tile map size)

	DMA_CH0 $00, $7E, (TextBuffer.BG2 & $FFFF), $18, 2048



; -------------------------- misc. tasks
	jsr	GetInput

	lda	scrollY
	sta	$210E				; BG1 vertical scroll
	stz	$210E
	sta	$2110				; BG2 vertical scroll
	stz	$2110

	lda	DP_HDMAchannels			; initiate HDMA transfers
	and	#%11111100				; make sure channels 0, 1 (reserved for normal DMA) aren't used
	sta	$420C

	lda	REG_RDNMI				; clear NMI flag (just to be sure)

	AccuIndex16

	pla					; restore temp variables
	sta	temp
	pla
	sta	temp+2
	pla
	sta	temp+4
	pla
	sta	temp+6

	ply					; restore 16 bit registers
	plx
	pla
rti



; ***************************** Set up GFX *****************************

GFXsetup:
	Accu8
	Index16



; -------------------------- HDMA tables --> WRAM
	ldx	#(HDMAtable.BG & $FFFF)		; set WRAM address = HDMA backdrop color gradient buffer, get lower word
	stx	$2181
	stz	$2183

	ldx	#0

	lda	#1					; build placeholder table with an all-black background
-	sta	$2180				; scanline no.

	stz	$2180				; 1st word: CGRAM address ($00)
	stz	$2180

	stz	$2180				; 2nd word: color (black)
	stz	$2180

	inx
	cpx	#224				; 224 HDMA table entries done?
	bne	-

	stz	$2180				; end of HDMA table

	ldx	#0

-	lda.l	HDMA_Window, x			; copy HDMA windowing table to buffer
	sta	HDMAtable.Window, x
	inx
	cpx	#HDMA_Window_End-HDMA_Window	; 13 bytes
	bne	-

	ldx	#0

-	lda.l	HDMA_Scroll, x			; copy HDMA horizontal scroll offset table to buffer
	sta	HDMAtable.ScrollBG1, x
	inx
	cpx	#HDMA_Scroll_End-HDMA_Scroll	; 21 bytes
	bne	-

	ldx	#0

-	lda.l	HDMA_Scroll, x			; copy HDMA horizontal scroll offset table to buffer
	sta	HDMAtable.ScrollBG2, x
	inx
	cpx	#HDMA_Scroll_End-HDMA_Scroll	; 21 bytes
	bne	-

	ldx	#0

-	lda.l	HDMA_ColMath, x			; copy HDMA color math table to buffer
	sta	HDMAtable.ColorMath, x
	inx
	cpx	#HDMA_ColMath_End-HDMA_ColMath	; 10 bytes
	bne	-



; -------------------------- palettes --> CGRAM
	stz	$2121				; reset CGRAM address

	ldx	#0

-	lda.l	BG_Palette, x
	sta	$2122

	inx
	cpx	#8					; 4 colors = 8 bytes done?
	bne	-

	lda	#ADDR_CGRAM_MAIN_GFX		; set CGRAM address for sprite palettes (main GFX palette = $80)
	sta	$2121

	DMA_CH0 $02, :Sprite_Palettes, Sprite_Palettes, $22, 256



; -------------------------- "expand" font for hi-res use into VRAM
	lda	#$80				; VRAM address increment mode: increment address by one word
	sta	$2115				; after accessing the high byte ($2119)

	ldx	#ADDR_VRAM_BG1_TILES		; set VRAM address for BG1 font tiles
	stx	$2116

	Accu16

	ldx	#$0000

__BuildFontBG1:
	ldy	#$0000

-	lda.l	Font, x				; first, copy font tile (font tiles sit on the "left")
	sta	$2118
	inx
	inx
	iny
	cpy	#$0008				; 16 bytes (8 double bytes) per tile
	bne	-

	ldy	#$0000

-	stz	$2118				; next, add 3 blank tiles (1 blank tile because Mode 5 forces 16×8 tiles
	iny					; and 2 blank tiles because BG1 is 4bpp)
	cpy	#$0018				; 16 bytes (8 double bytes) per tile
	bne	-

	cpx	#$0800				; 2 KiB font done?
	bne	__BuildFontBG1

	ldx	#ADDR_VRAM_BG2_TILES		; set VRAM address for BG2 font tiles
	stx	$2116

	ldx	#$0000

__BuildFontBG2:
	ldy	#$0000

-	stz	$2118				; first, add 1 blank tile (Mode 5 forces 16×8 tiles,
	iny					; no more blank tiles because BG2 is 2bpp)
	cpy	#$0008				; 16 bytes (8 double bytes) per tile
	bne	-

	ldy	#$0000

-	lda.l	Font, x				; next, copy 8×8 font tile (font tiles sit on the "right")
	sta	$2118
	inx
	inx
	iny
	cpy	#$0008				; 16 bytes (8 double bytes) per tile
	bne	-

	cpx	#$0800				; 2 KiB font done?
	bne	__BuildFontBG2

	Accu8



; -------------------------- sprites --> VRAM
	ldx	#ADDR_VRAM_SPR_TILES		; set VRAM address for sprite tiles
	stx	$2116

	DMA_CH0 $01, :SpriteTiles, SpriteTiles, $18, $4000



; -------------------------- font width table --> WRAM
	ldx	#(SpriteFWT & $FFFF)		; set WRAM address = sprite font width table buffer
	stx	$2181
	stz	$2183

	DMA_CH0 $00, :Sprite_FWT, Sprite_FWT, $80, Sprite_FWT_End-Sprite_FWT



; -------------------------- prepare tilemaps
	ldx	#ADDR_VRAM_BG1_TILEMAP		; set VRAM address to BG1 tilemap
	stx	$2116

	lda	#%00100000				; set the priority bit of all tilemap entries

	ldx	#$0800				; set BG1's tilemap size (64×32 = 2048 tiles)

-	sta	$2119				; set priority bit
	dex
	bne	-

	ldx	#ADDR_VRAM_BG2_TILEMAP		; set VRAM address to BG2 tilemap
	stx	$2116

	ldx	#$0800				; set BG2's tilemap size (64×32 = 2048 tiles)

-	sta	$2119				; set priority bit
	dex
	bne	-



; -------------------------- set up the screen
GFXsetup2:
	lda	#%00000011				; 8×8 (small) / 16×16 (large) sprites, character data at $6000
	sta	$2101

	lda	#$05				; set BG mode 5 for horizontal high resolution :-)
	sta	$2105

;	lda	#$08				; never mind (unless a BGMODE change would occur mid-frame)
;	sta	$2133

	lda	#%00000001				; BG1 tilemap VRAM address ($0000) & tilemap size (64×32 tiles)
	sta	$2107

	lda	#%00001001				; BG2 tilemap VRAM address ($0800) & tilemap size (64×32 tiles)
	sta	$2108

	lda	#%01000010				; set BG1's Character VRAM offset to $2000
	sta	$210B				; and BG2's Character VRAM offset to $4000

	lda	#%00010011				; turn on BG1 + BG2 + sprites
	sta	$212C				; on mainscreen
	sta	$212D				; and subscreen

	lda	#%00100010				; enable window 1 on BG1 & BG2
	sta	$2123				; (necessary to cut off scrolling "artifact" lines in the filebrowser)

	stz	$2126				; set window 1 left position (0)

	lda	#$FF				; set window 1 right position (255), window fills the whole screen
	sta	$2127

	lda	#%00000011				; enable window masking (i.e., disable the content) on BG1 & BG2
	sta	$212E				; on mainscreen
	sta	$212F				; and subscreen (all window content is re-enabled via HDMA)

	stz	$2130				; enable color math

	lda	#%00100000				; color math (mainscreen backdrop) for questions/SPC player "window"
	sta	$2131



; -------------------------- HDMA parameters

; -------------------------- channels 0, 1: reserved for general purpose DMA!



; -------------------------- channel 2



; -------------------------- channel 3: color math
	ldx	#(HDMAtable.ColorMath & $FFFF)
	stx	$4332

	lda	#$7E				; table in WRAM expected
	sta	$4334

	lda	#$32				; PPU register $2132 (color math subscreen backdrop color)
	sta	$4331

	lda	#$02				; transfer mode (2 bytes --> $2132)
	sta	$4330



; -------------------------- channel 4: background color gradient
	ldx	#(HDMAtable.BG & $FFFF)
	stx	$4342

	lda	#$7E				; table in WRAM expected
	sta	$4344

	lda	#$21				; PPU register $2121 (color index)
	sta	$4341

	lda	#$03				; transfer mode (4 bytes --> $2121, $2121, $2122, $2122)
	sta	$4340



; -------------------------- channel 5: main/subscreen window
	ldx	#(HDMAtable.Window & $FFFF)
	stx	$4352

	lda	#$7E
	sta	$4354

	lda	#$2E				; PPU reg. $212E (enable/disable mainscreen BG window area)
	sta	$4351

	lda	#$01				; transfer mode (2 bytes --> $212E, $212F)
	sta	$4350



; -------------------------- channel 6: BG1 horizontal scroll offset
	ldx	#(HDMAtable.ScrollBG1 & $FFFF)
	stx	$4362

	lda	#$7E
	sta	$4364

	lda	#$0D				; PPU reg. $210D (BG1HOFS)
	sta	$4361

	lda	#$03				; transfer mode (4 bytes --> $210D, $210D, $210E, $210E)
	sta	$4360



; -------------------------- channel 7: BG2 horizontal scroll offset
	ldx	#(HDMAtable.ScrollBG2 & $FFFF)
	stx	$4372

	lda	#$7E
	sta	$4374

	lda	#$0F				; PPU reg. $210F (BG2HOFS)
	sta	$4371

	lda	#$03				; transfer mode (4 bytes --> $210F, $210F, $2110, $2110)
	sta	$4370
	rts



; ************************* Scrolling routines *************************

DoScrolling:
	lda	cursorYCounter			; check cursor counter, no scroll if counter=0
	beq	__CursorCheckDone

	dec	cursorYCounter

	lda	cursorY				; cursorY = cursorY - cursorYUp + cursorYDown
	sec
	sbc	cursorYUp
	clc
	adc	cursorYDown
	sta	cursorY

__CursorCheckDone:

	lda	scrollYCounter			; check scroll counter, no scroll if counter=0
	beq	__DoYScrollDone
	dec	scrollYCounter

	lda	scrollY				; scrollY = scrollY - scrollYUp + scrollYDown
	sec
	sbc	scrollYUp
	clc
	adc	scrollYDown
	sta	scrollY

__DoYScrollDone:
	rts



ScrollUp:
	Accu16

	dec	selectedEntry			; decrement entry index

	lda	selectedEntry
	cmp	#$FFFF				; check for underflow
	bne	__ScrollUpCheckTop

	lda	filesInDir				; underflow, set selectedEntry = filesInDir - 1
	dec	a
	sta	selectedEntry

	lda	filesInDir				; check if filesInDir > maxFiles, which the cursor is restricted to, too
	cmp	#maxFiles+1				; reminder: "+1" needed due to the way CMP affects the carry bit
	bcs	__ScrollUpCheckTop

	Accu8

	lda	filesInDir
	asl	a
	asl	a
	asl	a					; multiply by 8 for sprite height
	clc
	adc	#cursorYmin				; add Y indention
	sta	cursorY				; put cursor at bottom of list

	bra	__ScrollUpCheckMiddle

__ScrollUpCheckTop:
	Accu8

	lda	cursorY
	cmp	#cursorYmin				; check if cursor at top
	bne	__ScrollUpCheckMiddle

	lda	speedCounter
	sta	scrollYCounter			; cursor at top, scroll background, leave cursor

	lda	speedScroll
	sta	scrollYUp

	stz	scrollYDown

	lda	insertTop
	sta	temp

	jsr	PrintClearLine

	lda	temp
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	ora	#minPrintX				; add horizontal indention
	sta	Cursor

	lda	temp
	lsr	a
	lsr	a
	lsr	a
	sta	Cursor+1

	jsr	DirPrintEntry

	lda	insertBottom
	sec
	sbc	#$01
	and	#%00011111
	sta	insertBottom

	lda	insertTop
	sec
	sbc	#$01
	and	#%00011111
	sta	insertTop

	bra	__ScrollUpDone

__ScrollUpCheckMiddle:
	lda	speedCounter
	sta	cursorYCounter

	lda	speedScroll
	sta	cursorYUp

	stz	cursorYDown

__ScrollUpDone:
	rts



ScrollDown:
	Accu16

	inc	selectedEntry			; increment entry index

	lda	selectedEntry			; check if selectedEntry >= filesInDir
	cmp	filesInDir
	bcc	__ScrollDownCheckBottom

	stz	selectedEntry			; yes, overflow --> reset selectedEntry

	lda	filesInDir				; check if filesInDir > maxFiles
	cmp	#maxFiles+1
	bcs	__ScrollDownCheckBottom

	Accu8

	lda	#cursorYmin-$08			; put cursor at top of screen
	sta	cursorY				; (subtraction necessary because it "scrolls in" from one line above)

	bra	__ScrollDownCheckMiddle

__ScrollDownCheckBottom:
	Accu8

	lda	cursorY
	cmp	#cursorYmax				; check if cursor at bottom
	bne	__ScrollDownCheckMiddle

	lda	speedCounter			; cursor at bottom, move background, leave cursor
	sta	scrollYCounter			; set scrollYCounter (8 or 4)

	lda	speedScroll
	sta	scrollYDown				; set scrollYDown to speed (1 or 2)

	stz	scrollYUp

	lda	insertBottom
	sta	temp

	jsr	PrintClearLine

	lda	temp
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	ora	#minPrintX				; add horizontal indention
	sta	Cursor

	lda	temp
	lsr	a
	lsr	a
	lsr	a
	sta	Cursor+1

	jsr	DirPrintEntry

	lda	insertBottom
	clc
	adc	#$01
	and	#%00011111
	sta	insertBottom

	lda	insertTop
	clc
	adc	#$01
	and	#%00011111
	sta	insertTop

	bra	__ScrollDownDone

__ScrollDownCheckMiddle:
	lda	speedCounter
	sta	cursorYCounter

	lda	speedScroll
	sta	cursorYDown

	stz	cursorYUp

__ScrollDownDone:
	rts



; ******************************** EOF *********************************
