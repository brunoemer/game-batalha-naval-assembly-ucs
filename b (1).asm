; Batalha naval
.model small
.stack 100h
.data
	matrizTiros db 100 dup(254)
	;matrizNavios db 100 dup(32)
	
	tableTop1 db 218, 21 dup(196), 191
	tableTitleTiros db 179, "   Matriz de tiros   ", 179
	tableTitleNavios db 179, "   Matriz de navios  ", 179
	tableTop2 db 195, 21 dup(196), 180
	tableNumberLine db "  0 1 2 3 4 5 6 7 8 9"
	tableBottom db 192, 21 dup(196), 217
	tableTitleResultado db 179, "   Resultado", 9 dup(' '), 179
	resultadoTitle1 db 		"Voce", 17 dup(' ')
	resultadoTiros db 		"  Tiros:       0 ", 4 dup(' ')
	resultadoAcertos db 	"  Acertos:     0 ", 4 dup(' ')
	resultadoAfundados db 	"  Afundados:   0 ", 4 dup(' ')
	resultadoTitle2 db 		"Adversario", 11 dup(' ')
	resultadoUltTiro db 	"  Ultimo tiro: 00X   "
	titleMensagem db 	"Mensagem:"
	titlePortaB db 		"Porta B  "
	titlePortaC db 		"Porta C  "
	titleTiro db 		"Tiro     "
	empty db 21 dup(' ')
	embarcacaoA db "Porta avioes   "
	embarcacaoB db "Navio de guerra"
	embarcacaoS db "Submarino      "
	embarcacaoD db "Destroyer      "
	embarcacaoP db "Barco patrulha "
	
	cont db 0
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

ESC_INT_21 proc ; escreve numero de ax
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

LE_CHAR_SEM_ECO proc ; le caracter sem escrever na tela, retorna em al
	mov ah, 07
	int 21h
	ret
endp

LE_CHAR proc ; le caracter e escrever na tela, retorna em al
	mov ah, 01
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

LE_CHAR_VIDEO proc ; le caracter do video, retorna em al o caracter ascii e ah os atributos cor
	push bx
	mov bh, 0 ; pagina
	mov ah, 08 ; numero do servico de BIOS
	int 10h ; posiciona cursor
	pop bx
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
	push ax ; salva a coluna base
	bordav1: mov al, 179
	call MOV_CURSOR
	call ESC_CHAR
	add dl, 22 ; move pra escrever segunda coluna
	call MOV_CURSOR
	call ESC_CHAR
	sub dl, 22 ; volta pra escrever primeira coluna
	mov ax, 10 ; escreve numeros verticais
	sub al, cl
	inc dl
	call MOV_CURSOR
	call ESC_INT_21
	dec dl
	inc dh
	loop bordav1
	pop ax
	mov dl, al
	inc dl
	mov dh, 3 ; escreve numeros horizontais
	mov bp, offset tableNumberLine
	mov cx, 21
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
	mov bl, 7 ; cor branco nas bordas
	mov cx, 23 ; tamanho
	; tabela 1
	mov dl, 0 ; coluna base
	mov dh, 1
	mov bp, offset tableTitleTiros
	call ESC_STRING
	call PRINT_TABLE
	; tabela 2
	mov dl, 24
	mov bp, offset tableTitleNavios
	call ESC_STRING
	call PRINT_TABLE
	; tabela resultados
	mov dl, 49
	mov bp, offset tableTitleResultado
	call ESC_STRING
	call PRINT_TABLE
	mov dh, 8 ; linha divisao do resultado
	mov bp, offset tableTop2
	call ESC_STRING
	mov cx, 21 ; escreve conteudo dos resultados
	inc dl
	mov dh, 3 ; linhas titulos
	mov bp, offset resultadoTitle1
	call ESC_STRING
	mov dh, 9
	mov bp, offset resultadoTitle2
	call ESC_STRING
	inc dh ; linhas tiros
	mov bp, offset resultadoTiros
	call ESC_STRING
	mov dh, 4
	call ESC_STRING
	inc dh ; linhas acertos
	mov bp, offset resultadoAcertos
	call ESC_STRING
	mov dh, 11
	call ESC_STRING
	inc dh ; linhas afundados
	mov bp, offset resultadoAfundados
	call ESC_STRING
	mov dh, 6
	call ESC_STRING
	mov dh, 13 ; linha ultimo tiro
	mov bp, offset resultadoUltTiro
	call ESC_STRING
	mov dh, 7
	mov bp, offset empty
	call ESC_STRING
	; tabela inferior
	mov cx, 9
	mov dl, 1
	mov dh, 18
	mov bp, offset titleMensagem
	call ESC_STRING
	add dh, 3
	mov bp, offset titlePortaB
	call ESC_STRING
	add dl, 24
	mov bp, offset titlePortaC
	call ESC_STRING
	add dl, 25
	mov bp, offset titleTiro
	call ESC_STRING
	
	; escreve conteudo da tabela 1
	call PRINT_CONTENT_MATRIZ
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

PRINT_CONTENT_MATRIZ proc ; escreve conteudo da tabela 1
	push ax
	push bx
	push cx
	push dx
	
	mov di, offset matrizTiros
	mov dh, 4 ; bases
	mov bl, 1 ; cor azul
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

LOAD_NAVIO proc ; carrega navio pega o caracter do bx e tamanho do cx
	push ax
	push bx
	push cx
	push dx
	
	ERRO: mov dx, 1332h ; posicao 19 x 50
	call MOV_CURSOR
	xor ax, ax
	
	push bx
	push cx
	call LE_CHAR
	sub al, '0' ; transforma em numero
	push ax
	inc dl
	call LE_CHAR
	sub al, '0' ; transforma em numero
	push ax
	inc dl
	call LE_CHAR
	push ax
	inc dl
	
	pop bx ; v ou h
	pop ax ; x
	mov ah, 2
	mul ah ; deslocamento x2
	add al, 27 ; base
	mov dl, al
	pop ax ; y
	mov dh, al
	add dh, 4 ; base
	pop cx ; tamanho
	pop ax ; caracter
	
	cmp bl, 'H'
	jz NAVIO_HORIZONTAL
	cmp bl, 'V'
	jz NAVIO_VERTICAL
	jmp ERRO
	
	NAVIO_HORIZONTAL: call MOV_CURSOR
	mov bl, 7
	call ESC_CHAR
	add dl, 2
	loop NAVIO_HORIZONTAL
	jmp NAVIO_FIM
	
	NAVIO_VERTICAL: call MOV_CURSOR
	mov bl, 7
	call ESC_CHAR
	inc dh
	loop NAVIO_VERTICAL
	
	NAVIO_FIM: 
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

NAVIO_TITLE proc ; escreve titulo com posicao inicial em bp
	push bx
	push cx
	push dx
	
	mov cx, 15
	mov bl, 7
	mov dx, 1232h ; posicao 18 x 50
	call ESC_STRING
	
	pop dx
	pop cx
	pop bx
	ret
endp

INIT_NAVIOS proc ; inicializa pedindo a posicao das embarcacoes
	push ax
	push bx
	push cx
	push dx
	
	mov bp, offset embarcacaoA
	call NAVIO_TITLE
	mov bx, 'A'
	mov cx, 5
	call LOAD_NAVIO
	mov bp, offset embarcacaoB
	call NAVIO_TITLE
	mov bx, 'B'
	mov cx, 4
	call LOAD_NAVIO
	mov bp, offset embarcacaoS
	call NAVIO_TITLE
	mov bx, 'S'
	mov cx, 3
	call LOAD_NAVIO
	mov bp, offset embarcacaoD
	call NAVIO_TITLE
	mov bx, 'D'
	mov cx, 3
	call LOAD_NAVIO
	mov bp, offset embarcacaoP
	call NAVIO_TITLE
	mov bx, 'P'
	mov cx, 2
	call LOAD_NAVIO
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

TIRO_ENVIA proc
	push ax
	push bx
	push cx
	push dx
	
	;TESTE: 
	mov dx, 1632h ; posicao 22 x 50
	call MOV_CURSOR
	call LE_CHAR
	sub al, '0' ; transforma em numero
	add al, 4 ; base
	push ax ; salva linha
	inc dl
	call LE_CHAR
	sub al, '0' ; transforma em numero
	mov ah, 2
	mul ah ; deslocamento x2
	add al, 3 ; base
	
	mov dl, al
	pop ax
	mov dh, al
	call MOV_CURSOR
	
	; comunicar com ppa
	;fazer
	mov dl, 00000010b ; pc, pc1 = 1: acertou navio; pc2 = 1: afundou navio; pc3 = 1: terminou jogo(voce ganhou)
	ror dl, 2 ; pega bit 2 da direita e joga em cf
	jc TIRO_ACERTOU
	mov al, 'x' ; caracter tiro erro
	mov bl, 4 ; cor vermelha
	jmp TIRO_ERROU
	TIRO_ACERTOU: mov al, 'o'
	mov bl, 2 ; cor verde
	; incrementa os acertos
	;fazer
	ror dl, 1; verifica pc2: afundou navio
	jnc NAVIO_NAO_AFUNDOU
	; incrementa os afundados
	;fazer
	NAVIO_NAO_AFUNDOU:
	ror dl, 1; verifica pc3: termina jogo
	jnc TIRO_ERROU ; continua jogo
	call END_GAME
	
	TIRO_ERROU:
	call ESC_CHAR
	
	; incrementa os tiros
	mov dx, 0441h
	call MOV_CURSOR
	;fazer
	mov ax, 1 ; tiros feitos
	mov bl, 7
	call ESC_INT_21
	
	;jmp TESTE ; teste varios tiros
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

TIRO_RECEBE proc
	push dx
	
	mov cx, 10
	TESTE: mov dx, 7h ; beep 7h ascii
	call ESC_CHAR_21
	;call DELAY
	loop TESTE
	
	pop dx
	ret
endp

INIT_GAME proc ; inicia o jogo, solicitando quem comeca
	RODADAS: call TIRO_ENVIA
	call TIRO_RECEBE
	jmp RODADAS
	ret
endp

END_GAME proc
	
	call EXIT
endp

INICIO:	mov ax, @data ; carrega valor inicial da stack
	mov ds, ax
	call DEFINE_MODO
	
	call PRINT_TABLES
	call INIT_NAVIOS
	call INIT_GAME
	
	; teste
	
	
	call EXIT
end INICIO
