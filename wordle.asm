title worldle

include Irvine16.inc
include cs240.inc

startMenu proto
makeBoard proto
gamemode proto

.8086

.data

gameIntro BYTE "Please enter the game mode you'd like to play:  ",0dh,0ah
BYTE "1.) Wordle - standard",0dh,0ah
BYTE "2.) Wordle - hard mode, not implemented :(",0dh,0ah
BYTE "3.) Wordle - two player, not implemented :(",0

gameChoice BYTE " ",0

.code

main PROC
	mov ax,@data
	mov ds,ax

	call clrscr240

	mov bx,offset gameIntro
	call startMenu

	mov cx,2 			;; buffer size = 2
	mov dx,offset gameChoice
	call ReadString240 	;; user game choice is in GameChoice

	mov bx,dx
	mov cx,[bx] 	;; cx is a numerical char representing user game choice
	sub cx,48 		;; Asci -> int =  Ascii - 48

	call clrscr240
	call gameMode

	mov dl,0 		
	mov dh,23 		
	call jumpcursor ;; Jump cursor to bottom-left of screen

	mov ax,4C00h
	int 21h

main ENDP

END main