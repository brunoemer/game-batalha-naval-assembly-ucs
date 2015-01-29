; Batalha naval
.model small
.stack 100h
.data
	matrizTiros db 100 dup(254)
	matrizNavios db 100 dup(32)
	
	tableTop1 db 218, 21 dup(196), 191
	tableTitleTiros db 179, "   Matriz de tiros   ", 179
	tableTitleNavios db 179, "   Matriz de navios  ", 179
	tableTop2 db 195, 21 dup(196), 180
	tableNumberLine db "  0 1 2 3 4 5 6 7 8 9"
	tableBottom db 192, 21 dup(196), 217
	
.code
EXIT proc ; termina o programa
	;mov al, 0
	;call MUDA_PAGINA
	
	mov ah, 4ch	; prepara o fim do programa
	int 21h		; sinaliza o DOS 
	ret
endp

QUEBRA_LINHA proc ; quebra linha
	push dx
	mov dx, 13 ; new line
	call ESC_CHAR_21
	mov dx, 10 ; carriage return
	call ESC_CHAR_21
	pop dx
	ret
endp

ESC_CHAR_21 proc ; escreve char ascii de dx
	push ax
	mov ah, 02
	int 21h
	pop ax
	ret
endp

ESC_STRING_21 proc ; escreve string a partir do endereco de dx, ate caracter $
	push ax
	mov ah, 09
	int 21h
	pop ax
	ret
endp

ESC_NUMERO_21 proc ; escreve numero de ax
	push ax
	push bx
	push dx
	push cx
	mov bx, 10
	xor cx, cx
	DIVIDE: xor dx, dx
	div bx
	add dl, '0' ; transforma de numero para caracter ascii
	push dx
	inc cx
	or ax, ax
	jnz DIVIDE
	LACO2: pop dx
	call ESC_CHAR_21
	loop LACO2
	pop cx
	pop dx
	pop bx
	pop ax
	ret
endp

LE_CHAR proc ; al le caracter sem escrever na tela
	mov ah, 07
	int 21h
	ret
endp

MUDA_PAGINA proc ; muda a pagina, o numero da pagina definido em al
	push ax
	mov ah, 05h ; numero do servico de BIOS
	int 10h
	pop ax
	ret
endp

DEFINE_MODO proc ; define modo
    push ax
    mov al, 03h ; modo texto 80 x 25
    mov ah, 00h ; modo de video
    int 10h
    pop ax
    ret
endp

MOV_CURSOR proc ; move o cursor dh=linha dl=coluna
	push ax
	push bx
	mov bh, 0 ; pagina
	mov ah, 02 ; numero do servico de BIOS
	int 10h ; posiciona cursor
	pop bx
	pop ax
	ret
endp

ESC_CHAR proc ; escreve char com atributo pelo servico de video do bios, escreve caracter de al
	; bl atributo cor - 4 bits: intensidade, red, green, blue
	push ax
	push bx
	push cx
	push dx
	mov bh, 0 ; pagina ou cor do segundo plano
	mov cx, 1 ; numero de repeticoes
	mov ah, 09h ; numero do servico de BIOS
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

ESC_STRING proc ; escreve string pelo servico de video do bios, escreve string iniciada em ES:BP, comprimento cx
	; coordenadas da tela em dx, dh = linha, dl = coluna - bl atributo cor - 4 bits: intensidade, red, green, blue
	push ax
	push bx
	push cx
	push dx
	mov bh, 0 ; pagina
	mov ah, 13h ; numero do servico de BIOS
	mov al, 00h ; numero do subservico
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

PRINT_TABLE proc ; escreve borda da tabela
	push ax
	push bx
	push cx
	push dx
	
	mov al, dl ; salva coluna base
	mov dh, 0 ; head
	mov bp, offset tableTop1 ; inicio
	call ESC_STRING
	mov dh, 2
	mov bp, offset tableTop2
	call ESC_STRING
	mov dh, 14
	mov bp, offset tableBottom
	call ESC_STRING
	mov dl, al ; primeira linha
	mov dh, 3
	mov cx, 11
	bordav1: mov al, 179
	call MOV_CURSOR
	call ESC_CHAR
	add dl, 22 ; move pra escrever segunda linha
	call MOV_CURSOR
	call ESC_CHAR
	sub dl, 22 ; volta pra escrever primeira linha
	mov ax, 10 ; escreve numeros verticais
	sub al, cl
	inc dl
	call MOV_CURSOR
	call ESC_NUMERO_21
	dec dl
	inc dh
	loop bordav1
	mov dh, 3 ; escreve numeros horizontais
	mov dl, 1
	mov bp, offset tableNumberLine
	mov cx, 21
	call ESC_STRING
	add dl, 24
	call ESC_STRING
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

PRINT_TABLES proc
	push ax
	push bx
	push cx
	push dx
	
	mov ax, @data ; escreve string
	mov es, ax
	mov bl, 7h ; cor branco nas bordas
	mov cx, 23 ; tamanho
	; tabela 1
	mov dl, 0 ; coluna base
	mov dh, 1
	mov bp, offset tableTitleTiros
	call ESC_STRING
	call PRINT_TABLE
	; tabela 2
	mov dl, 24
	mov dh, 1
	mov bp, offset tableTitleNavios
	call ESC_STRING
	call PRINT_TABLE
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

PRINT_CONTENT proc
	push ax
	push bx
	push cx
	push dx
	
	mov bl, 2h ; cor
	mov di, offset matrizTiros
	mov dh, 4 ; bases
	mov cx, 10
	lacoi: mov dl, 3
	push cx
	mov cx, 10
	lacoj: call MOV_CURSOR
	mov al, [di]
	call ESC_CHAR
	inc di
	add dl, 2
	loop lacoj
	pop cx
	inc dh
	loop lacoi
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

INICIO:	mov ax, @data ; carrega valor inicial da stack
	mov ds, ax
	
	call DEFINE_MODO
	call PRINT_TABLES
	call PRINT_CONTENT
	
	call LE_CHAR
	
	;mov di, 5
	;mov bx, 70
	;mov [matrizTiros+bx+di], 111
	;call PRINT_CONTENT
	;call LE_CHAR
	
	call EXIT
end INICIO
