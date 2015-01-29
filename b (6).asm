; Batalha naval
.model small
.stack 100h
.data
	matrizTiros db 100 dup(?)
	matrizNavios db 100 dup(?)
	
	tableTop1 db 218, 21 dup(196), 191
	tableTitleTiros db 179, "   Matriz de tiros   ", 179
	tableTitleNavios db 179, "   Matriz de navios  ", 179
	tableTop2 db 195, 21 dup(196), 180
	border db 179
	;tableLine db 179, 32, 48, 32, 49, 32, 50, 32, 51, 32, 52, 32, 53, 32, 54, 32, 55, 32, 56, 32, 57, 179
	;tableContent db 179, 20 dup(22), 179, '$'
	tableBottom db 192, 21 dup(196), 217
	
.code

EXIT proc ; termina o programa
	mov ah, 4ch	; prepara o fim do programa
	int 21h		; sinaliza o DOS 
	ret
endp

LE_CHAR proc ; al le caracter sem escrever na tela
	mov ah, 07
	int 21h
	ret
endp

ESC_CHAR proc ; escreve char ascii de dx
	push ax
	mov ah, 02
	int 21h
	pop ax
	ret
endp

QUEBRA_LINHA proc ; quebra linha
	push dx
	mov dx, 13 ; new line
	call ESC_CHAR
	mov dx, 10 ; carriage return
	call ESC_CHAR
	pop dx
	ret
endp

ESC_STRING proc ; escreve string a partir do endereco de dx, ate caracter $
	push ax
	mov ah, 09
	int 21h
	pop ax
	ret
endp

ESC_NUMERO proc ; escreve numero de ax
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
	call ESC_CHAR
	loop LACO2
	pop cx
	pop dx
	pop bx
	pop ax
	ret
endp

PRINT_TABLES proc
	push cx
	push dx
	mov dx, offset tableTop1 ; topo da tabela
	call ESC_STRING
	call QUEBRA_LINHA
	mov dx, offset tableTitleTiros ; titulo
	call ESC_STRING
	call QUEBRA_LINHA
	mov dx, offset tableTop2 ; topo da tabela
	call ESC_STRING
	call QUEBRA_LINHA
	mov dx, 179 ; linha com numeros
	call ESC_CHAR
	mov dx, 32
	call ESC_CHAR
	mov cx, 10
	laco_table_col: mov dx, 32
	call ESC_CHAR
	mov ax, 10
	sub ax, cx
	call ESC_NUMERO
	loop laco_table_col
	mov dx, 179
	call ESC_CHAR
	call QUEBRA_LINHA
	mov cx, 10
	laco_table_row: mov dx, 179 ; linhas com dados
	call ESC_CHAR
	mov ax, 10
	sub ax, cx
	call ESC_NUMERO
	push cx
	mov cx, 10
	laco_col: mov dx, 32
	call ESC_CHAR
	mov dx, 22
	call ESC_CHAR
	loop laco_col
	pop cx
	mov dx, 179
	call ESC_CHAR
	call QUEBRA_LINHA
	loop laco_table_row
	mov dx, offset tableBottom ; final da tabela
	call ESC_STRING
	
	;mov dh, 1
	;mov dl, 0
	
	pop dx
	pop cx
	ret
endp

LIMPA_TELA proc ; limpa a tela
    push ax
    mov ah, 00h
    mov al, 03h
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

MUDA_PAGINA proc ; muda a pagina, o numero da pagina definido em al
	push ax
	mov ah, 05h ; numero do servico de BIOS
	int 10h
	pop ax
	ret
endp

ESC_CHAR_V proc ; escreve char com atributo pelo servico de video do bios, escreve caracter de al
	; bl atributo cor - 4 bits: intensidade, red, green, blue
	push ax
	push bx
	push cx
	mov bh, 0h ; pagina ou cor do segundo plano
	mov bl, 9h ; cor
	mov cx, 1 ; numero de repeticoes
	mov ah, 09h ; numero do servico de BIOS
	int 10h
	pop cx
	pop bx
	pop ax
	ret
endp

ESC_STRING_V proc ; escreve string pelo servico de video do bios, escreve string iniciada em ES:BP, comprimento cx
	; coordenadas da tela em dx, dh = linha, dl = coluna
	push ax
	push bx
	push cx
	xor bh, bh ; pagina
	mov bl, 9h ; cor
	mov ah, 13h ; numero do servico de BIOS
	mov al, 00h ; numero do subservico
	int 10h
	pop cx
	pop bx
	pop ax
	ret
endp

PRINT_TABLES_10 proc
	push ax
	push bx
	push cx
	push dx
	
	mov ax, @data ; escreve string
	mov es, ax
	mov cx, 23 ; tamanho
	
	mov dx, 0000h ; head
	mov bp, offset tableTop1 ; inicio
	call ESC_STRING_V
	mov dx, 0100h
	mov bp, offset tableTitleTiros
	call ESC_STRING_V
	mov dx, 0200h
	mov bp, offset tableTop2
	call ESC_STRING_V
	mov dx, 0D00h ; fim
	mov bp, offset tableBottom
	call ESC_STRING_V
	
	mov dl, 0 ; linhas verticais
	bordav2: mov dh, 3
	mov cx, 10
	mov al, 179
	bordav1: call MOV_CURSOR
	call ESC_CHAR_V
	inc dh
	loop bordav1
	cmp dl, 0
	mov dl, 22
	jz bordav2
	
	
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

INICIO:	mov ax, @data ; carrega valor inicial da stack
	mov ds, ax
	
	call LIMPA_TELA
	;call PRINT_TABLES
	call PRINT_TABLES_10
	
	;mov al, 22 ; escreve char 
	;mov bl, 1h
	;call ESC_CHAR_V
	
	;mov dh, 0 ; linha
	;mov dl, 23 ; coluna
	;mov bx, 0023h
	;call MOV_CURSOR
	
	call LE_CHAR
	
	call EXIT
end INICIO

;montar
;tasm /z /zi /l arquivo.asm ; l - para montar o arquivo hexa
;tlink /v arquivo.obj ; v depuracao
