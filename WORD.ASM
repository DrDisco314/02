title WORD

include irvine16.inc
include cs240.inc

.8086

.code

;; DX: offset of buffer for the command line tail.
getcmdtail proc
	pushf
	push ax
	push cx
	push si
	push di

	mov di,dx

	mov ch,0

	mov cl,es:[80h]		; es has start of program segment
	jcxz done
	mov si,81h		; point to first byte of cmd tail
				; in PSP.

top:	mov al,es:[si]		; get a byte from cmd tail in PSP
	mov [di],al		; store into our data segment string
	inc di			; move along both
	inc si			; strings
	loop top

done:	mov byte ptr [di],0	; null terminate our buffer

	pop di
	pop si
	pop cx
	pop ax
	popf
	ret

getcmdtail endp



.data
wordfile BYTE "WORDS.TXT",0
badr BYTE "Could not read file",0

.code

;; IN: AX file handle
;; IN: CX number of chars to read
;; IN: DX buffer to write
;; OUT: CX number of chars actually read
ReadFileN proc
	pushf
	push ax
	push bx	
	push dx

	mov bx,ax
	mov ah,3Fh
	int 21h
	jc bad
	mov cx,ax	
	jmp coda
bad: 	mov dx, offset badr
	call writestring240
	call newline
	
coda:	pop dx
	pop bx
	pop ax
	popf
	ret
ReadFileN endp

.data

wordbuf BYTE "             ",0

.code

;; IN: bx and dx offsets
;; OUT: boolean in AX
strequal proc
	pushf

	call strcmp
	jz yep
nope:	mov ax,0
	jmp coda
yep:	mov ax,1
	
coda:	popf
	ret
strequal endp

;; IN dx: offset to some word
;; OUT: ax = 1 if yes that's a word; AX = 0 otherwise
isword proc

	;; push registers	

	mov bx,dx	; save offset of someword

	mov dx, offset wordfile
	call OpenInputFile240
		
	;; ax is file handle
top:mov cx,6
	mov dx,offset wordbuf
	call ReadFileN
	cmp cx,6
	jnz endofi

	mov byte ptr [wordbuf + 5],0

	push ax			;; save filehandle
	call strequal		;; need this function
	cmp ax,1		;; see if it's equal
	pop ax			;; restore file handle
	jz found		;; go to found if found!!
	
	jmp top

endofi: call CloseFile240
	mov ax,0
	jmp coda

found:	call CloseFile240
	mov ax,1
	jmp coda 	;; might not need this jump

coda: 	
		
	;; pop registers
	
	ret
isword endp

.data

new_word BYTE "     ",0


.code

;; IN: Remove empty characters from a string (DX offset)
;; OUT: New trimmed string without extra spaces
set_string proc

	pushf
	push di
	push si
	push ax
	push bx


	mov di, offset new_word

	mov cx,5
	mov bx,dx
	mov si,di
top:mov al,[bx]
	mov [si],al
	inc bx
	inc si
	loop top

	xchg di,dx

	pop bx
	pop ax
	pop si
	pop di
	popf
	ret
set_string endp


.data

wbuffer BYTE "     ",0

.code

;; IN: DX
;; OUT: DX offset to a random word from a text file
rand_word proc

	pushf
	push ax
	push si
	push bx

	mov ax, 8494
	call Randomize
	call RandomRange
	inc ax


	;xchg dx,bx
	xchg ax,si


	mov dx, offset wordfile
	call OpenInputFile240

top: 
	mov cx,6
	mov dx, offset wbuffer
	call ReadFileN

	cmp si,0
	jz coda
	mov byte ptr [wbuffer + 5],0

	dec si
	jmp top

coda: call CloseFile240
	
	mov bx,dx
	xchg bx,dx

	pop bx
	pop si
	pop ax 
	popf
	ret

rand_word endp

;; IN: DX and BX, offsets to user and actual strings
;: OUT: AH contains the bit wise representation of 
in_place proc

    ;; Bitwise representation in AH: 00000000  if 
    ;; no letters correspond
    ;; AH: 00011111 When all letters are the same

    pushf
    push si
    push di
    push cx


    mov ah,0         ;; Set up our bit wise representation

    mov si, dx
    mov di, bx


top: 
    mov ch,[si]
    mov cl,[di]

    cmp ch,0
    jz coda

    cmp ch,cl
    jz flip
    shl ah, 1
    inc di
    inc si
flip:
    add ah, 1         ;; Flip the bit corresponding to the 
    shl ah, 1          ;; position where the characters are the same

    inc di
    inc si
    jmp top


coda:
    shr ah, 1     ;; Have to shift left to get rid of the null
    mov al,ah     ;; pointer at the end of our bitwise representation
    mov ah, 0

    pop cx         ;; restore all registers/flags except AX
    pop di
    pop si
    popf
    ret

in_place endp


;; IN: BX, offset to the wordle word, DX, offset to user guess
;; OUT: al, bitwise representation of if a letter is in a wordle word
;;	i.e, al = '00011001', the lower 5 bits of al represent if a letter is in 
;;		 the wordle word but not in the right position.
;; 		 1 = letter at this spot is in word but not in right position
;;		 0 = not in word at all
inWord proc
	pushf
	push si
	push dx
	push cx
	push bx

	mov ax,0 			;; Zero out ax
	mov si,dx 			;; store dx in si
top:
	cmp byte ptr [si],0 			
	jz done				;; if [si] = endChar, done
	shl ax,1 			;; create bitwise representation by shifting
						;; al left by 1 each step
	mov ch,[si]
	call inWordHelper

	add al,cl			;; if ah = 1 the least significant bit of al becomes 1
						;; else, the least significant bit remains 0
	inc si
	jmp top

done:
	pop bx
	pop cx
	pop dx
	pop si
	popf
	ret
inWord endp

;; IN: BX, offset to the wordle word, ch, char to see if in BX
;; OUT: cl = 1 if char in BX, cl = 0 otherwise
inWordHelper proc
	pushf
	push bx

	mov cl,0
top:
	cmp byte ptr [bx],0
	jz false
	cmp byte ptr [bx],ch
	jz true
	inc bx
	jmp top

true:
	mov cl,1
	jmp done

false:
	mov cl,0
	jmp done

done:
	pop bx
	popf
	ret
inWordHelper endp

END 