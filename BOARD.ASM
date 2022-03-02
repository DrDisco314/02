title BOARD

include Irvine16.inc  ;; gives us the model
include cs240.inc

strRowCol proto
textBox proto

.8086

titleRow = 3
titleCol = 36

boardRow = 4
boardCol = 32

numBoxes = 5
numRows = 6

redWhite = 01001111b   ;; Red background, white letter
greenWhite = 00101111b ;; Green background, white letter
greyBlack = 01111111b   ;; Grey background, white letters
greyBlack = 01110000b   ;; Grey background, black letters

.data

header BYTE "Wordle!",0
three word 3


gameTitle BYTE "CS240 Project 2: Wordle",0

.code

;; Makes the bacgkround a solid color
;; IN: ah, background color
background proc
	pushf

	mov ax,0
	mov ah,greyBlack
	mov dx,0
	call jumpcursor
	mov bx,0

	mov si,0
outer:	 			;; Outer: Moves down 3 rows
	mov cx,0
inner: 				;; Inner: Creates boxes in a row
	call BiosWriteChar
	inc cx
	cmp cx,80		;; if num_boxes (cx) < 5 (numBoxes)
	jb inner 		;; Repeat inner loop
	
	inc bl
	mov dx,0
	mov dh,bl
	call jumpcursor

	inc si
	cmp si,24 		;; if num_rows < 6
	jb outer 		;; Repeat outer loop

	popf
	ret
background endp

;; IN: BX, offset of start message
startMenu proc
    pushf
    push dx

    mov dh,5
    mov dl,12
    call textBox
    mov dl,59
    mov dh,6
    call jumpcursor

    pop dx
    popf
    ret

startMenu endp

vertLine = 0B3h
horzLine = 0C4h
bottomLeftCh = 0C0h
bottomRightCh = 0D9h
topLeftCh = 0DAh
topRightCh = 0BFh

;; IN: ah, current char considering
;;	   cx, 5 - cx = index(char)
;;	   DX, user word
;;	   BX, Wordle word
;; OUT: attrivute of color
getCharColor proc
	pushf

	popf
	ret
getCharColor endp


;; IN: DX, offset of word to be written
;;	   BX, which row of boxes to place word in (BX = 1 -> numRows)
;; Assumes strlen is = numBoxes
placeWord proc
	pushf
	push ax
	push bx
	push cx
	push dx
	push si

	mov si,dx 		;; Save dx in si

	mov dl,boardCol
	add dl,1  		;; Place first char in dl = boardCol + 1
	mov dh,boardRow 
	add dh,1 		;; Place first char in dh = boardRow + 1
	push dx			;; save the coordinates of the cursor

	dec bx 	
	mov ax,bx 		;; Ensure ax = 0 before we multiply		
	mul three		;; desiredRow(char) = 3(bx - 1)
	add cx,ax 		;; Adjust starting row to desired row
	mov dh,cl
	mov ax,0

	mov cx,numBoxes	;; How many times loop should iterate
	pop dx			;; pop coordinates of the cursor
top:
	call JumpCursor
	mov al,[si]
	call getCharColor
	call BiosWriteChar
	inc si 			;; move to the next char to be written
	add dl,3 		;; move cursor to the inside of the next box
	loop top

	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	ret
placeWord endp


;; Displays a square on the screen
;; IN: DH (row), Dl (col) top-left corner to draw square from
;;	   BH (numRows), BL (len(col))
makeSquare proc
	pushf
	push ax
	push bx
	push cx
	push dx
	
	call JumpCursor
	mov al,topLeftCh		;; Upper Left corner
	call WriteChar240 

	mov cx,0 				;; Zero high bits of cx
	mov cl,bl 				;; cl = len(row)

lp1:
	inc dl 					;; Move to the right
	call JumpCursor
	mov al,horzLine 		;; Horizontal line
	call WriteChar240
	loop lp1

	inc dl 					;; Move to the right
	call JumpCursor
	mov al,topRightCh 		;; Upper right corner
	call WriteChar240

	mov cl,bh 				;; cl = numRows
lp2:
	inc dh 					;; Down a row
	call JumpCursor
	mov al,vertLine 		;; Vertical Line
	call WriteChar240
	loop lp2

	inc dh 					;; Down a row
	call JumpCursor
	mov al,bottomRightCh 	;; Lower right corner
	call WriteChar240

	mov cl,bl 				;; cl = len(row)
lp3:
	dec dl 					;; Move to the left
	call JumpCursor
	mov al,horzLine			;; Horizontal line
	call WriteChar240
	loop lp3

	dec dl 					;; Move to the left
	call JumpCursor
	mov al,bottomLeftCh 	;; Lower left corner
	call WriteChar240

	mov cl,bh 				;; cl = numRows
lp4:
	dec dh 					;; Up a row
	call JumpCursor
	mov al,vertLine 		;; Vertical line
	call WriteChar240
	loop lp4

	pop dx
	pop cx
	pop bx
	pop ax
	popf
	ret
makeSquare endp

;; Makes a wordle board
makeBoard proc
	pushf
	push cx
	push bx
	push dx

	mov dh,titleRow 	;; starting header row
	mov dl,titleCol		;; starting header col
	call JumpCursor
	mov dx,offset header
	call WriteString240 ;; Write header, "Wordle!"

	;; Looked up the format of nested loops in assembly
	;; https://stackoverflow.com/questions/23713682/nested-loop-in-assembly-language

	mov dh,boardRow		;; starting box row
	mov dl,boardCol		;; starting box col

	mov bx,0
outer:	 			;; Outer: Moves down 3 rows
	mov cx,0
inner: 				;; Inner: Creates boxes in a row
	push bx
	mov bh,1
	mov bl,1
	call makeSquare
	pop bx
	add dl,3 		;; Move over 3 cols to draw next box
	inc cx
	cmp cx,numBoxes	;; if num_boxes (cx) < 5 (numBoxes)
	jb inner 		;; Repeat inner loop

	mov dl,boardCol	;; Go back to starting col
	add dh,3 		;; Move down to next row of boxes
	inc bx
	cmp bx,numRows	;; if num_rows < 6
	jb outer 		;; Repeat outer loop

	pop dx
	pop bx
	pop cx
	popf
	ret
makeBoard endp

;; IN: ah, current char considering
;;       cx, 5 - cx = index(char)
;;       DX, user word
;;       BX, Wordle word
;; OUT: ah, attrivute of color
getCharColor proc
    pushf
    push cx

;    push ax
;    mov ax,5        ;; Set the value of cx to the index
;    sub ax,cx         ;; of the char within the string by
;    xchg cx,ax         ;; subtracting the length of 5.
;    pop ax



    call in_place     ;; Value of the place positions are stored in ah

top:
    mov al,0
    shl ah,cl

    mov cx,7
lp1:
    shr ah,1
    loop lp1

    cmp ah,0
    jnz coda

found:
    mov ah, greenWhite
    jmp coda

next:
    call inWord
    mov ah,0
    shl al,cl

    mov cx,7
lp2:
    shr ah,1
    loop lp2

    mov ah, redWhite

coda:

    pop cx
    popf
    ret

getCharColor endp

END