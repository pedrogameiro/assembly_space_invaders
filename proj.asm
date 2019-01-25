; *********************************************************************************
; *
; * IST-UTL
; *
; *********************************************************************************
; *********************************************************************************
; *
; * Modulo: 	Proj.asm
; * Descri��o : Este programa consiste num jogo de defesa antia�rea. Recorrendo a dois teclados, 
; *		um f�sico e um virtual, podemos controlar um canh�o que dispara balas contra bombas que est�o a cair. 
; * 		Cada bomba que chegar ao ch�o remove uma vida de um total de 6 vidas. O score m�ximo de bombas
; *		que podemos destruir � 999. O canh�o � composto por dois pixeis acesos, um em cima do outro na parte inferior do PIXEL_SCREEN
; *		(ecr� onde o jogo � apresentado). As bombas s�o compostas por 3 pixeis acesos na horizontal 
; *		que vao descendendo pelo PIXEL_SCREEN at� serem destru�das pelas balas que ascendem do canh�o, ou quando chegam ao ch�o. 
; *		Quando chegam ao ch�o desaparecem com uma explos�o. 
; *		Isto foi um projecto de Arquitectura de computadores do IST realizado no segundo semestre de 2012.
; *		
; *
; *
; *		
; *
; *
; *
; *
; * Nota : R8 ir� possuir, durante a execu��o do c�digo, o valor da �ltima tecla pressionada pelo teclado virtual.
; * 	   R9 ir� possuir, durante a execu��o do c�digo, os valores de vari�veis de mem�ria das seguintes rotinas:
; *		* canhao
; *		* bala
; *		* bomba
; *	   R10 ir� funcionar, durante a execu��o do c�digo, como um contador a ser usado para a cria��o de valores aleat�rios.
; *
; *	Feito por:
; *	Pedro Gameiro N 72617
; *	Nuno Oliveira N 73915
; *	Jos� Martins  N 66378
; *
; *********************************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************

M1_RCU		EQU	6000H		; Registo controlo da MUART-1
M1_REP		EQU	6002H		; Registo estado da MUART-1
M1_RD1		EQU	6004H		; Registo dados do canal 1 da MUART-1 (porto de Rx)
M1_RD2		EQU	6006H		; Registo dados da canal 2 da MUART-1 (porto de Tx)
PIXEL_BASE	EQU	4000H		; Endere�o da primeira posi��o do PIXEL SCREEN.
PIXEL_FIM	EQU	407FH		; Endere�o da ultima posi��o do PIXEL SCREEN.
POUT_1		EQU	7000H		; Endere�o do display.
POUT_2		EQU	9000H		; Endere�o do teclado para acessos de escrita.
PIN		EQU	0A000H		; Endere�o do teclado para acessos de leitura e do rel�gio 1.

TEC_MU_CANH_E	EQU	61H		; 61H corresponde ao valor "a" em ASCII.
TEC_MU_CANH_D	EQU	64H		; 64H corresponde ao valor "d" em ASCII.
TEC_MU_FIRE	EQU	20H		; 20H corresponde ao valor de "SPACE" em ASCII.
TEC_MU_PAUSE	EQU	70H		; 70H corresponde ao valor de "p" em ASCII.
TEC_MU_END	EQU	1BH		; 1BH corresponde ao valor de "ESQ" em ASCII.
TEC_MU_START	EQU	0AH		; 0AH corresponde ao valor de "ENTER" em ASCII.

TEC_END		EQU	3H		; Tecla associada � opera��o de terminar o jogo.
TEC_PAUSE	EQU	1H		; Tecla associada � opera��o de colocar em pausa o jogo.
TEC_START	EQU	0H		; Tecla associada � opera��o de iniciar e reiniciar o jogo.
TEC_FIRE	EQU	0EH		; Tecla associada � opera��o de disparar no jogo.
TEC_CANH_E	EQU	0CH		; Tecla associada � opera��o de deslocar o canh�o para a esquerda no jogo.
TEC_CANH_D	EQU	0DH		; Tecla associada � opera��o de deslocar o canh�o para a direita no jogo.

VAL_NULO	EQU	0FFFFH		; Constante usada para indentificar valores neutros.
RITM_BOMBAS	EQU	5d		; Constante que controla o ritmo do aparecimentos de bombas(quanto maior a constante menor o ritmo).
NUM_VIDAS	EQU	6d		; N�mero de vidas inicias do jogo.

MAX_PS		EQU	31d		; Posi��o m�xima decimal do PIXEL SCREEN.
MIN_PS		EQU	0d		; Posi��o m�nima decimal do PIXEL SCREEN.

; *********************************************************************************
; * DADOS
; *********************************************************************************

PLACE	1000H
TABLE	100H		
stackpointer:				; Tabela reservada para uso da pilha.

bte_tab:	WORD	int0		; Endere�os das rotinas de interrup��o.
		WORD	int1
		WORD	int2
		WORD	int3

ref_balas:	WORD	0H		; Valor correspondente ao n�mero actual de balas em jogo(n�mero m�ximo 8).
tab_balas:	TABLE	8d		; Tabela com a localiza��o vertical e horizontal das balas em jogo(n�mero m�ximo 8).	

			
ref_bombas:	WORD	0H		; Valor correspondente ao n�mero actual de bombas em jogo(n�mero m�ximo 8).
tab_bombas:	TABLE	8d		; Tabela com a localiza��o vertical e horizontal das bombas em jogo(n�mero m�ximo 8).

tab_teclas:	TABLE	16d		; Tabela destinada a conter os endere�os das rotinas associadas �s teclas recebidas pela "PUSH MATRIX".
		
tab_tec_muart:	WORD	canhao_esq	; Tabela com os endere�os das rotinas associadas �s teclas recebidas pelo "MUART".
		WORD	canhao_dir
		WORD	fire_bala
		WORD	pause
		WORD	termina
		WORD	reboot
		WORD	fire_bala
		
string0:	STRING	0AH,09H,"****  Iniciou o jogo, boa sorte!   ****",0
string1:	STRING	0AH,09H,"****  Reiniciou o jogo, boa sorte! ****",0
string2:	STRING	0AH,0AH,09H,09H,">>>> GAME OVER <<<<",0
string3:	STRING	0AH,09H,"****    O jogo entrou em pausa.    ****",0
string4:	STRING	0AH,09H,"****    O jogo saiu da pausa.      ****",0
string5:	STRING	0AH,09H,"IST-UTL",0AH,09H,"+++ Jogo de defesa anti-aerea +++",0AH,09H,"Feito por:",0AH,09H,"Pedro Gameiro N 72617",0AH,09H,"Jose Martins N 66378",0AH,09H,"Nuno Oliveira N 73915",0AH,0
string6:	STRING	0AH,09H,"****    O jogo foi terminado       ****",0
string_score:	STRING	0AH,09H,"++++ Conseguiu destruir XXX bombas! ++++",0	;O ultimo "X" est� a ocupar o 28� byte da string.
string7:	STRING	0AH,09H,"++++   Nao destruiu nenhuma bomba!   ++++",0
		
pos_canhao:	WORD	13d		; Valor correspondente � localiza��o actual do canh�o na horizontal.
tecla: 		WORD	VAL_NULO	; Valor em mem�ria da �ltima tecla pressionada.
tec_muart:	WORD	VAL_NULO

vidas:		WORD	0		; Valor correspondente ao n�mero de vidas restantes durante o jogo, que ser� representada no display
					; ao longo do jogo.
score:		WORD	0		; Valor correspondente ao n�mero de bombas destru�das ao longo do jogo.

					
int3_var:	WORD	0H		; Vari�vel usada pela rotina "int3", para a escrita de strings no terminal ligado a "MUART".

; *********************************************************************************
; * C�digo
; *********************************************************************************
Place	0

	MOV SP, stackpointer		; Inicializa��es necess�rias.
	MOV BTE, bte_tab
	EI				; Activa as interrup��es relacionadas com a MUART.
	EI2
	EI3
	
	CALL preenche_tab_tec
	CALL inicializa_tabs		; Coloca os valores iniciais nas tabelas referentes �s bombas e �s balas.
	CALL limpa_PS			; Desliga todos os pixeis do PIXEl-SCREEN.
	CALL ini_MUART			; Inicializa a MUART.
	MOV R2, string5
	CALL muart_out			; Imprime a string5 no terminal.
	
	CALL start			; Espera que o utilizador pressione a tecla para iniciar o jogo.
	MOV R2, string0			
	CALL muart_out			; Imprime a string0 no terminal.
	
inicio:					
	MOV R1, 13d
	CALL desenha_canhao		; Desenha o canh�o na posi��o 13 horizontal e 0 vertical.
	MOV R1, NUM_VIDAS	
	CALL display			; Inicia as vidas, tanto em mem�ria como no display.
	EI0				; Activa as interrup��es ligadas aos clocks 1 e 2.
	EI1
	
corpo:					; Corpo principal do c�digo.
	BIT R9, 0			; Verifica, usando o bit 0 de "R9" como vari�vel de estado, se ocorreu um flanco ascendente 
	JNZ corpo_bala			; no rel�gio 1, desde a �ltima iterac��o. Caso tenha, corre a itera��o respons�vel pelas balas.
corpo1:
	BIT R9, 3			; Verifica, usando o bit 3 de "R9" como mem�ria de estado, se ocorreu um flanco ascendente 
	JNZ corpo_bomba			; no rel�gio 2, desde a �ltima itera��o. Caso tenha, corre a itera��o respons�vel pelas bombas.	
	JMP corpo_tec

corpo_bala:				; Chama a rotina bala e coloca o bit 0 de "R9" a 0.
	CALL bala
	CLR R9, 0
	JMP corpo1

corpo_bomba:				; Chama a rotina bomba e coloca o bit 3 de "R9" a 0.
	CALL bomba


	
	MOV R0, R10			; Verifica se o contador "R10" possui um valor m�ltiplo da vari�vel "RITM_BOMBAS".
	MOV R2, RITM_BOMBAS		; Caso se verifique, executa a rotina "bomba_nova"(Tem como objectivo coordenar 
	MOD R0, R2			;o ritmo de aparecimento de bombas).
	JNZ corpo_bomba_fim
	
	CALL bomba_nova
corpo_bomba_fim:			
	CLR R9, 3
	JMP corpo_tec

corpo_tec:
	CALL LE_tec			; Determina se alguma tecla foi pressionada pelo teclado virtual.
					; caso se verifique, coloca o respectivo valor na vari�vel "tecla".
								
	MOV R0, tecla			; Coloca o valor da tecla pressionada em "R3".
	MOV R3, [R0]
	
	CMP R3, R8			; Verifica se a tecla pressionada continua pressionada.
	JEQ corpo_tec2			; Se n�o continuar pressionada actualiza "R8" com o valor da nova tecla, caso esteja n�o verifica se a tecla
	MOV R8, R3			; corresponde a alguma opera��o.
	
	CLR R9, 1			; Caso a tecla n�o continue pressionada, coloca as vari�veis de estado das rotinas "canhao_esq"
	CLR R9, 2			; e "canhao_dir" a 0, de forma a parar o movimento do canh�o caso este se estivesse a mover.
	
	CMP R3, -1			; Verifica se "R3" possui o "VAL_NULO", ou seja, se foi pressionada uma tecla
	JZ corpo_tec2			; ou se apenas foi detectada pela rotina "LE_tec" a sua inexist�ncia.
	
	MOV R0, tab_teclas		; Executa, usando a "tab_teclas" como uma tabela de rotinas, a rotina correspondente � tecla pressionada.
	SHL R3, 1			; Multiplica "R3" por 2.
	ADD R0, R3
	MOV R3, [R0]
	CALLF R3			; Faz a chamada � rotina correspondente � tecla pressionada no teclado virtual usando "CALLF"
					; de forma a ser f�cil �s rotinas, ao qual n�o seja necess�rio retornar, apagar o valor de "RL".
corpo_tec2:				
	MOV R2, tec_muart		; Executa as rotinas correspondentes ao input do teclado f�sico pelo MUART,
	MOV R3, [R2]			; colocando "VAL_NULO" na vari�vel "tec_muart" para marcar como tratada a tecla.
	
	CMP R3, -1			; Verifica se o valor da tecla obtido corresponde ao "VAL_NULO", ou, se existe alguma tecla
	JZ corpo			; ainda n�o processada.
	MOV R0, tab_tec_muart
	ADD R0, R3
	MOV R3, [R0]
	CALLF R3			; Faz a chamada � rotina correspondente � tecla pressionada no teclado f�sico usando "CALLF"
                                        ; de forma a ser f�cil �s rotinas, ao qual n�o seja necess�rio retornar, apagar o valor de "RL".
					
	MOV R3, VAL_NULO
	MOV [R2], R3	 

	JMP corpo

tec_canhao_esq:
	SET R9, 1			; Coloca o bit 2 de "R9" a 1 para permitir a execu��o da rotina "canhao_esq" pela int0.
	RETF
	
tec_canhao_dir:
	SET R9, 2			; Coloca o bit 2 de "R9" a 1 para permitir a execu��o da rotina "canhao_dir" pela int0.
	RETF
no_tec:					; Apenas retorna para o valor do "RL" usado para teclas n�o associadas a nenhuma opera��o.
	RETF
	
; *********************************************************************************
;* INTERRUP��ES
; *********************************************************************************
	
;* -- int0 ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina � executada pela interrup��o "EI0".
;*	      � activada pelo rel�gio-1 no flanco ascendente.
;* 	      Incrementa o registo "R10" para futura utiliza��o pela rotina "bomba".
;*	      Executa, se uma das teclas correspondentes ao deslocamento do canh�o tiver sido pressionada,
;*	      A rotina correspondente.
;*
;* Par�metros: R9(Variaveis de estado), R10(Contador)
;* Retorna: --
;* Destr�i: --
;* Notas: --
int0:
	BIT R9, 2			; Se o 2� bit de "R9" estiver a 1, significa que a tecla correspondente ao
	JNZ int0_canhao_D		; deslocamento do canh�o para a direita.
	
	BIT R9, 1
	JNZ int0_canhao_E		; Se o 1� bit de "R9" estiver a 1, significa que a tecla correspondente ao
	JMP int0_fim			; deslocamento do canh�o para a esquerda.
	
int0_canhao_D:
	CALLF canhao_dir		; Chama a rotina respons�vel pelo deslocamento do canh�o para a direita.
	JMP int0_fim
	
int0_canhao_E:
	CALLF canhao_esq		; Chama a rotina respons�vel pelo deslocamento do canh�o para a esquerda.
	JMP int0_fim
int0_fim:
	ADD R10, 1			; Adiciona 1 ao contador "R10".
	SET R9, 0			; Activa a vari�vel de estado usada para a execu��o da rotina bala.

	RFE

;* -- int1 ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina � executada pela interrup��o "EI1".
;*            � activada pelo rel�gio-2 no flanco ascendente.
;*	      Coloca o bit 3 de "R9" a 1 para futura utiliza��o pela rotina "bomba" e incrementa o contador "R10".
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
int1:
	ADD R10, 2			; Adiciona 2 ao contador "R10".
	SET R9, 3			; Activa a vari�vel de estado usada para a execu��o da rotina bomba.
	RFE
	
;* -- int2 ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina � activada pela interrup��o "EI2" que, por sua vez,
;*            � activada pelo sinal da MUART que indica a exist�ncia de um byte ainda n�o lido.
;*	      Coloca na vari�vel "tec_muart" o �ndice da tabela "tab_tec_muart" correspondente � rotina
;*	      a ser executada pela tecla pressionada no teclado fisico.
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --	
int2:
	PUSH	R0
	PUSH	R1
	PUSH	R3

	MOV	R0, M1_RD1	; Registo de dados (canal 1)
	MOVB	R3, [R0]	; Caracter que chegou
	MOV 	R0, tec_muart
	
	MOV	R1, TEC_MU_CANH_E ; Verifica se o valor recebido corresponde � tecla associada � desloca��o do canh�o para a esquerda.
	CMP	R3, R1
	JEQ	int2_esq
	
	MOV	R1, TEC_MU_CANH_D ; Verifica se o valor recebido corresponde � tecla associada � desloca��o do canh�o para a direita.
	CMP	R3, R1
	JEQ	int2_dir
	
	MOV	R1, TEC_MU_FIRE   ; Verifica se o valor recebido corresponde � tecla associada ao disparo de uma bala.
	CMP	R3, R1
	JEQ	int2_fire
	
	MOV	R1, TEC_MU_PAUSE ; Verifica se o valor recebido corresponde � tecla associada a colocar o jogo em pausa.
	CMP	R3, R1
	JEQ	int2_pause
	
	MOV	R1, TEC_MU_END  ; Verifica se o valor recebido corresponde � tecla associada a terminar o jogo.
	CMP	R3, R1
	JEQ	int2_end
	
	MOV	R1, TEC_MU_START ; Verifica se o valor recebido corresponde � tecla associada a iniciar e reiniciar o jogo.
	CMP	R3, R1
	JEQ	int2_start
	JMP int2_fim
int2_esq:			; Coloca em "tec_muart" o valor do �ndice da tabela "tab_tec_muart" correspondente � tecla.
	MOV R3, 0d
	MOV [R0], R3
	JMP int2_fim	
int2_dir:			; Coloca em "tec_muart" o valor do �ndice da tabela "tab_tec_muart" correspondente � tecla.
	MOV R3, 2d
	MOV [R0], R3
	JMP int2_fim
int2_fire:			; Coloca em "tec_muart" o valor do �ndice da tabela "tab_tec_muart" correspondente � tecla.
	MOV R3, 4d
	MOV [R0], R3
	JMP int2_fim
int2_pause:			; Coloca em "tec_muart" o valor do �ndice da tabela "tab_tec_muart" correspondente � tecla.
	MOV R3, 6d
	MOV [R0], R3
	JMP int2_fim
int2_end:			; Coloca em "tec_muart" o valor do �ndice da tabela "tab_tec_muart" correspondente � tecla.
	MOV R3, 8d
	MOV [R0], R3
	JMP int2_fim
int2_start:			; Coloca em "tec_muart" o valor do �ndice da tabela "tab_tec_muart" correspondente � tecla.
	MOV R3, 10d
	MOV [R0], R3
	JMP int2_fim
	
int2_fim:			; Sai repondo os registos usados.
	POP	R3
	POP	R1		
	POP	R0
	RFE
	
;* -- int3 ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina � activada pela interrup��o "EI3", que por sua vez
;*            � activada pelo sinal da MUART quando esta est� pronta a receber um byte.
;*	      Imprime em cada intera��o um caracter da string cujo o endere�o esteja em "int3_var".
;*	      
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
;*	  
int3:
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV	R0, int3_var	
	MOV	R2, [R0]
	MOVB	R1, [R2]	; Coloca em "R1" o caracter a imprimir.
	ADD	R2, 1
	MOV	[R0], R2
	
	CMP R1, 0		; Verifica se a string j� terminou.
	JEQ int3_fim
	MOV	R0, M1_RD2	; Registo de dados (canal 2).
	MOVB	[R0], R1 	; Envia o caracter.
int3_fim:
	POP R2
	POP R1
	POP R0
	RFE
	
; *********************************************************************************
;* ROTINAS
; *********************************************************************************

;* -- start ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina fica em espera activa enquanto n�o for pressionada a tecla associada ao in�cio do jogo.
;*	      Tem como prop�sito dar ao utilizador a possiblidade de iniciar o jogo.
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
start:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R2, tec_muart
start1:				; Fica em espera activa at� que o utilizador pressione, ou pelo teclado virtual, ou pelo fisico
	MOV R0, tecla		; a tecla associada ao iniciar do jogo.
	CALL LE_tec
	MOV R1, [R0]
	CMP R1, TEC_START
	JEQ start_fim
	
	MOV R1, [R2]
	MOV R0, 10d
	CMP R1, R0
	JEQ start_fim
	
	JMP start1
	
start_fim:			; Coloca o valor nulo na vari�vel "tec_muart", de forma a marcar a tecla pressionada como usada.
	MOV R1, VAL_NULO
	MOV [R2], R1

	MOV R1, 1000d		; Chama a rotina "espera" de forma a dar tempo ao utilizador para come�ar a jogar.
	CALL espera
	POP R2
	POP R1
	POP R0
	RET

;* -- termina ----------------------------------------------------------------
;* 
;* Descri��o: Termina o jogo limpando o PIXEl-SCREEN e colocando o Dysplay a 0.
;*	      Para sair da rotina � necess�rio pressionar a tecla associada ao iniciar do jogo.
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: De forma a ser uma rotina que pode ser executada com a instru��o "CALLF"
;*	  esta coloca o registo "RL" a zero antes de executar JMP para o "inicio".

termina:				
	DI0
	DI1				; Desactiva as interrup��es.

	MOV R2, string6			; Imprime no terminal a string6.
	CALL muart_out
	MOV R1, 1000d
	CALL espera			; Coloca o c�digo brevemente em pausa de forma a dar tempo � string6 de ser impressa no terminal.
	
	CALL imprime_score
	CALL limpa_PS
	CLR R1
	CALL display			; Coloca as vidas e o display a zero.
	CALL start
	CLR RL				; Coloca o registo "RL" pois a rotina n�o efectua nenhum "RETF" e por isso n�o o vai usar o seu valor.
	CALLF reboot			; Efectua um salto para "reboot", cuja rotina n�o efectua um "RETF".
	
;* -- reboot ----------------------------------------------------------------
;* 
;* Descri��o: Reinicia o jogo limpando todas as vari�veis e registos necess�rios,
;*	      executa a fun��o "espera" de forma a dar ao jogador tempo para se preparar.
;*	      Regressa para o "inicio".
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: De forma a ser uma rotina que pode ser executada com a instru��o "CALLF"
;*	  ela coloca o registo "RL" a zero antes de executar JMP para o "inicio".

reboot:				
	DI0			; Desactiva as interrup��es relacionadas com os clocks.
	DI1
	MOV R2, string1		; Imprime no terminal a string1.
	CALL muart_out
	CALL limpa_var		; Limpa as vari�veis necess�rias.
	MOV R1, 2000d		
	CALL espera
	MOV R2, tec_muart	; Coloca o valor nulo na vari�vel tec_muart, de forma a marcar a tecla pressionada como usada.
	MOV R1, VAL_NULO
	MOV [R2], R1
	CLR RL			; Coloca o registo "RL" pois a rotina n�o efectua nenhum "RETF" e por isso n�o vai usar o seu valor.
	JMP inicio

	
;* -- pause ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina fica em espera activa enquanto n�o for pressionada a tecla associada � pausa.
;*	      Tem como prop�sito colocar o jogo em pausa .
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
pause:
	DI0			; Desactiva as interrup��es associadas aos clocks.
	DI1
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV R2, string3		; Imprime no terminal a string3.
	CALL muart_out
	MOV R0, tecla
	MOV R2, tec_muart
	MOV R1, VAL_NULO	; Coloca VAL_NULO em "tec_muart" marcando a �ltima tecla pressionada como usada.
	MOV [R2], R1
	
pause1:				; Espera que a tecla associada � pausa pare de ser pressionada se esta estiver.
	CALL LE_tec
	MOV R1, [R0]
	CMP R1, TEC_PAUSE
	JEQ pause1
	
	MOV R1, 1500d		
	CALL espera
pause2:				; Fica em espera activa enquanto n�o for pressionada a tecla associada � pausa.
	CALL LE_tec
	MOV R1, [R0]
	CMP R1, TEC_PAUSE
	JEQ pause_fim
	
	MOV R1, [R2]		
	CMP R1, 6d		; Verifica se a tecla associada � pausa foi pressionada via MUART.
	JEQ pause_fim
	
	JMP pause2
	
pause_fim:
	MOV R2, string4		; Imprime no terminal a string4.
	CALL muart_out
	POP R2	
	POP R1
	POP R0
	EI0			; Activa as interrup��es associadas aos clocks.
	EI1
	RETF
	
;* -- limpa_PS ----------------------------------------------------------------
;* 
;* Descri��o: Desliga todos os pixeis do PIXEL-SCREEN.
;*	      
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
limpa_PS:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R2, PIXEL_FIM	; PIXEL_FIM corrresponde ao endere�o do byte de pixeis do PIXE-SCREEN.
	MOV R0, PIXEL_BASE	; Coloca o endere�o inicial do PIXEL-SCREEN em "R0".
	CLR R1

limpa_PS_1:			; Desliga, a cada itera��o, um byte de pixeis do PIXEL-SCREEN, at� chegar ao �ltimo.
	MOVB [R0], R1	
	ADD R0, 1
	CMP R0, R2
	JLE limpa_PS_1
	
	POP R2
	POP R1
	POP R0
	RET

;* -- inicializa_tabs ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina coloca valores neutros em todas as entradas das tabelas tab_balas e tab_bombas.
;*	      
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: R0, R1, R2
;* Notas: --
inicializa_tabs:
	MOV R0, tab_balas
	MOV R2, 8d
	MOV R1, VAL_NULO
inicializa_tabs_balas:		; Preenche as 8 entradas da tabela "tab_balas" com "VAL_NULO".
	MOV [R0], R1
	ADD R0, 2
	SUB R2, 1
	JNZ inicializa_tabs_balas
	
	MOV R0, tab_bombas
	MOV R2, 8d
inicializa_tabs_bombas:		; Preenche as 8 entradas da tabela "tab_balas" com "VAL_NULO".
	MOV [R0], R1
	ADD R0, 2
	SUB R2, 1
	JNZ inicializa_tabs_bombas
	RET

;* -- espera ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina coloca o programa em espera, � tanto maior o tempo de espera quanto o valor de R1.
;*	      
;*	      
;*
;* Par�metros: R1 ( Quantidade de itera��es a executar)
;* Retorna: --
;* Destr�i: R1
;* Notas: --
espera:
	NOP
	SUB R1, 1		; A cada itera��o decrementa o valor de "R1", quando este for igual a zero retorna.
	JNZ espera
	RET

;* -- display ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina actualiza o display com o valor de R1 e actualiza o valor da vari�vel "vidas" com esse valor.
;*	      
;*	      
;* 
;* Par�metros: R1( Valor a actualizar)
;* Retorna: --
;* Destr�i: --
;* Notas: --
display:
	PUSH R0
	PUSH R1
	MOV R0, POUT_1		; Endere�o correspondente ao dysplay hexadecimal.
	MOVB [R0], R1
	MOV R0, vidas
	MOV [R0], R1
	POP R1
	POP R0
	RET
	
;* -- limpa_var ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina coloca os valores originais em "ref_balas", "ref_bombas", "pos_canhao", "score",
;*	     nas tabelas "tab_balas" e "tab_bombas" e limpa o PIXEL-SCREEN.
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i:  R1, R9, R10.
;* Notas: Os registos R9 e R10 retornam com o valor 0000H.
limpa_var:
	MOV R0, ref_balas		; Coloca a zero a vari�vel com o valor da quantidade de balas em jogo.
	MOV R1, 0H
	MOV [R0], R1
	MOV R0, ref_bombas		; Coloca a zero a vari�vel com o valor da quantidade de bombas em jogo.
	MOV [R0], R1
	MOV R0, pos_canhao		; Coloca o valor inicia em "pos_canhao".
	MOV R1, 13d
	MOV [R0], R1
	MOV R0, score			; Reinicia o score.
	CLR R1
	MOV [R0], R1
	CALL limpa_PS			; Desliga todos os pixeis do PIXEl_SCREEN.
	CALL inicializa_tabs		; Coloca os valores originais nas tabelas "tab_bombas" e "tab_balas".
	CLR R9
	CLR R10
	RET

;* -- ini_MUART ----------------------------------------------------------------
;* 
;* Descri��o: Inicializa a MUART-1 permitindo o acesso � mesma.
;*	      
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i:  --
;* Notas: --
ini_MUART:	PUSH	R0
		PUSH	R1
		MOV	R0, M1_RCU	; prepara acesso RCU
		MOV	R1, 00H
		MOVB	[R0], R1	; programa factor de multiplic. de 16
		POP	R1
		POP	R0
		RET

;* -- muart_out ----------------------------------------------------------------
;* 
;* Descri��o: Imprime no terminal, ligado a MUART, o primeiro byte para o qual "R2" endere�a.
;*	      Quando este terminar de ser impresso, a rotina de interrup��o "int3" encarregar-se-� de imprimir
;*	     os seguintes.
;*
;* Par�metros: R2 (Endere�o da string)
;* Retorna: --
;* Destr�i:  --
;* Notas: --
muart_out:	PUSH	R0
		PUSH	R1
		
		MOV R0, int3_var	; Coloca em "int3_var" o valor do endere�o do proximo byte para uso pela rotina "int3".
		ADD R2, 1
		MOV [R0], R2
		SUB R2, 1
		
		MOV	R0, M1_RD2	; Registo de dados (canal 2).
		MOVB	R1, [R2]
		MOVB	[R0], R1 	; Envia o primeiro caracter.
		
		POP	R1		; Sai, repondo os registos usados.
		POP	R0
		RET
		
;* -- imprime_score ----------------------------------------------------------------

;* 
;* Descri��o: Imprime no terminal a string "string_score", trocando nesta, "XXX"
;*	     pelo valor de "score".
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i:  --
;* Notas: --
imprime_score:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4

	MOV R0, score
	MOV R1, [R0]
	MOV R0, string_score
	MOV R2, 28d			; O ultimo "X" da string encontra-se no 28� byte desta
	ADD R0, R2			; Somando 28d ao endere�o inicial da string, � obtido o endere�o do �ltimo dos "X"s.
	
	CMP R1, 0			; Verifica se o score foi igual a 0.
	JEQ imprime_score_zero
	
	MOV R2, 999d			; Verifica se o score ultrapassou ou atingiu o seu limite de 3 d�gitos.
	CMP R1, R2
	JGE imprime_score_max
	MOV R3, 10d
	MOV R4, 30H
	MOV R2, R1
	
	MOD R2, R3			; Escreve na string "string_score" o d�gito de menor peso do score.
	ADD R2, R4
	MOVB [R0], R2
	SUB R0, 1
	
	DIV R1, R3			; Escreve na string "string_score" o segundo d�gito de menor peso.
	MOV R2, R1
	MOD R2, R3
	ADD R2, R4
	MOVB [R0], R2
	SUB R0, 1
	
	DIV R1, R3			; Escreve na string "string_score" o d�gito de maior peso.
	ADD R1, R4
	MOVB [R0], R1
	
	MOV R2, string_score		; Executa a rotina "muart_out" para que esta escreva a string "string_score" j� alterada.
	CALL muart_out
	JMP imprime_score_fim
	
imprime_score_zero:
	MOV R2, string7			; Imprime a "string7".
	CALL muart_out
	JMP imprime_score_fim
	
imprime_score_max:			; Altera a string "string_score" com o score maximo(999).
	MOV R1, 39H
	MOVB [R0], R1
	SUB R0, 1
	MOVB [R0], R1
	SUB R0, 1
	MOVB [R0], R1
	
	MOV R2, string_score		; Executa a rotina "muart_out" para que esta escreva a string "string_score" j� alterada.
	CALL muart_out
	
imprime_score_fim:
	POP R4
	POP R3
	POP R2
	POP R1
	POP R0
	RET	

;* -- bomba_nova ----------------------------------------------------------------
;* 
;* Descri��o: Lan�a em jogo uma nova bomba numa coluna aleat�ria, se n�o houverem j� em jogo 8 bombas.
;*	      
;*
;* Par�metros: R10 (Contador usado para cria��o de valores aleat�rios)
;* Retorna: --
;* Destr�i: --
;* Notas: --
bomba_nova:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV R0, tab_bombas
	MOV R2, ref_bombas
	
	MOV R3, [R2]		
	CMP R3, 7			; Verifica se j� existem em jogo 8 bombas.
	JGT bomba_nova_fim
	
	ADD R3, 1		
	MOV [R2], R3
bomba_nova_ciclo:			; Procura na tabela "tab_bombas" uma entrada que n�o esteja a ser usada.
	MOV R2, [R0]		
	CMP R2, -1			; Verifica se a entrada cont�m o VAL_NULO.
	JZ bomba_nova1
	
	ADD R0, 2
	JMP bomba_nova_ciclo

bomba_nova1:				; Escreve na entrada encontrada uma nova bomba, na posi��o vertical 0 e
	MOV R2, R10			;calcula atrav�s de "R10" um valor aleat�rio para a posi��o horizontal,
	MOV R1, 8			; usando a formula, sem alterar o seu valor: ("R10" mod 8)*4
	MOD R2, R1
	SHL R2, 2			; Multiplica o "R2" por 4.	
	MOV R1, R2
	CLR R2
	MOV [R0], R1
	MOV R3, 1			; "R3" = 1, indica a rotina "escreve_PS" para desenhar uma bomba no PIXEL_SCREEN.
	CALL escreve_PS			; Desenha no PIXEL_SCREEN a bomba na sua posi��o inicial.
bomba_nova_fim:
	POP R3
	POP R2
	POP R1
	POP R0
	RET


;* -- bomba ----------------------------------------------------------------
;* 
;* Descri��o: Executa a itera��o das bombas, descendo-as uma posi��o no PIXEL_SCREEN.
;*	      Se atingirem o fim do PIXEL_SCREEN, desenha uma explos�o, removendo uma vida.
;*	      Quando terminar a explos�o, remove-as actualizando a cada mudan�a do seu estado		
;*	      o seu valor na tabela "tab_bombas".
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: Cada bomba que atinge o fim do PIXEL_SCREEN explode duas vezes, uma por cada execu��o da rotina.
bomba:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	
	MOV R0, ref_bombas	
	MOV R4, [R0]
	
	AND R4, R4			; Verifica se existem balas em jogo.
	JZ bomba_fim
	MOV R0, tab_bombas
bomba_ciclo:				; Procura na tabela "tab_bombas" cada uma das bombas existentes em jogo.
	MOV R2, [R0]
	CMP R2, -1			; Verifica se a entrada cont�m o "VAL_NULO".
	JNZ bomba_desce
	
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_desce:				; Desce, uma posi��o no PIXEL_SCREEN, a bomba em quest�o e, caso esta chegue � �ltima posi��o
	MOVB R2, [R0]			;explode-a.
	MOV R1, [R0]
	MOV R3, 00FFH
	AND R1, R3
	MOV R3, MAX_PS
	
	BIT R2, 6
	JNZ bomba_apaga			; Caso a bomba j� tenha chegado � �ltima posi��o e explodido duas vezes, 
					;remove a bomba da tabela e apaga-a do "PIXEL SCREEN".
	BIT R2, 7
	JNZ bomba_explode2		; Caso a bomba j� tenha chegado ao fundo do "PIXEL SCREEN", na �ltima itera��o, e executado uma explos�o, 
					;salta para "bomba_explode2".
	CMP R2, R3
	JEQ bomba_explode		; Caso a bomba nesta itera��o atinga o fim do "PIXEL_SCREEN", salta para "bomba_explode".
	
	MOV R3, 1			; Apaga a bomba na posi��o actual.
	CALL escreve_PS
	ADD R2, 1
	CALL escreve_PS			; Desenha a bomba na posi��o seguinte
	MOVB [R0], R2
	
	SUB R4, 1			; Marca a bomba como tratada.
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_explode:				; Apaga a bomba na posi��o actual.
	MOV R3, 1
	CALL escreve_PS
	
	SET R2, 7			; Marca a bomba como explodida uma vez na tabela.
	MOVB [R0], R2
	CALL explosao1			; Desenha a explos�o
	
	SUB R4, 1			; Marca a bomba como tratada e verifica se era a �ltima bomba da tabela "tab_bombas".
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_explode2:
	
	SET R2, 6			; Marca a bomba como explodida duas vezes.
	MOVB [R0], R2
	CALL explosao1			; Apaga no "PIXEL_SCREEN" a primeira explos�o.
	CALL explosao2			; Desenha no "PIXEL_SCREEN" a segunda explos�o.
	
	SUB R4, 1			; Marca a bomba como tratada e verifica se era a �ltima bomba da tabela "tab_bombas".
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_apaga:				
	CALL explosao2			; Apaga, do PIXEL_SCREEN, a segunda explos�o.

	MOV R1, VAL_NULO		; Remove a bala da tabela "tab_bombas".
	MOV [R0], R1
	
	MOV R2, vidas
	MOV R1, [R2]
	SUB R1, 1			; Decrementa uma vida.
	JZ game_over			; Verifica se era a �ltima vida. Caso seja, salta para "game_over".
	
	MOV [R2], R1			; Actualiza as vidas tanto em mem�ria como no display hexadecimal.
	CALL display
	
	MOV R2, ref_bombas		; Actualiza "ref_bombas" com a quantidade de bombas.
	MOV R1, [R2]
	SUB R1, 1
	MOV [R2], R1
	
	SUB R4, 1			; Marca a bomba como tratada e verifica se era a �ltima bomba da tabela "tab_bombas".
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
bomba_fim:
	POP R4
	POP R3
	POP R2
	POP R1
	POP R0
	RET

;* -- explosao1 ----------------------------------------------------------------
;* 
;* Descri��o: Desenha no PIXEL_SCREEN uma explos�o.
;*	     
;*	      
;*
;* Par�metros: R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: --
;* Destr�i: --
;* Notas: No parametro "R2", apenas os primeiros 5 bits de menor peso ser�o usados.
explosao1:
	PUSH R1
	PUSH R2
	
	MOV R3, 1FH			; Coloca a zero todos os bits de "R2", exepto os primeiros 5 de menor peso,
	AND R2, R3			;de forma a retirar os bits que marcam a bomba como explodida na tabela "tab_bombas".
	
	MOV R3, 1
	CALL escreve_PS			; Acende os pixeis que desenham a explos�o.
	SUB R2, 1
	CALL escreve_PS
	SUB R2, 1
	CALL escreve_PS
	CLR R3
	CALL escreve_PS
	ADD R1, 2
	CALL escreve_PS
	SUB R1, 1
	ADD R2, 1
	CALL escreve_PS
	ADD R2, 1
	SUB R1, 1
	CALL escreve_PS
	ADD R1, 2
	CALL escreve_PS
	
	POP R2
	POP R1
	RET
	
;* -- explosao2 ----------------------------------------------------------------
;* 
;* Descri��o: Desenha no PIXEL_SCREEN uma explos�o.
;*
;* Par�metros: R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: --
;* Destr�i: --
;* Notas: No parametro "R2", apenas os primeiros 5 bits de menor peso ser�o usados.
explosao2:
	PUSH R1
	PUSH R2
	
	MOV R3, 1FH			; Coloca a zero todos os bits de "R2", excepto os primeiros 5 de menor peso,
	AND R2, R3			;de forma a retirar os bits que marcam a bomba como explodida na tabela "tab_bombas".
	
	MOV R3, 1
	CALL escreve_PS			; Acende os pixeis que desenham explos�o.
	SUB R2, 1
	CALL escreve_PS
	SUB R2, 1
	CALL escreve_PS
	CLR R3
	ADD R1, 1
	CALL escreve_PS
	ADD R2, 1
	SUB R1, 1
	CALL escreve_PS
	ADD R1, 2
	CALL escreve_PS
	ADD R2, 1
	SUB R1, 1
	CALL escreve_PS
	
	POP R2
	POP R1
	RET

;* -- game_over ----------------------------------------------------------------
;* 
;* Descri��o: Termina o jogo, limpando o "PIXEL-SCREEN" e colocando o Display a 0
;*	     e desactiva as interrup��es "int0" e "int1".
;*	      Para sair da rotina � necess�rio pressionar a tecla associada ao iniciar do jogo.
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: De forma a ser uma rotina que pode ser executada com a instru��o "CALLF",
;*	  esta coloca o registo "RL" a zero antes de saltar para "inicio".

game_over:				
	DI0
	DI1				; Desactiva as interrup��es relacionadas com os clocks.
	
	CALL limpa_PS			; Desliga todos os pixeis do PIXEL_SCREEN.
	CLR R1
	CALL display			; Coloca o display e as vidas a zero.
	
	MOV R2, string2			; Imprime no terminal a string2.
	CALL muart_out
	
	MOV R1, 1000d			; Coloca o c�digo brevemente em pausa de forma a dar tempo � string2 de ser impressa no terminal.
	CALL espera
	
	CALL imprime_score		; Imprime no terminal o score atingido no jogo

	CALL start			; Coloca o c�digo em pausa at� que seja pressionada a tecla associada a reiniciar o jogo.
	CLR RL				; Coloca o registo "RL" pois a rotina n�o efectua nenhum "RETF" e por isso n�o vai usar o seu valor.
	CALLF reboot			; Efectua um "CALLF" para a rotina "reboot", a qual n�o retorna.

;* -- fire_bala ----------------------------------------------------------------
;* 
;* Descri��o: Caso ainda n�o existam em jogo 8 balas, � inicializada uma nova bala na coordenada acima da posi��o
;*	      actual do canh�o, actualizando tanto a tabela correspondente �s posi��es das balas, como o PIXEL SCREEN.
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
fire_bala:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	
	MOV R0, tab_balas
	MOV R2, ref_balas
	
	MOV R3, [R2]			; Verifica se o limite m�ximo de balas(8) em jogo j� foi alcan�ado.
	CMP R3, 7			;caso n�o tenha sido, adiciona 1 ao valor actual de balas em jogo guardado em mem�ria(ref_balas).
	JGT fire_bala_fim
	
	ADD R3, 1		
	MOV [R2], R3

fire_bala_ciclo:			; Procura na tabela "tab_balas" a primeira entrada com o valor neutro (VAL_NULO).
	MOV R2, [R0]		
	CMP R2, -1			; Verifica se a entrada cont�m o VAL_NULO.
	JZ fire_bala1	
	
	ADD R0, 2
	JMP fire_bala_ciclo

fire_bala1:				; Regista na primeira entrada livre da tabela "tab_balas" uma nova bala e desenha-a no PIXEL_SCREEN.
	MOV R3, pos_canhao
	MOV R1, [R3]			; Coloca em "R1" a coordenada horizontal actual do canh�o.
	MOV R2, 29d			; Coloca em "R2" a coordenada vertical correspondente � posi��o imediatamente acima do canh�o.
	
	CLR R3				; Coloca "R3" a zero de forma a indicar a rotina "escreve_PS" para desenhar no PIXEL_SCREEN
	CALL escreve_PS			;um pixel na coordenada dos par�metros "R1"(horizontal) e "R2"(vertical".
	
	SHL R2, 8
	ADD R2, R1
	MOV [R0], R2			; Coloca em mem�ria a informa��o correspondente � coordenada da bala.

fire_bala_fim:				; Termina a rotina.
	POP R3
	POP R2
	POP R1
	POP R0
	RETF

;* -- bala ----------------------------------------------------------------
;* 
;* Descri��o: Sobe todas as balas em jogo uma posi��o, actualizando o valor das suas coordenadas na tabela
;*	      "tab_balas". Caso alguma bala atinja uma bomba, ambas s�o removidas tanto do PIXEL_SCREEN como
;*	      das tabelas onde reside a informa��o das suas coordenadas e � incrementado 1 ao score.
;*	      As balas que cheguem ao topo do PIXEL_SCREEN s�o simplesmente removidas.
;*
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
bala:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	
	MOV R0, ref_balas		; Verifica se existe alguma bala em jogo, salta para bala_fim caso n�o exista.
	MOV R4, [R0]
	MOV R0, tab_balas
	
	AND R4, R4
	JZ bala_fim
bala_ciclo:				; Localiza na tabela "tab_balas" as entradas correspondentes a cada uma das balas em jogo.

	MOV R2, [R0]
	CMP R2, -1			; Verifica se a entrada cont�m o VAL_NULO.
	JNZ bala_estado
	
	ADD R0, 2
	JMP bala_ciclo
	
bala_estado:
	MOVB R2, [R0]
	MOV R1, [R0]
	MOV R3, 00FFH		
	AND R1, R3
	
	CMP R2, 1
	JN bala_remove			; Verifica se a bala nesta interac��o ultrapassa o topo do PIXEL_SCREEN.
	
	CALL colisao			; Verifica se existe uma bomba na posi��o imediatamente acima da bala ou na mesma posi��o.
	BIT R3, 0			; Se a rotina colis�o devolver "R3" com o valor 1, significa que houve colis�o e foi removida a bomba.
	JNZ bala_remove
	
bala_sobe:				; Sobe a bala uma posi��o na vertical actualizando a tabela "tab_balas".
	
	MOV R3, 2d			; Coloca "R3" a 2 de forma a indicar a rotina "escreve_PS" dois pixeis,
	CALL escreve_PS			;um na coordenada do pixel actual para o desligar e outra na superior para criar a ilus�o da subida da bala.
	SUB R2, 1
	MOVB [R0], R2
	
	SUB R4, 1			; Marca a bala como tratada e verifica se era a �ltima da tabela "tab_balas".
	JZ bala_fim
	ADD R0, 2
	JMP bala_ciclo
	
bala_remove:				; Desliga o pixel correspondente � bala que atingiu a �ltima posi��o.
	CLR R3				; Coloca "R3" a zero de forma a indicar a rotina escreve_PS para desenhar no PIXEL_SCREEN
	CALL escreve_PS			;um pixel na coordenada dos parametros "R1"(horizontal) e "R2"(vertical".
	MOV R2, VAL_NULO		; Actualiza a tabela removendo a bala.
	MOV [R0], R2
	
	MOV R3, ref_balas		; Decrementa a "ref_balas" 1 de forma a descontar ao n�mero de balas em jogo a bala removida.
	MOV R2, [R3]
	SUB R2, 1
	MOV [R3], R2
	
	SUB R4, 1			; Marca a tecla como tratada.
	JZ bala_fim
	ADD R0, 2
	JMP bala_ciclo
	
bala_fim:				; Termina a rotina.
	POP R4
	POP R3
	POP R2
	POP R1
	POP R0
	RET

;* -- colisao ----------------------------------------------------------------
;* 
;* Descri��o: Verifica se existiu colis�o entre uma bala e alguma bomba.
;*	      Caso tenha havido, remove da tabela "tab_bombas" a entrada referente a bomba que colidiu,
;*	      decrementa 1 a "ref_bombas" de forma a actualizar o n�mero de balas em jogo e apaga
;*	      a bomba do PIXEL_SCREEN.
;*
;* Par�metros:R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: R3
;* Destr�i: --
;* Notas: (R3 retorna com o valor 0 caso n�o tenha existido colis�o e 1 caso tenha).
colisao:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R5
	
	SUB R2, 1			; Subtrai a "R2" e "R1" 1 obtendo assim a coordenada do primeiro pixel de uma possivel bomba
	SUB R1, 1			;imediatamente acima da bala.
	
	MOV R3, R1			; Verifica se a bala se encontra numa posi��o onde seja possivel existir uma bomba,
	MOV R5, 4			;as coordenadas onde nunca existem bombas s�o as todas as que t�m como coordenada horizontal um m�ltiplo de 4.
	MOD R3, R5
	JNZ colisao_fim	
	
	MOV R0, PIXEL_BASE	
	CALL calc_endereco
	CALL masc_bit
	
	MOVB R5, [R0]			; Verifica se existe uma bomba na posi��o acima da bala verificando se o primeiro bit da coluna,
	AND R5, R3			;que identifica na tabela "tab_bombas" as bombas, est� aceso.
	JZ colisao1
	
	MOV R5, R2			; Confirmado que existe uma bomba, coloca as coordenadas da bomba em "R5" e salta para "colisao_ciclo".
	SHL R5, 8
	ADD R5, R1
	MOV R0, tab_bombas
	JMP colisao_ciclo
	
colisao1:
	ADD R2, 1
	MOV R0, PIXEL_BASE		; Confirmado que n�o existe nenhuma bomba na posi��o imediatamente acima da bala,

	CALL calc_endereco		;verifica se existe uma bomba na mesma posi��o da bala, o que pode acontecer
	CALL masc_bit			;devido a alguma falha num dos clocks.
	
	MOVB R5, [R0]			; Verifica se existe bomba na posi��o da bala, verificando se o primeiro bit da coluna,
	AND R5, R3			;que identifica na tabela "tab_bombas" as bombas est� aceso.
	JZ colisao_fim
	
	MOV R5, R2			; Confirmado que existe uma bomba, coloca as coordenadas da bomba em "R5" e avan�a para "colisao_ciclo".
	SHL R5, 8
	ADD R5, R1
	MOV R0, tab_bombas
	
colisao_ciclo:				; Procura na tabela "tab_bombas" a bomba com as coordenadas iguais ao valor de "R5".
	MOV R3, [R0]
	CMP R3, R5
	JEQ colisao_rm_bomb
	
	ADD R0, 2
	JMP colisao_ciclo
	
colisao_rm_bomb:			; Remove da tabela "tab_bombas" a bomba encontrada, actualizando tamb�m "ref_bombas" com o
	MOV R3, 1			;n�mero de balas que se encontram agora em jogo.
	CALL escreve_PS

	MOV R3, VAL_NULO
	MOV [R0], R3
	
	MOV R5, ref_bombas
	MOV R3, [R5]
	SUB R3, 1
	MOV [R5], R3
	
	MOV R3, 1
	ADD R10, 1
	
	MOV R2, score			; Incrementa um a "score" actualizando assim o n�mero de balas destru�das pelo utilizador.
	MOV R1, [R2]			;(se o score atingir o valor FFFFH n�o incrementa).
	ADD R1, 1
	JV colisao_fim2
	
	MOV [R2], R1
	JMP colisao_fim2
	
colisao_fim:				; Caso n�o tenha sido removida uma bomba.
	CLR R3
colisao_fim2:				; Caso tenha sido removida uma bomba.
	POP R5
	POP R2
	POP R1
	POP R0
	RET
	
;* -- canhao_dir ----------------------------------------------------------------
;* 
;* Descri��o: Desloca o canh�o 2 pixeis para a direita no PIXEL_SCREEN actualizando
;*	      a sua posi��o na vari�vel "pos_canhao".
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: ( Se o canh�o estiver na posi��o 31 horizontal a rotina n�o faz nada.)
canhao_dir:			
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV R0, pos_canhao
	MOV R1, [R0]
	MOV R2, MAX_PS			; MAX_PS � o valor da �ltima posi��o horizontal � direita do PIXEL_SCREEN
	CMP R1, R2			;que coincide com a �ltima posi��o � direita que o canh�o pode ocupar.
	JEQ canhao_dir_fim
	
	CALL desenha_canhao		; Apaga o canh�o do PIXEL_SCREEN.
	ADD R1, 2
	CALL desenha_canhao		; Desenha o canh�o no PIXEL_SCREEN na nova posi��o.
	MOV [R0], R1
canhao_dir_fim:
	POP R2
	POP R1
	POP R0
	RETF
	
	
;* -- canhao_esq ----------------------------------------------------------------
;* 
;* Descri��o: Desloca o canh�o 2 pixeis para a esquerda no PIXEL SCREEN, actualizando
;*	      a sua posi��o na vari�vel "pos_canhao".
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
canhao_esq:			
	PUSH R0
	PUSH R1
	PUSH R2

	MOV R0, pos_canhao
	MOV R1, [R0]
	CMP R1, 1			; 1 � o valor da �ltima posi��o horizontal � esquerda que o canh�o pode ocupar.
	JEQ canhao_esq_fim
	
	CALL desenha_canhao		; Apaga o canh�o do PIXEL SCREEN.
	SUB R1, 2
	CALL desenha_canhao		; Desenha o canh�o no PIXEL SCREEN na nova posi��o.
	MOV [R0], R1
canhao_esq_fim:
	POP R2
	POP R1
	POP R0
	RETF

;* -- escreve_PS ----------------------------------------------------------------
;* 
;* Descri��o: Acende ou apaga pixeis no PIXEL SCREEN conforme o estado actual do pixeis em quest�o.
;*	      Esta rotina possui 3 modos de funcionamento:
;*	R3=0 : Liga ou desliga o pixel cujas coordenadas sejam R1(horizontal) e R2(vertical).(modo pixel)
;*	R3=1 : Liga ou desliga 3 pixeis sequenciais horizontalmente
;*	      cuja coordenada do primeiro � esquerda seja R1(horizontal) e R2(vertical).(modo bomba)
;*	R3=2 : Liga ou desliga 2 pixeis sequenciais verticalmente, 
;*	      cuja coordenada do inferior seja R1(horizontal) e R2(vertical).(modo bala)
;*
;* Par�metros: R1(Coordenada horizontal), R2(Coordenada vertical), R3
;* Retorna: --
;* Destr�i: --
;* Notas: (O modo bomba s� funciona se "R1" for igual a um seguintes valores:
;*	0, 4, 8, 12, 16, 20, 24, 28).
escreve_PS:
	PUSH R0
	PUSH R1
	PUSH R3
	PUSH R7
	MOV R0, PIXEL_BASE
	
	BIT R3, 0			; Verifica se deve executar o modo bomba.
	JNZ escreve_PS_bomb
	
	BIT R3, 1			; Verifica se deve executar o modo bala.
	JNZ escreve_PS_bala
					; Executa o modo pixel.
	CALL	calc_endereco		; Calcula o endere�o do byte do PIXEL_SCREEN onde se encontra o pixel em quest�o.
	CALL	masc_bit		; Cria uma m�scara com 1 no bit que representa o pixel em quest�o no byte endere�ado.
	JMP escreve_PS_imprime_sai
	
escreve_PS_bomb:			; Executa o modo bomba desenhando no PIXEL_SCREEN 3 pixeis em apenas uma opera��o de escrita.
	CALL	calc_endereco		; Calcula o endere�o do byte do PIXEL_SCREEN onde se encontra o pixel em quest�o.
	MOV	R3, 8d
	MOV	R7, R1			; Usa a f�rmula ("R1" mod 8) para verificar se as coordenadas dizem respeito ao primeiro ou
	MOD	R7, R3			;segundo nibble do byte para o qual "calc_endere�o" calculou o endere�o do PIXEl_SCREEN.
	MOV	R3, 0E0H
	CMP	R7, 4
	JLT	escreve_PS_imprime_sai
	SHR	R3, 4
	JMP	escreve_PS_imprime_sai
	
escreve_PS_bala:			; Executa o modo bala desenhando primeiro um pixel nas coordenadas "R1" e "R2" e desenhando
					;em "escreve_PS_imprime_sai" outro pixel imediatamente acima.
	CALL	calc_endereco		; Calcula o endere�o do byte do PIXEL_SCREEN onde se encontra o pixel em quest�o.
	CALL	masc_bit		; Cria uma m�scara com 1 no bit que representa o pixel em quest�o no byte endere�ado.
	
	MOVB R7, [R0]			; Liga ou desliga o pixel em quest�o no PIXEL_SCREEN.
	XOR R7, R3
	MOVB [R0], R7
	SUB R0, 4			; Subtraindo 4 ao endere�o do pixel, dado que o PIXEl SCREEN possui 4 byte em cada linha,
	JMP	escreve_PS_imprime_sai	;altera o endere�o para o pixel imediatamente acima do anterior.

escreve_PS_imprime_sai:
	MOVB R7, [R0]			; Liga ou desliga o pixel em quest�o no PIXEL_SCREEN.
	XOR R7, R3
	MOVB [R0], R7
	
	POP R7
	POP R3
	POP R1
	POP R0
	RET

;* -- calc_endereco ----------------------------------------------------------------
;* 
;* Descri��o: Actualiza o valor de R0 com o endere�o do byte do PIXEL-SCREEN pertencente,
;*	      ao bit de coordenadas "R1"(horizontal) e "R2"(vertical).
;*
;* Par�metros: 	R0(PIXEL_BASE), R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: R0 
;* Destr�i: --
;* Notas: --
calc_endereco:
	PUSH R1
	PUSH R3
	
	MOV R3, 4			; Efectua a seguinte f�rmula para calcular o endere�o do byte,
	MUL R3, R2			;que "R1" e "R2" identificam:
	ADD R0, R3			;("R0" + 4*"R2" + "R1"/8)
	
	MOV R3, 8
	DIV R1, R3
	ADD R0, R1
	
	POP R3
	POP R1
	RET
	
	
;* -- masc_bit ----------------------------------------------------------------
;* 
;* Descri��o: Cria uma m�scara, colocando o bit do byte que "R1" define a 1.
;*	      
;*
;* Par�metros: 	R1(Ordem do bit a colocar a 1)
;* Retorna: R3
;* Destr�i: --
;* Notas: --
masc_bit:
	PUSH R1
	MOV R3, 8
	MOD R1, R3			; Efectua a seguinte f�rmula para obter em "R1" a ordem do bit
	MOV R3, 100H			;a colocar a 1.
	ADD R1, 1
masc_bit_1:
	SHR R3, 1			; Efectua tantos "SHR" a "R3"=100H quanta a ordem do bit em quest�o
	SUB R1, 1			;de forma a colocar 1 no bit em quest�o.(Foi considerado o bit de menor peso como o 1� bit)
	JNZ masc_bit_1
	
	POP R1
	RET

;* -- LE_tec ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina l� da "PUSH-MATRIX" o valor da tecla pressionada e coloca o seu valor
;*	      na vari�vel "tecla". 
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: (Caso nenhuma tecla esteja pressionada coloca em "tecla" o VAL_NULO)
LE_tec:
	PUSH R0
	PUSH R4
	PUSH R3
	PUSH R1
	MOV R0, POUT_2
	MOV R4, PIN
	
	CALL testa_tec		; Verifica se alguma tecla est� pressionada, e obt�m o valor
	AND R3, R3		;da linha e da coluna do teclado correspondentes � tecla.
	JZ LE_tec_null		; Caso nenhuma tecla esteja pressionada.
	
	CALL conv_tec		; Converte o n�mero da linha e da coluna da tecla pressionada para o seu valor.
	MOV R0, tecla		; Coloca o valor da tecla pressionada em "tecla".
	MOV [R0], R3
	
	JMP LE_tec_fim
LE_tec_null:
	MOV R0, tecla		; Coloca em "tecla" o "VAL_NULO" significando que nenhuma tecla foi pressionada.
	MOV R1, VAL_NULO
	MOV [R0], R1
LE_tec_fim:
	POP R1
	POP R3
	POP R4
	POP R0
	RET
	
;* -- testa_tec ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina testa o teclado por uma tecla pressionada,
;*	     coloca o valor da linha correspondente a tecla no teclado em "R3",
;*	      e o valor da coluna em "R1".
;*
;* Par�metros: 	R0(POUT_2), R4(PIN)
;* Retorna: R1, R3 
;* Destr�i: --

;* Notas: (R3) e (R2) ter�o o valor 0 se nenhuma tecla for pressionada.
testa_tec:
	PUSH R2
	MOV R2, 000FH			
	MOV R3, 08H	
testa_tec_1:
	MOVB [R0], R3		; Activa uma determinada coluna verificando se nesta existe com o valor 1. 
	MOVB R1, [R4]		;Caso isto aconte�a, significa que foi pressionada uma tecla que � definida por essa linha e coluna.
	
	AND R1, R2		; Isola o primeiro nibble de menor peso que corresponde � informa��o 
	JNZ	volta_tec	;recebida pela "PUSH MATRIX" (o 4� bit corresponde ao valor do clock1).
	SHR R3, 1		; Executa um "SHR" a "R3" de forma a testar a linha seguinte.
	JZ	volta_tec
	JMP testa_tec_1
volta_tec:
	POP R2
	RET

;* -- conv_tec ----------------------------------------------------------------
;* 
;* Descri��o: Esta rotina converte o valor da coluna e da linha da tecla
;*	      pressionada pela "PUSH MATRIX"( R1 e R3 respectivamente),
;*	      no valor da mesma, colocando o seu valor em "R3".
;*	      
;*
;* Par�metros: 	R1(Coluna da tecla), R3(Linha da tecla)
;* Retorna: R3 
;* Destr�i: --
;* Notas: --
conv_tec:	
	PUSH R4
	PUSH R5
	
	MOV R4, R1
	CLR R5
conv_tec_COL:			; A cada itera��o incrementa a "R5" 1 e executa a "R4" um "SHR" at� que este seja igual a zero,
	ADD R5, 1		;contando assim a quantidade de zeros � direita de "R4" e obtendo o valor da ordem do �nico bit a 1 de "R1".
	SHR R4, 1
	JNZ conv_tec_COL
	MOV R1, R5
	
	MOV R4, R3
	CLR R5
conv_tec_LIN:			; A cada itera��o incrementa a "R5" 1 e executa a "R4" um "SHR" at� que este seja igual a zero,
	ADD R5, 1		;contando assim a quantidade de zeros a direita de "R4" e obtendo o valor da ordem do �nico bit a 1 de "R3".
	SHR R4, 1		
	JNZ conv_tec_LIN
	MOV R3, R5
	
	SUB R1, 1
	SUB R3, 1
	MOV R5, 4		; Aplica a seguinte f�rmula para calcular o valor da tecla pressionada na "PUSH MATRIX",
	MUL R3, R5		;algo que apenas � poss�vel atrav�s de uma f�rmula devido ao facto das teclas terem valores sequenciais.
	ADD R3, R1		; ("R1" - 1 + ("R3" - 1) * 4)
			
	POP R5
	POP R4
	RET
	
;* -- desenha_canhao ----------------------------------------------------------------
;* 
;* Descri��o: Desenha no PIXEL-SCREEN um canh�o, composto por dois pixeis, um na �ltima posi��o vertical
;*	      e outro imediatamente acima, os dois na posi��o horizontal do valor do registo "R1".
;*	      
;*
;* Par�metros: 	R1(Valor horizontal do canh�o.)
;* Retorna: --
;* Destr�i: --
;* Notas: --
desenha_canhao:
	PUSH R2
	PUSH R3

	MOV R3, 2d		; "R3"=2d indica � rotina "escreve_PS" para executar o "modo bala", que desenha dois pixeis verticais,	
				;como � pretendido.
	MOV R2, MAX_PS		; MAX_PS corresponde a �ltima posi��o do PIXEL-SCREEN, neste contexto �ltima posi��o vertical.
	CALL escreve_PS		; Desenha o canh�o.
	
	POP R3
	POP R2
	RET
	
;* -- preenche_tab_tec ----------------------------------------------------------------
;* 
;* Descri��o: Preenche a tabela "tab_teclas" com as rotinas a executar para cada umas das teclas
;*	      da "PUSH MATRIX" e coloca a rotina associada a cada tecla na posi��o da tabela correspondente.
;*	      
;*
;* Par�metros: --
;* Retorna: --
;* Destr�i: --
;* Notas: --
preenche_tab_tec:
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV R0, tab_teclas
	MOV R1, 16d		; 16 � o n�mero de teclas existente no "PUSH MATRIX".
	MOV R2, no_tec		; Rotina a colocar em teclas n�o associadas a nenhuma ac��o.
	
preeche_tab_tec1:		; Coloca em todas as posi��es da tabela "tab_teclas" a rotina "no_tec".
	MOV [R0], R2
	ADD R0, 2
	SUB R1, 1
	JNZ preeche_tab_tec1
	
	MOV R0, tab_teclas	
	
	MOV R2, TEC_START	; Coloca a rotina associada ao reiniciar do jogo na posi��o associada � tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, reboot
	MOV [R2], R1
	
	MOV R2, TEC_PAUSE	; Coloca a rotina associada a colocar o jogo em pausa na posi��o associada � tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, pause
	MOV [R2], R1
	
	MOV R2, TEC_END		; Coloca a rotina associada a terminar o jogo na posi��o associada � tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, termina
	MOV [R2], R1
	
	MOV R2, TEC_CANH_E	; Coloca a rotina associada a deslocar o canh�o para a esquerda na posi��o associada � tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, tec_canhao_esq	
	MOV [R2], R1
	
	MOV R2, TEC_CANH_D	; Coloca a rotina associada a deslocar o canh�o para a direita na posi��o associada � tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, tec_canhao_dir
	MOV [R2], R1
	
	MOV R2, TEC_FIRE	; Coloca a rotina associada a disparar uma bala no jogo na posi��o associada � tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, fire_bala
	MOV [R2], R1
	
	POP R0
	POP R1
	POP R2
	RET
