title GAMEPLAY

include Irvine16.inc
include cs240.inc

makeBoard proto
makeSquare proto
placeWord proto
rand_word proto

.8086

.data
choiceOne BYTE "You've selected, Standard Wordle!",0

choiceTwo BYTE "Unfortunately, we were unable to implement this :(",0

choiceThree BYTE "Unfortunately, we were unable to implement this :(",0

inputWord BYTE "Enter a word:",0

userWord BYTE "      ",0

clearInput BYTE "                   ",0

.code

;; Runs a game mode
;; IN: CX, am int from 1->3 representing the user's desired game mode
gameMode proc
	pushf
	push dx

	cmp cx,1
	jz c1
	cmp cx,2
	jz c2
	cmp cx,3
	jz c3

	mov dx,0
	call jumpcursor

c1:
	mov dx,offset choiceOne
	call writestring240
	call standardWordle
	jmp done

c2:
	mov dx,offset choiceTwo
	call writestring240
	jmp done

c3:
	mov dx,offset choiceThree
	call writestring240
	jmp done

done:
	pop dx
	popf
	ret
gameMode endp

;; gets the length of a string
;; IN: dx, offset	
;; OUT: cx, length of string
strlen proc
	pushf
	push si

	mov si,dx
top:	
	cmp byte ptr [si],0
	jz done
	inc si
	jmp top

done:	
	mov cx,si
	sub cx,dx

	pop si
	popf
	ret

strlen endp


;; Reads a string message with multiple lines and determines the length of
;; the longest row as well as how many total rows there are so the
;; message can be printed with a box around it
;; IN: bx, offset of message
;; OUT: dh (numRows), dl (len(longestRow))
strRowCol proc
	pushf
	push bx
	push cx

	mov dx,0 	;; clear dx
	mov dh,1 	;; min rows = 1

	mov cx,0 	;; clear cx
top:
	cmp byte ptr [bx],0 	;; if currentChar = 0, done
	jz checkLen
	cmp byte ptr [bx],0dh 	;; if curentChar = 0dh, new row
	jz incRow
	inc cl 			;; inc len(currentRow)
	inc bx 			;; go to next char
	jmp top

incRow:
	inc dh 			;; increase numRows 
	add bx,2 		;; inc currentChar by two for
					;; carriage-return & line-feed
	cmp dl,cl 		;; check if largestRow < currentRow
	jb newLongestLp	;; if true, update dl
	mov cl,0 		;; row finished, reset cx
	jmp top

newLongestLp:
	mov dl,cl 	;; move currentRow -> dl	
	mov cl,0 	;; Row finished, reset cx
	jmp top

checkLen:
	cmp dl,cl
	jb newLongest
	jmp done

newLongest:
	mov dl,cl 	;; move currentRow -> dl
	mov cl,0 	;; Row finished, reset cx
	jmp done

done:
	pop cx
	pop bx
	popf
	ret

strRowCol endp


UpperLeftCh = 0C9h
LowerLeftCh = 0C8h
UpperRightCh = 0BBh
LowerRightCh = 0BCh
HorizontalCh = 0CDh
VerticalCh = 0BAh


;; CX has line length
HorizLine proc
	pushf
	push ax
	push cx

	mov al, HorizontalCh	;; write a horizontal bar
top:	
	call WriteChar240
	loop top				;; cx times

	pop cx
	pop ax
	popf
	ret	

HorizLine endp

.data

upperleft WORD ?

.code

;; Helper function for textBox, formats a string to be printed in a text box
;; IN: BX, string offset. DH, row to print at. DL, col to print at.
_printStringBox proc
	pushf
	push ax
	push bx
	push dx


	call jumpcursor
	push dx
top:
	cmp byte ptr [bx],0
	jz done
	mov al,[bx]
	call WriteChar240
	cmp byte ptr [bx],0ah
	jz newlne
	inc bx
	jmp top

newlne:
	pop dx
	inc dh
	call jumpcursor
	inc bx
	push dx
	jmp top


done:
	pop dx

	pop dx
	pop bx
	pop ax
	popf
	ret
_printStringBox endp

;; Places a box around a text message
;; IN: BX string offset
;; 	   DH, DL top-left corner of message box
textBox proc
	pushf
	push ax
	push bx
	push dx

	call clrscr240

	push bx 		;; save bx
	push dx			;; save dx
	call strRowCol 	;; IN: bx, offset of message
					;; OUT: dh (numRows), dl (len(longestRow))
	mov bx,0 		;; clear bx
	mov bh,dh 		;; bh = numRows(message)
	mov bl,dl 		;; bl = len(longestRow)
	pop dx 			;; restore dx


	call makeSquare

	inc dh 			
	inc dl 			;; Down a row and over a col to print string in the box
	pop bx 			;; restore bx
	call _printStringBox

	pop dx
	pop bx
	pop ax
	popf
	ret
textBox endp

;; Plays a standard game of wordle
standardWordle proc
	pushf

	call makeBoard 			;; Write board

	mov cx,6 	;; run loop 6 times
	mov bx,1 	;; starting row to place words on

top:
	cmp cx,0
	jz done
	mov dl,0 				
	mov dh,23
	call jumpcursor

	mov dx,offset inputWord ;; Ask user to input a word at 0,23
	call writestring240

	push bx
	mov bx,dx 				;; Store word in bx
	push cx
	call strlen 			;; cx = strlen(bx)
	mov ax,0
	mov al,cl
	pop cx
	pop bx

	mov dl,0 				
	mov dh,23
	add dl,al
	inc dl
	call jumpcursor			

	push cx
	mov cx,6 				;; buffer size = 6
	mov dx,offset userWord
	call readstring240
	pop cx

	call placeWord
	
	mov dl,0
	mov dh,23
	call jumpcursor
	mov dx, offset clearInput
	call writestring240

	inc bx
	dec cx
	jmp top

done:

	popf
	ret
standardWordle endp

;; IN: BX string offset
;; IN DH, DL center of the message
CenterBoxMessage proc
	pushf
	push ax
	push cx
	push dx

	push dx			;; save the screen location
	mov dx,bx
	call strlen		;; cx the length
	pop dx			;; restore screen location

	mov al,cl
	shr al,1		;; al is half the length

	sub dl,al		;; new column coordinate computed

	mov upperleft, dx ;; upperleft is where the message is
	
	;; Top row of the box
	sub dh,1		;; diagonal up and to the left
	sub dl,1
	call JumpCursor
	mov al,upperleftch	;; write the upper left corner
	call WriteChar240
	call HorizLine 		;; cx has the message length
	mov al, upperrightch
	call WriteChar240	;; upper right corner
	
	;; Go to the next line
	mov dx,upperleft
	sub dl,1		;; back one column
	call JumpCursor
	
	;; output the line with the message
	mov al,VerticalCh
	call WriteChar240	;; vertical bar
	mov dx, bx
	call WriteString240	;; and the message
	call WriteChar240	;; another vertical bar

	;; Go to the next line
	mov dx,upperleft
	add dh,1		; next row
	sub dl,1		; previous column
	call JumpCursor		; go!	

	;; write the bottom of the box
	mov al,lowerleftch
	call WriteChar240
	call HorizLine
	mov al,lowerrightch
	call WriteChar240
	
	pop dx
	pop cx
	pop ax
	popf
	ret

CenterBoxMessage endp

END