; *********************************************************************************
; *
; * IST-UTL
; *
; *********************************************************************************
; *********************************************************************************
; *
; * Modulo: 	Proj.asm
; * Descrição : Este programa consiste num jogo de defesa antiaérea. Recorrendo a dois teclados, 
; *		um físico e um virtual, podemos controlar um canhão que dispara balas contra bombas que estão a cair. 
; * 		Cada bomba que chegar ao chão remove uma vida de um total de 6 vidas. O score máximo de bombas
; *		que podemos destruir é 999. O canhão é composto por dois pixeis acesos, um em cima do outro na parte inferior do PIXEL_SCREEN
; *		(ecrã onde o jogo é apresentado). As bombas são compostas por 3 pixeis acesos na horizontal 
; *		que vao descendendo pelo PIXEL_SCREEN até serem destruídas pelas balas que ascendem do canhão, ou quando chegam ao chão. 
; *		Quando chegam ao chão desaparecem com uma explosão. 
; *		Isto foi um projecto de Arquitectura de computadores do IST realizado no segundo semestre de 2012.
; *		
; *
; *
; *		
; *
; *
; *
; *
; * Nota : R8 irá possuir, durante a execução do código, o valor da última tecla pressionada pelo teclado virtual.
; * 	   R9 irá possuir, durante a execução do código, os valores de variáveis de memória das seguintes rotinas:
; *		* canhao
; *		* bala
; *		* bomba
; *	   R10 irá funcionar, durante a execução do código, como um contador a ser usado para a criação de valores aleatórios.
; *
; *	Feito por:
; *	Pedro Gameiro N 72617
; *	Nuno Oliveira N 73915
; *	José Martins  N 66378
; *
; *********************************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************

M1_RCU		EQU	6000H		; Registo controlo da MUART-1
M1_REP		EQU	6002H		; Registo estado da MUART-1
M1_RD1		EQU	6004H		; Registo dados do canal 1 da MUART-1 (porto de Rx)
M1_RD2		EQU	6006H		; Registo dados da canal 2 da MUART-1 (porto de Tx)
PIXEL_BASE	EQU	4000H		; Endereço da primeira posição do PIXEL SCREEN.
PIXEL_FIM	EQU	407FH		; Endereço da ultima posição do PIXEL SCREEN.
POUT_1		EQU	7000H		; Endereço do display.
POUT_2		EQU	9000H		; Endereço do teclado para acessos de escrita.
PIN		EQU	0A000H		; Endereço do teclado para acessos de leitura e do relógio 1.

TEC_MU_CANH_E	EQU	61H		; 61H corresponde ao valor "a" em ASCII.
TEC_MU_CANH_D	EQU	64H		; 64H corresponde ao valor "d" em ASCII.
TEC_MU_FIRE	EQU	20H		; 20H corresponde ao valor de "SPACE" em ASCII.
TEC_MU_PAUSE	EQU	70H		; 70H corresponde ao valor de "p" em ASCII.
TEC_MU_END	EQU	1BH		; 1BH corresponde ao valor de "ESQ" em ASCII.
TEC_MU_START	EQU	0AH		; 0AH corresponde ao valor de "ENTER" em ASCII.

TEC_END		EQU	3H		; Tecla associada à operação de terminar o jogo.
TEC_PAUSE	EQU	1H		; Tecla associada à operação de colocar em pausa o jogo.
TEC_START	EQU	0H		; Tecla associada à operação de iniciar e reiniciar o jogo.
TEC_FIRE	EQU	0EH		; Tecla associada à operação de disparar no jogo.
TEC_CANH_E	EQU	0CH		; Tecla associada à operação de deslocar o canhão para a esquerda no jogo.
TEC_CANH_D	EQU	0DH		; Tecla associada à operação de deslocar o canhão para a direita no jogo.

VAL_NULO	EQU	0FFFFH		; Constante usada para indentificar valores neutros.
RITM_BOMBAS	EQU	5d		; Constante que controla o ritmo do aparecimentos de bombas(quanto maior a constante menor o ritmo).
NUM_VIDAS	EQU	6d		; Número de vidas inicias do jogo.

MAX_PS		EQU	31d		; Posição máxima decimal do PIXEL SCREEN.
MIN_PS		EQU	0d		; Posição mínima decimal do PIXEL SCREEN.

; *********************************************************************************
; * DADOS
; *********************************************************************************

PLACE	1000H
TABLE	100H		
stackpointer:				; Tabela reservada para uso da pilha.

bte_tab:	WORD	int0		; Endereços das rotinas de interrupção.
		WORD	int1
		WORD	int2
		WORD	int3

ref_balas:	WORD	0H		; Valor correspondente ao número actual de balas em jogo(número máximo 8).
tab_balas:	TABLE	8d		; Tabela com a localização vertical e horizontal das balas em jogo(número máximo 8).	

			
ref_bombas:	WORD	0H		; Valor correspondente ao número actual de bombas em jogo(número máximo 8).
tab_bombas:	TABLE	8d		; Tabela com a localização vertical e horizontal das bombas em jogo(número máximo 8).

tab_teclas:	TABLE	16d		; Tabela destinada a conter os endereços das rotinas associadas às teclas recebidas pela "PUSH MATRIX".
		
tab_tec_muart:	WORD	canhao_esq	; Tabela com os endereços das rotinas associadas às teclas recebidas pelo "MUART".
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
string_score:	STRING	0AH,09H,"++++ Conseguiu destruir XXX bombas! ++++",0	;O ultimo "X" está a ocupar o 28º byte da string.
string7:	STRING	0AH,09H,"++++   Nao destruiu nenhuma bomba!   ++++",0
		
pos_canhao:	WORD	13d		; Valor correspondente à localização actual do canhão na horizontal.
tecla: 		WORD	VAL_NULO	; Valor em memória da última tecla pressionada.
tec_muart:	WORD	VAL_NULO

vidas:		WORD	0		; Valor correspondente ao número de vidas restantes durante o jogo, que será representada no display
					; ao longo do jogo.
score:		WORD	0		; Valor correspondente ao número de bombas destruídas ao longo do jogo.

					
int3_var:	WORD	0H		; Variável usada pela rotina "int3", para a escrita de strings no terminal ligado a "MUART".

; *********************************************************************************
; * Código
; *********************************************************************************
Place	0

	MOV SP, stackpointer		; Inicializações necessárias.
	MOV BTE, bte_tab
	EI				; Activa as interrupções relacionadas com a MUART.
	EI2
	EI3
	
	CALL preenche_tab_tec
	CALL inicializa_tabs		; Coloca os valores iniciais nas tabelas referentes às bombas e às balas.
	CALL limpa_PS			; Desliga todos os pixeis do PIXEl-SCREEN.
	CALL ini_MUART			; Inicializa a MUART.
	MOV R2, string5
	CALL muart_out			; Imprime a string5 no terminal.
	
	CALL start			; Espera que o utilizador pressione a tecla para iniciar o jogo.
	MOV R2, string0			
	CALL muart_out			; Imprime a string0 no terminal.
	
inicio:					
	MOV R1, 13d
	CALL desenha_canhao		; Desenha o canhão na posição 13 horizontal e 0 vertical.
	MOV R1, NUM_VIDAS	
	CALL display			; Inicia as vidas, tanto em memória como no display.
	EI0				; Activa as interrupções ligadas aos clocks 1 e 2.
	EI1
	
corpo:					; Corpo principal do código.
	BIT R9, 0			; Verifica, usando o bit 0 de "R9" como variável de estado, se ocorreu um flanco ascendente 
	JNZ corpo_bala			; no relógio 1, desde a última iteracção. Caso tenha, corre a iteração responsável pelas balas.
corpo1:
	BIT R9, 3			; Verifica, usando o bit 3 de "R9" como memória de estado, se ocorreu um flanco ascendente 
	JNZ corpo_bomba			; no relógio 2, desde a última iteração. Caso tenha, corre a iteração responsável pelas bombas.	
	JMP corpo_tec

corpo_bala:				; Chama a rotina bala e coloca o bit 0 de "R9" a 0.
	CALL bala
	CLR R9, 0
	JMP corpo1

corpo_bomba:				; Chama a rotina bomba e coloca o bit 3 de "R9" a 0.
	CALL bomba


	
	MOV R0, R10			; Verifica se o contador "R10" possui um valor múltiplo da variável "RITM_BOMBAS".
	MOV R2, RITM_BOMBAS		; Caso se verifique, executa a rotina "bomba_nova"(Tem como objectivo coordenar 
	MOD R0, R2			;o ritmo de aparecimento de bombas).
	JNZ corpo_bomba_fim
	
	CALL bomba_nova
corpo_bomba_fim:			
	CLR R9, 3
	JMP corpo_tec

corpo_tec:
	CALL LE_tec			; Determina se alguma tecla foi pressionada pelo teclado virtual.
					; caso se verifique, coloca o respectivo valor na variável "tecla".
								
	MOV R0, tecla			; Coloca o valor da tecla pressionada em "R3".
	MOV R3, [R0]
	
	CMP R3, R8			; Verifica se a tecla pressionada continua pressionada.
	JEQ corpo_tec2			; Se não continuar pressionada actualiza "R8" com o valor da nova tecla, caso esteja não verifica se a tecla
	MOV R8, R3			; corresponde a alguma operação.
	
	CLR R9, 1			; Caso a tecla não continue pressionada, coloca as variáveis de estado das rotinas "canhao_esq"
	CLR R9, 2			; e "canhao_dir" a 0, de forma a parar o movimento do canhão caso este se estivesse a mover.
	
	CMP R3, -1			; Verifica se "R3" possui o "VAL_NULO", ou seja, se foi pressionada uma tecla
	JZ corpo_tec2			; ou se apenas foi detectada pela rotina "LE_tec" a sua inexistência.
	
	MOV R0, tab_teclas		; Executa, usando a "tab_teclas" como uma tabela de rotinas, a rotina correspondente à tecla pressionada.
	SHL R3, 1			; Multiplica "R3" por 2.
	ADD R0, R3
	MOV R3, [R0]
	CALLF R3			; Faz a chamada à rotina correspondente à tecla pressionada no teclado virtual usando "CALLF"
					; de forma a ser fácil às rotinas, ao qual não seja necessário retornar, apagar o valor de "RL".
corpo_tec2:				
	MOV R2, tec_muart		; Executa as rotinas correspondentes ao input do teclado físico pelo MUART,
	MOV R3, [R2]			; colocando "VAL_NULO" na variável "tec_muart" para marcar como tratada a tecla.
	
	CMP R3, -1			; Verifica se o valor da tecla obtido corresponde ao "VAL_NULO", ou, se existe alguma tecla
	JZ corpo			; ainda não processada.
	MOV R0, tab_tec_muart
	ADD R0, R3
	MOV R3, [R0]
	CALLF R3			; Faz a chamada à rotina correspondente à tecla pressionada no teclado físico usando "CALLF"
                                        ; de forma a ser fácil às rotinas, ao qual não seja necessário retornar, apagar o valor de "RL".
					
	MOV R3, VAL_NULO
	MOV [R2], R3	 

	JMP corpo

tec_canhao_esq:
	SET R9, 1			; Coloca o bit 2 de "R9" a 1 para permitir a execução da rotina "canhao_esq" pela int0.
	RETF
	
tec_canhao_dir:
	SET R9, 2			; Coloca o bit 2 de "R9" a 1 para permitir a execução da rotina "canhao_dir" pela int0.
	RETF
no_tec:					; Apenas retorna para o valor do "RL" usado para teclas não associadas a nenhuma operação.
	RETF
	
; *********************************************************************************
;* INTERRUPÇÕES
; *********************************************************************************
	
;* -- int0 ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina é executada pela interrupção "EI0".
;*	      É activada pelo relógio-1 no flanco ascendente.
;* 	      Incrementa o registo "R10" para futura utilização pela rotina "bomba".
;*	      Executa, se uma das teclas correspondentes ao deslocamento do canhão tiver sido pressionada,
;*	      A rotina correspondente.
;*
;* Parâmetros: R9(Variaveis de estado), R10(Contador)
;* Retorna: --
;* Destrói: --
;* Notas: --
int0:
	BIT R9, 2			; Se o 2º bit de "R9" estiver a 1, significa que a tecla correspondente ao
	JNZ int0_canhao_D		; deslocamento do canhão para a direita.
	
	BIT R9, 1
	JNZ int0_canhao_E		; Se o 1º bit de "R9" estiver a 1, significa que a tecla correspondente ao
	JMP int0_fim			; deslocamento do canhão para a esquerda.
	
int0_canhao_D:
	CALLF canhao_dir		; Chama a rotina responsável pelo deslocamento do canhão para a direita.
	JMP int0_fim
	
int0_canhao_E:
	CALLF canhao_esq		; Chama a rotina responsável pelo deslocamento do canhão para a esquerda.
	JMP int0_fim
int0_fim:
	ADD R10, 1			; Adiciona 1 ao contador "R10".
	SET R9, 0			; Activa a variável de estado usada para a execução da rotina bala.

	RFE

;* -- int1 ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina é executada pela interrupção "EI1".
;*            É activada pelo relógio-2 no flanco ascendente.
;*	      Coloca o bit 3 de "R9" a 1 para futura utilização pela rotina "bomba" e incrementa o contador "R10".
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
int1:
	ADD R10, 2			; Adiciona 2 ao contador "R10".
	SET R9, 3			; Activa a variável de estado usada para a execução da rotina bomba.
	RFE
	
;* -- int2 ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina é activada pela interrupção "EI2" que, por sua vez,
;*            é activada pelo sinal da MUART que indica a existência de um byte ainda não lido.
;*	      Coloca na variável "tec_muart" o índice da tabela "tab_tec_muart" correspondente à rotina
;*	      a ser executada pela tecla pressionada no teclado fisico.
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --	
int2:
	PUSH	R0
	PUSH	R1
	PUSH	R3

	MOV	R0, M1_RD1	; Registo de dados (canal 1)
	MOVB	R3, [R0]	; Caracter que chegou
	MOV 	R0, tec_muart
	
	MOV	R1, TEC_MU_CANH_E ; Verifica se o valor recebido corresponde à tecla associada à deslocação do canhão para a esquerda.
	CMP	R3, R1
	JEQ	int2_esq
	
	MOV	R1, TEC_MU_CANH_D ; Verifica se o valor recebido corresponde à tecla associada à deslocação do canhão para a direita.
	CMP	R3, R1
	JEQ	int2_dir
	
	MOV	R1, TEC_MU_FIRE   ; Verifica se o valor recebido corresponde à tecla associada ao disparo de uma bala.
	CMP	R3, R1
	JEQ	int2_fire
	
	MOV	R1, TEC_MU_PAUSE ; Verifica se o valor recebido corresponde à tecla associada a colocar o jogo em pausa.
	CMP	R3, R1
	JEQ	int2_pause
	
	MOV	R1, TEC_MU_END  ; Verifica se o valor recebido corresponde à tecla associada a terminar o jogo.
	CMP	R3, R1
	JEQ	int2_end
	
	MOV	R1, TEC_MU_START ; Verifica se o valor recebido corresponde à tecla associada a iniciar e reiniciar o jogo.
	CMP	R3, R1
	JEQ	int2_start
	JMP int2_fim
int2_esq:			; Coloca em "tec_muart" o valor do índice da tabela "tab_tec_muart" correspondente à tecla.
	MOV R3, 0d
	MOV [R0], R3
	JMP int2_fim	
int2_dir:			; Coloca em "tec_muart" o valor do índice da tabela "tab_tec_muart" correspondente à tecla.
	MOV R3, 2d
	MOV [R0], R3
	JMP int2_fim
int2_fire:			; Coloca em "tec_muart" o valor do índice da tabela "tab_tec_muart" correspondente à tecla.
	MOV R3, 4d
	MOV [R0], R3
	JMP int2_fim
int2_pause:			; Coloca em "tec_muart" o valor do índice da tabela "tab_tec_muart" correspondente à tecla.
	MOV R3, 6d
	MOV [R0], R3
	JMP int2_fim
int2_end:			; Coloca em "tec_muart" o valor do índice da tabela "tab_tec_muart" correspondente à tecla.
	MOV R3, 8d
	MOV [R0], R3
	JMP int2_fim
int2_start:			; Coloca em "tec_muart" o valor do índice da tabela "tab_tec_muart" correspondente à tecla.
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
;* Descrição: Esta rotina é activada pela interrupção "EI3", que por sua vez
;*            é activada pelo sinal da MUART quando esta está pronta a receber um byte.
;*	      Imprime em cada interação um caracter da string cujo o endereço esteja em "int3_var".
;*	      
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
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
	
	CMP R1, 0		; Verifica se a string já terminou.
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
;* Descrição: Esta rotina fica em espera activa enquanto não for pressionada a tecla associada ao início do jogo.
;*	      Tem como propósito dar ao utilizador a possiblidade de iniciar o jogo.
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
start:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R2, tec_muart
start1:				; Fica em espera activa até que o utilizador pressione, ou pelo teclado virtual, ou pelo fisico
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
	
start_fim:			; Coloca o valor nulo na variável "tec_muart", de forma a marcar a tecla pressionada como usada.
	MOV R1, VAL_NULO
	MOV [R2], R1

	MOV R1, 1000d		; Chama a rotina "espera" de forma a dar tempo ao utilizador para começar a jogar.
	CALL espera
	POP R2
	POP R1
	POP R0
	RET

;* -- termina ----------------------------------------------------------------
;* 
;* Descrição: Termina o jogo limpando o PIXEl-SCREEN e colocando o Dysplay a 0.
;*	      Para sair da rotina é necessário pressionar a tecla associada ao iniciar do jogo.
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: De forma a ser uma rotina que pode ser executada com a instrução "CALLF"
;*	  esta coloca o registo "RL" a zero antes de executar JMP para o "inicio".

termina:				
	DI0
	DI1				; Desactiva as interrupções.

	MOV R2, string6			; Imprime no terminal a string6.
	CALL muart_out
	MOV R1, 1000d
	CALL espera			; Coloca o código brevemente em pausa de forma a dar tempo à string6 de ser impressa no terminal.
	
	CALL imprime_score
	CALL limpa_PS
	CLR R1
	CALL display			; Coloca as vidas e o display a zero.
	CALL start
	CLR RL				; Coloca o registo "RL" pois a rotina não efectua nenhum "RETF" e por isso não o vai usar o seu valor.
	CALLF reboot			; Efectua um salto para "reboot", cuja rotina não efectua um "RETF".
	
;* -- reboot ----------------------------------------------------------------
;* 
;* Descrição: Reinicia o jogo limpando todas as variáveis e registos necessários,
;*	      executa a função "espera" de forma a dar ao jogador tempo para se preparar.
;*	      Regressa para o "inicio".
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: De forma a ser uma rotina que pode ser executada com a instrução "CALLF"
;*	  ela coloca o registo "RL" a zero antes de executar JMP para o "inicio".

reboot:				
	DI0			; Desactiva as interrupções relacionadas com os clocks.
	DI1
	MOV R2, string1		; Imprime no terminal a string1.
	CALL muart_out
	CALL limpa_var		; Limpa as variáveis necessárias.
	MOV R1, 2000d		
	CALL espera
	MOV R2, tec_muart	; Coloca o valor nulo na variável tec_muart, de forma a marcar a tecla pressionada como usada.
	MOV R1, VAL_NULO
	MOV [R2], R1
	CLR RL			; Coloca o registo "RL" pois a rotina não efectua nenhum "RETF" e por isso não vai usar o seu valor.
	JMP inicio

	
;* -- pause ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina fica em espera activa enquanto não for pressionada a tecla associada à pausa.
;*	      Tem como propósito colocar o jogo em pausa .
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
pause:
	DI0			; Desactiva as interrupções associadas aos clocks.
	DI1
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV R2, string3		; Imprime no terminal a string3.
	CALL muart_out
	MOV R0, tecla
	MOV R2, tec_muart
	MOV R1, VAL_NULO	; Coloca VAL_NULO em "tec_muart" marcando a última tecla pressionada como usada.
	MOV [R2], R1
	
pause1:				; Espera que a tecla associada à pausa pare de ser pressionada se esta estiver.
	CALL LE_tec
	MOV R1, [R0]
	CMP R1, TEC_PAUSE
	JEQ pause1
	
	MOV R1, 1500d		
	CALL espera
pause2:				; Fica em espera activa enquanto não for pressionada a tecla associada à pausa.
	CALL LE_tec
	MOV R1, [R0]
	CMP R1, TEC_PAUSE
	JEQ pause_fim
	
	MOV R1, [R2]		
	CMP R1, 6d		; Verifica se a tecla associada à pausa foi pressionada via MUART.
	JEQ pause_fim
	
	JMP pause2
	
pause_fim:
	MOV R2, string4		; Imprime no terminal a string4.
	CALL muart_out
	POP R2	
	POP R1
	POP R0
	EI0			; Activa as interrupções associadas aos clocks.
	EI1
	RETF
	
;* -- limpa_PS ----------------------------------------------------------------
;* 
;* Descrição: Desliga todos os pixeis do PIXEL-SCREEN.
;*	      
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
limpa_PS:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R2, PIXEL_FIM	; PIXEL_FIM corrresponde ao endereço do byte de pixeis do PIXE-SCREEN.
	MOV R0, PIXEL_BASE	; Coloca o endereço inicial do PIXEL-SCREEN em "R0".
	CLR R1

limpa_PS_1:			; Desliga, a cada iteração, um byte de pixeis do PIXEL-SCREEN, até chegar ao último.
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
;* Descrição: Esta rotina coloca valores neutros em todas as entradas das tabelas tab_balas e tab_bombas.
;*	      
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: R0, R1, R2
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
;* Descrição: Esta rotina coloca o programa em espera, é tanto maior o tempo de espera quanto o valor de R1.
;*	      
;*	      
;*
;* Parâmetros: R1 ( Quantidade de iterações a executar)
;* Retorna: --
;* Destrói: R1
;* Notas: --
espera:
	NOP
	SUB R1, 1		; A cada iteração decrementa o valor de "R1", quando este for igual a zero retorna.
	JNZ espera
	RET

;* -- display ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina actualiza o display com o valor de R1 e actualiza o valor da variável "vidas" com esse valor.
;*	      
;*	      
;* 
;* Parâmetros: R1( Valor a actualizar)
;* Retorna: --
;* Destrói: --
;* Notas: --
display:
	PUSH R0
	PUSH R1
	MOV R0, POUT_1		; Endereço correspondente ao dysplay hexadecimal.
	MOVB [R0], R1
	MOV R0, vidas
	MOV [R0], R1
	POP R1
	POP R0
	RET
	
;* -- limpa_var ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina coloca os valores originais em "ref_balas", "ref_bombas", "pos_canhao", "score",
;*	     nas tabelas "tab_balas" e "tab_bombas" e limpa o PIXEL-SCREEN.
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói:  R1, R9, R10.
;* Notas: Os registos R9 e R10 retornam com o valor 0000H.
limpa_var:
	MOV R0, ref_balas		; Coloca a zero a variável com o valor da quantidade de balas em jogo.
	MOV R1, 0H
	MOV [R0], R1
	MOV R0, ref_bombas		; Coloca a zero a variável com o valor da quantidade de bombas em jogo.
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
;* Descrição: Inicializa a MUART-1 permitindo o acesso à mesma.
;*	      
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói:  --
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
;* Descrição: Imprime no terminal, ligado a MUART, o primeiro byte para o qual "R2" endereça.
;*	      Quando este terminar de ser impresso, a rotina de interrupção "int3" encarregar-se-á de imprimir
;*	     os seguintes.
;*
;* Parâmetros: R2 (Endereço da string)
;* Retorna: --
;* Destrói:  --
;* Notas: --
muart_out:	PUSH	R0
		PUSH	R1
		
		MOV R0, int3_var	; Coloca em "int3_var" o valor do endereço do proximo byte para uso pela rotina "int3".
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
;* Descrição: Imprime no terminal a string "string_score", trocando nesta, "XXX"
;*	     pelo valor de "score".
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói:  --
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
	MOV R2, 28d			; O ultimo "X" da string encontra-se no 28º byte desta
	ADD R0, R2			; Somando 28d ao endereço inicial da string, é obtido o endereço do último dos "X"s.
	
	CMP R1, 0			; Verifica se o score foi igual a 0.
	JEQ imprime_score_zero
	
	MOV R2, 999d			; Verifica se o score ultrapassou ou atingiu o seu limite de 3 dígitos.
	CMP R1, R2
	JGE imprime_score_max
	MOV R3, 10d
	MOV R4, 30H
	MOV R2, R1
	
	MOD R2, R3			; Escreve na string "string_score" o dígito de menor peso do score.
	ADD R2, R4
	MOVB [R0], R2
	SUB R0, 1
	
	DIV R1, R3			; Escreve na string "string_score" o segundo dígito de menor peso.
	MOV R2, R1
	MOD R2, R3
	ADD R2, R4
	MOVB [R0], R2
	SUB R0, 1
	
	DIV R1, R3			; Escreve na string "string_score" o dígito de maior peso.
	ADD R1, R4
	MOVB [R0], R1
	
	MOV R2, string_score		; Executa a rotina "muart_out" para que esta escreva a string "string_score" já alterada.
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
	
	MOV R2, string_score		; Executa a rotina "muart_out" para que esta escreva a string "string_score" já alterada.
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
;* Descrição: Lança em jogo uma nova bomba numa coluna aleatória, se não houverem já em jogo 8 bombas.
;*	      
;*
;* Parâmetros: R10 (Contador usado para criação de valores aleatórios)
;* Retorna: --
;* Destrói: --
;* Notas: --
bomba_nova:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV R0, tab_bombas
	MOV R2, ref_bombas
	
	MOV R3, [R2]		
	CMP R3, 7			; Verifica se já existem em jogo 8 bombas.
	JGT bomba_nova_fim
	
	ADD R3, 1		
	MOV [R2], R3
bomba_nova_ciclo:			; Procura na tabela "tab_bombas" uma entrada que não esteja a ser usada.
	MOV R2, [R0]		
	CMP R2, -1			; Verifica se a entrada contém o VAL_NULO.
	JZ bomba_nova1
	
	ADD R0, 2
	JMP bomba_nova_ciclo

bomba_nova1:				; Escreve na entrada encontrada uma nova bomba, na posição vertical 0 e
	MOV R2, R10			;calcula através de "R10" um valor aleatório para a posição horizontal,
	MOV R1, 8			; usando a formula, sem alterar o seu valor: ("R10" mod 8)*4
	MOD R2, R1
	SHL R2, 2			; Multiplica o "R2" por 4.	
	MOV R1, R2
	CLR R2
	MOV [R0], R1
	MOV R3, 1			; "R3" = 1, indica a rotina "escreve_PS" para desenhar uma bomba no PIXEL_SCREEN.
	CALL escreve_PS			; Desenha no PIXEL_SCREEN a bomba na sua posição inicial.
bomba_nova_fim:
	POP R3
	POP R2
	POP R1
	POP R0
	RET


;* -- bomba ----------------------------------------------------------------
;* 
;* Descrição: Executa a iteração das bombas, descendo-as uma posição no PIXEL_SCREEN.
;*	      Se atingirem o fim do PIXEL_SCREEN, desenha uma explosão, removendo uma vida.
;*	      Quando terminar a explosão, remove-as actualizando a cada mudança do seu estado		
;*	      o seu valor na tabela "tab_bombas".
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: Cada bomba que atinge o fim do PIXEL_SCREEN explode duas vezes, uma por cada execução da rotina.
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
	CMP R2, -1			; Verifica se a entrada contém o "VAL_NULO".
	JNZ bomba_desce
	
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_desce:				; Desce, uma posição no PIXEL_SCREEN, a bomba em questão e, caso esta chegue à última posição
	MOVB R2, [R0]			;explode-a.
	MOV R1, [R0]
	MOV R3, 00FFH
	AND R1, R3
	MOV R3, MAX_PS
	
	BIT R2, 6
	JNZ bomba_apaga			; Caso a bomba já tenha chegado à última posição e explodido duas vezes, 
					;remove a bomba da tabela e apaga-a do "PIXEL SCREEN".
	BIT R2, 7
	JNZ bomba_explode2		; Caso a bomba já tenha chegado ao fundo do "PIXEL SCREEN", na última iteração, e executado uma explosão, 
					;salta para "bomba_explode2".
	CMP R2, R3
	JEQ bomba_explode		; Caso a bomba nesta iteração atinga o fim do "PIXEL_SCREEN", salta para "bomba_explode".
	
	MOV R3, 1			; Apaga a bomba na posição actual.
	CALL escreve_PS
	ADD R2, 1
	CALL escreve_PS			; Desenha a bomba na posição seguinte
	MOVB [R0], R2
	
	SUB R4, 1			; Marca a bomba como tratada.
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_explode:				; Apaga a bomba na posição actual.
	MOV R3, 1
	CALL escreve_PS
	
	SET R2, 7			; Marca a bomba como explodida uma vez na tabela.
	MOVB [R0], R2
	CALL explosao1			; Desenha a explosão
	
	SUB R4, 1			; Marca a bomba como tratada e verifica se era a última bomba da tabela "tab_bombas".
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_explode2:
	
	SET R2, 6			; Marca a bomba como explodida duas vezes.
	MOVB [R0], R2
	CALL explosao1			; Apaga no "PIXEL_SCREEN" a primeira explosão.
	CALL explosao2			; Desenha no "PIXEL_SCREEN" a segunda explosão.
	
	SUB R4, 1			; Marca a bomba como tratada e verifica se era a última bomba da tabela "tab_bombas".
	JZ bomba_fim
	ADD R0, 2
	JMP bomba_ciclo
	
bomba_apaga:				
	CALL explosao2			; Apaga, do PIXEL_SCREEN, a segunda explosão.

	MOV R1, VAL_NULO		; Remove a bala da tabela "tab_bombas".
	MOV [R0], R1
	
	MOV R2, vidas
	MOV R1, [R2]
	SUB R1, 1			; Decrementa uma vida.
	JZ game_over			; Verifica se era a última vida. Caso seja, salta para "game_over".
	
	MOV [R2], R1			; Actualiza as vidas tanto em memória como no display hexadecimal.
	CALL display
	
	MOV R2, ref_bombas		; Actualiza "ref_bombas" com a quantidade de bombas.
	MOV R1, [R2]
	SUB R1, 1
	MOV [R2], R1
	
	SUB R4, 1			; Marca a bomba como tratada e verifica se era a última bomba da tabela "tab_bombas".
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
;* Descrição: Desenha no PIXEL_SCREEN uma explosão.
;*	     
;*	      
;*
;* Parâmetros: R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: --
;* Destrói: --
;* Notas: No parametro "R2", apenas os primeiros 5 bits de menor peso serão usados.
explosao1:
	PUSH R1
	PUSH R2
	
	MOV R3, 1FH			; Coloca a zero todos os bits de "R2", exepto os primeiros 5 de menor peso,
	AND R2, R3			;de forma a retirar os bits que marcam a bomba como explodida na tabela "tab_bombas".
	
	MOV R3, 1
	CALL escreve_PS			; Acende os pixeis que desenham a explosão.
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
;* Descrição: Desenha no PIXEL_SCREEN uma explosão.
;*
;* Parâmetros: R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: --
;* Destrói: --
;* Notas: No parametro "R2", apenas os primeiros 5 bits de menor peso serão usados.
explosao2:
	PUSH R1
	PUSH R2
	
	MOV R3, 1FH			; Coloca a zero todos os bits de "R2", excepto os primeiros 5 de menor peso,
	AND R2, R3			;de forma a retirar os bits que marcam a bomba como explodida na tabela "tab_bombas".
	
	MOV R3, 1
	CALL escreve_PS			; Acende os pixeis que desenham explosão.
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
;* Descrição: Termina o jogo, limpando o "PIXEL-SCREEN" e colocando o Display a 0
;*	     e desactiva as interrupções "int0" e "int1".
;*	      Para sair da rotina é necessário pressionar a tecla associada ao iniciar do jogo.
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: De forma a ser uma rotina que pode ser executada com a instrução "CALLF",
;*	  esta coloca o registo "RL" a zero antes de saltar para "inicio".

game_over:				
	DI0
	DI1				; Desactiva as interrupções relacionadas com os clocks.
	
	CALL limpa_PS			; Desliga todos os pixeis do PIXEL_SCREEN.
	CLR R1
	CALL display			; Coloca o display e as vidas a zero.
	
	MOV R2, string2			; Imprime no terminal a string2.
	CALL muart_out
	
	MOV R1, 1000d			; Coloca o código brevemente em pausa de forma a dar tempo à string2 de ser impressa no terminal.
	CALL espera
	
	CALL imprime_score		; Imprime no terminal o score atingido no jogo

	CALL start			; Coloca o código em pausa até que seja pressionada a tecla associada a reiniciar o jogo.
	CLR RL				; Coloca o registo "RL" pois a rotina não efectua nenhum "RETF" e por isso não vai usar o seu valor.
	CALLF reboot			; Efectua um "CALLF" para a rotina "reboot", a qual não retorna.

;* -- fire_bala ----------------------------------------------------------------
;* 
;* Descrição: Caso ainda não existam em jogo 8 balas, é inicializada uma nova bala na coordenada acima da posição
;*	      actual do canhão, actualizando tanto a tabela correspondente às posições das balas, como o PIXEL SCREEN.
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
fire_bala:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	
	MOV R0, tab_balas
	MOV R2, ref_balas
	
	MOV R3, [R2]			; Verifica se o limite máximo de balas(8) em jogo já foi alcançado.
	CMP R3, 7			;caso não tenha sido, adiciona 1 ao valor actual de balas em jogo guardado em memória(ref_balas).
	JGT fire_bala_fim
	
	ADD R3, 1		
	MOV [R2], R3

fire_bala_ciclo:			; Procura na tabela "tab_balas" a primeira entrada com o valor neutro (VAL_NULO).
	MOV R2, [R0]		
	CMP R2, -1			; Verifica se a entrada contém o VAL_NULO.
	JZ fire_bala1	
	
	ADD R0, 2
	JMP fire_bala_ciclo

fire_bala1:				; Regista na primeira entrada livre da tabela "tab_balas" uma nova bala e desenha-a no PIXEL_SCREEN.
	MOV R3, pos_canhao
	MOV R1, [R3]			; Coloca em "R1" a coordenada horizontal actual do canhão.
	MOV R2, 29d			; Coloca em "R2" a coordenada vertical correspondente à posição imediatamente acima do canhão.
	
	CLR R3				; Coloca "R3" a zero de forma a indicar a rotina "escreve_PS" para desenhar no PIXEL_SCREEN
	CALL escreve_PS			;um pixel na coordenada dos parâmetros "R1"(horizontal) e "R2"(vertical".
	
	SHL R2, 8
	ADD R2, R1
	MOV [R0], R2			; Coloca em memória a informação correspondente à coordenada da bala.

fire_bala_fim:				; Termina a rotina.
	POP R3
	POP R2
	POP R1
	POP R0
	RETF

;* -- bala ----------------------------------------------------------------
;* 
;* Descrição: Sobe todas as balas em jogo uma posição, actualizando o valor das suas coordenadas na tabela
;*	      "tab_balas". Caso alguma bala atinja uma bomba, ambas são removidas tanto do PIXEL_SCREEN como
;*	      das tabelas onde reside a informação das suas coordenadas e é incrementado 1 ao score.
;*	      As balas que cheguem ao topo do PIXEL_SCREEN são simplesmente removidas.
;*
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
bala:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	
	MOV R0, ref_balas		; Verifica se existe alguma bala em jogo, salta para bala_fim caso não exista.
	MOV R4, [R0]
	MOV R0, tab_balas
	
	AND R4, R4
	JZ bala_fim
bala_ciclo:				; Localiza na tabela "tab_balas" as entradas correspondentes a cada uma das balas em jogo.

	MOV R2, [R0]
	CMP R2, -1			; Verifica se a entrada contém o VAL_NULO.
	JNZ bala_estado
	
	ADD R0, 2
	JMP bala_ciclo
	
bala_estado:
	MOVB R2, [R0]
	MOV R1, [R0]
	MOV R3, 00FFH		
	AND R1, R3
	
	CMP R2, 1
	JN bala_remove			; Verifica se a bala nesta interacção ultrapassa o topo do PIXEL_SCREEN.
	
	CALL colisao			; Verifica se existe uma bomba na posição imediatamente acima da bala ou na mesma posição.
	BIT R3, 0			; Se a rotina colisão devolver "R3" com o valor 1, significa que houve colisão e foi removida a bomba.
	JNZ bala_remove
	
bala_sobe:				; Sobe a bala uma posição na vertical actualizando a tabela "tab_balas".
	
	MOV R3, 2d			; Coloca "R3" a 2 de forma a indicar a rotina "escreve_PS" dois pixeis,
	CALL escreve_PS			;um na coordenada do pixel actual para o desligar e outra na superior para criar a ilusão da subida da bala.
	SUB R2, 1
	MOVB [R0], R2
	
	SUB R4, 1			; Marca a bala como tratada e verifica se era a última da tabela "tab_balas".
	JZ bala_fim
	ADD R0, 2
	JMP bala_ciclo
	
bala_remove:				; Desliga o pixel correspondente à bala que atingiu a última posição.
	CLR R3				; Coloca "R3" a zero de forma a indicar a rotina escreve_PS para desenhar no PIXEL_SCREEN
	CALL escreve_PS			;um pixel na coordenada dos parametros "R1"(horizontal) e "R2"(vertical".
	MOV R2, VAL_NULO		; Actualiza a tabela removendo a bala.
	MOV [R0], R2
	
	MOV R3, ref_balas		; Decrementa a "ref_balas" 1 de forma a descontar ao número de balas em jogo a bala removida.
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
;* Descrição: Verifica se existiu colisão entre uma bala e alguma bomba.
;*	      Caso tenha havido, remove da tabela "tab_bombas" a entrada referente a bomba que colidiu,
;*	      decrementa 1 a "ref_bombas" de forma a actualizar o número de balas em jogo e apaga
;*	      a bomba do PIXEL_SCREEN.
;*
;* Parâmetros:R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: R3
;* Destrói: --
;* Notas: (R3 retorna com o valor 0 caso não tenha existido colisão e 1 caso tenha).
colisao:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R5
	
	SUB R2, 1			; Subtrai a "R2" e "R1" 1 obtendo assim a coordenada do primeiro pixel de uma possivel bomba
	SUB R1, 1			;imediatamente acima da bala.
	
	MOV R3, R1			; Verifica se a bala se encontra numa posição onde seja possivel existir uma bomba,
	MOV R5, 4			;as coordenadas onde nunca existem bombas são as todas as que têm como coordenada horizontal um múltiplo de 4.
	MOD R3, R5
	JNZ colisao_fim	
	
	MOV R0, PIXEL_BASE	
	CALL calc_endereco
	CALL masc_bit
	
	MOVB R5, [R0]			; Verifica se existe uma bomba na posição acima da bala verificando se o primeiro bit da coluna,
	AND R5, R3			;que identifica na tabela "tab_bombas" as bombas, está aceso.
	JZ colisao1
	
	MOV R5, R2			; Confirmado que existe uma bomba, coloca as coordenadas da bomba em "R5" e salta para "colisao_ciclo".
	SHL R5, 8
	ADD R5, R1
	MOV R0, tab_bombas
	JMP colisao_ciclo
	
colisao1:
	ADD R2, 1
	MOV R0, PIXEL_BASE		; Confirmado que não existe nenhuma bomba na posição imediatamente acima da bala,

	CALL calc_endereco		;verifica se existe uma bomba na mesma posição da bala, o que pode acontecer
	CALL masc_bit			;devido a alguma falha num dos clocks.
	
	MOVB R5, [R0]			; Verifica se existe bomba na posição da bala, verificando se o primeiro bit da coluna,
	AND R5, R3			;que identifica na tabela "tab_bombas" as bombas está aceso.
	JZ colisao_fim
	
	MOV R5, R2			; Confirmado que existe uma bomba, coloca as coordenadas da bomba em "R5" e avança para "colisao_ciclo".
	SHL R5, 8
	ADD R5, R1
	MOV R0, tab_bombas
	
colisao_ciclo:				; Procura na tabela "tab_bombas" a bomba com as coordenadas iguais ao valor de "R5".
	MOV R3, [R0]
	CMP R3, R5
	JEQ colisao_rm_bomb
	
	ADD R0, 2
	JMP colisao_ciclo
	
colisao_rm_bomb:			; Remove da tabela "tab_bombas" a bomba encontrada, actualizando também "ref_bombas" com o
	MOV R3, 1			;número de balas que se encontram agora em jogo.
	CALL escreve_PS

	MOV R3, VAL_NULO
	MOV [R0], R3
	
	MOV R5, ref_bombas
	MOV R3, [R5]
	SUB R3, 1
	MOV [R5], R3
	
	MOV R3, 1
	ADD R10, 1
	
	MOV R2, score			; Incrementa um a "score" actualizando assim o número de balas destruídas pelo utilizador.
	MOV R1, [R2]			;(se o score atingir o valor FFFFH não incrementa).
	ADD R1, 1
	JV colisao_fim2
	
	MOV [R2], R1
	JMP colisao_fim2
	
colisao_fim:				; Caso não tenha sido removida uma bomba.
	CLR R3
colisao_fim2:				; Caso tenha sido removida uma bomba.
	POP R5
	POP R2
	POP R1
	POP R0
	RET
	
;* -- canhao_dir ----------------------------------------------------------------
;* 
;* Descrição: Desloca o canhão 2 pixeis para a direita no PIXEL_SCREEN actualizando
;*	      a sua posição na variável "pos_canhao".
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: ( Se o canhão estiver na posição 31 horizontal a rotina não faz nada.)
canhao_dir:			
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV R0, pos_canhao
	MOV R1, [R0]
	MOV R2, MAX_PS			; MAX_PS é o valor da última posição horizontal à direita do PIXEL_SCREEN
	CMP R1, R2			;que coincide com a última posição à direita que o canhão pode ocupar.
	JEQ canhao_dir_fim
	
	CALL desenha_canhao		; Apaga o canhão do PIXEL_SCREEN.
	ADD R1, 2
	CALL desenha_canhao		; Desenha o canhão no PIXEL_SCREEN na nova posição.
	MOV [R0], R1
canhao_dir_fim:
	POP R2
	POP R1
	POP R0
	RETF
	
	
;* -- canhao_esq ----------------------------------------------------------------
;* 
;* Descrição: Desloca o canhão 2 pixeis para a esquerda no PIXEL SCREEN, actualizando
;*	      a sua posição na variável "pos_canhao".
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
canhao_esq:			
	PUSH R0
	PUSH R1
	PUSH R2

	MOV R0, pos_canhao
	MOV R1, [R0]
	CMP R1, 1			; 1 é o valor da última posição horizontal à esquerda que o canhão pode ocupar.
	JEQ canhao_esq_fim
	
	CALL desenha_canhao		; Apaga o canhão do PIXEL SCREEN.
	SUB R1, 2
	CALL desenha_canhao		; Desenha o canhão no PIXEL SCREEN na nova posição.
	MOV [R0], R1
canhao_esq_fim:
	POP R2
	POP R1
	POP R0
	RETF

;* -- escreve_PS ----------------------------------------------------------------
;* 
;* Descrição: Acende ou apaga pixeis no PIXEL SCREEN conforme o estado actual do pixeis em questão.
;*	      Esta rotina possui 3 modos de funcionamento:
;*	R3=0 : Liga ou desliga o pixel cujas coordenadas sejam R1(horizontal) e R2(vertical).(modo pixel)
;*	R3=1 : Liga ou desliga 3 pixeis sequenciais horizontalmente
;*	      cuja coordenada do primeiro à esquerda seja R1(horizontal) e R2(vertical).(modo bomba)
;*	R3=2 : Liga ou desliga 2 pixeis sequenciais verticalmente, 
;*	      cuja coordenada do inferior seja R1(horizontal) e R2(vertical).(modo bala)
;*
;* Parâmetros: R1(Coordenada horizontal), R2(Coordenada vertical), R3
;* Retorna: --
;* Destrói: --
;* Notas: (O modo bomba só funciona se "R1" for igual a um seguintes valores:
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
	CALL	calc_endereco		; Calcula o endereço do byte do PIXEL_SCREEN onde se encontra o pixel em questão.
	CALL	masc_bit		; Cria uma máscara com 1 no bit que representa o pixel em questão no byte endereçado.
	JMP escreve_PS_imprime_sai
	
escreve_PS_bomb:			; Executa o modo bomba desenhando no PIXEL_SCREEN 3 pixeis em apenas uma operação de escrita.
	CALL	calc_endereco		; Calcula o endereço do byte do PIXEL_SCREEN onde se encontra o pixel em questão.
	MOV	R3, 8d
	MOV	R7, R1			; Usa a fórmula ("R1" mod 8) para verificar se as coordenadas dizem respeito ao primeiro ou
	MOD	R7, R3			;segundo nibble do byte para o qual "calc_endereço" calculou o endereço do PIXEl_SCREEN.
	MOV	R3, 0E0H
	CMP	R7, 4
	JLT	escreve_PS_imprime_sai
	SHR	R3, 4
	JMP	escreve_PS_imprime_sai
	
escreve_PS_bala:			; Executa o modo bala desenhando primeiro um pixel nas coordenadas "R1" e "R2" e desenhando
					;em "escreve_PS_imprime_sai" outro pixel imediatamente acima.
	CALL	calc_endereco		; Calcula o endereço do byte do PIXEL_SCREEN onde se encontra o pixel em questão.
	CALL	masc_bit		; Cria uma máscara com 1 no bit que representa o pixel em questão no byte endereçado.
	
	MOVB R7, [R0]			; Liga ou desliga o pixel em questão no PIXEL_SCREEN.
	XOR R7, R3
	MOVB [R0], R7
	SUB R0, 4			; Subtraindo 4 ao endereço do pixel, dado que o PIXEl SCREEN possui 4 byte em cada linha,
	JMP	escreve_PS_imprime_sai	;altera o endereço para o pixel imediatamente acima do anterior.

escreve_PS_imprime_sai:
	MOVB R7, [R0]			; Liga ou desliga o pixel em questão no PIXEL_SCREEN.
	XOR R7, R3
	MOVB [R0], R7
	
	POP R7
	POP R3
	POP R1
	POP R0
	RET

;* -- calc_endereco ----------------------------------------------------------------
;* 
;* Descrição: Actualiza o valor de R0 com o endereço do byte do PIXEL-SCREEN pertencente,
;*	      ao bit de coordenadas "R1"(horizontal) e "R2"(vertical).
;*
;* Parâmetros: 	R0(PIXEL_BASE), R1(Coordenada horizontal), R2(Coordenada vertical)
;* Retorna: R0 
;* Destrói: --
;* Notas: --
calc_endereco:
	PUSH R1
	PUSH R3
	
	MOV R3, 4			; Efectua a seguinte fórmula para calcular o endereço do byte,
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
;* Descrição: Cria uma máscara, colocando o bit do byte que "R1" define a 1.
;*	      
;*
;* Parâmetros: 	R1(Ordem do bit a colocar a 1)
;* Retorna: R3
;* Destrói: --
;* Notas: --
masc_bit:
	PUSH R1
	MOV R3, 8
	MOD R1, R3			; Efectua a seguinte fórmula para obter em "R1" a ordem do bit
	MOV R3, 100H			;a colocar a 1.
	ADD R1, 1
masc_bit_1:
	SHR R3, 1			; Efectua tantos "SHR" a "R3"=100H quanta a ordem do bit em questão
	SUB R1, 1			;de forma a colocar 1 no bit em questão.(Foi considerado o bit de menor peso como o 1º bit)
	JNZ masc_bit_1
	
	POP R1
	RET

;* -- LE_tec ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina lê da "PUSH-MATRIX" o valor da tecla pressionada e coloca o seu valor
;*	      na variável "tecla". 
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: (Caso nenhuma tecla esteja pressionada coloca em "tecla" o VAL_NULO)
LE_tec:
	PUSH R0
	PUSH R4
	PUSH R3
	PUSH R1
	MOV R0, POUT_2
	MOV R4, PIN
	
	CALL testa_tec		; Verifica se alguma tecla está pressionada, e obtém o valor
	AND R3, R3		;da linha e da coluna do teclado correspondentes à tecla.
	JZ LE_tec_null		; Caso nenhuma tecla esteja pressionada.
	
	CALL conv_tec		; Converte o número da linha e da coluna da tecla pressionada para o seu valor.
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
;* Descrição: Esta rotina testa o teclado por uma tecla pressionada,
;*	     coloca o valor da linha correspondente a tecla no teclado em "R3",
;*	      e o valor da coluna em "R1".
;*
;* Parâmetros: 	R0(POUT_2), R4(PIN)
;* Retorna: R1, R3 
;* Destrói: --

;* Notas: (R3) e (R2) terão o valor 0 se nenhuma tecla for pressionada.
testa_tec:
	PUSH R2
	MOV R2, 000FH			
	MOV R3, 08H	
testa_tec_1:
	MOVB [R0], R3		; Activa uma determinada coluna verificando se nesta existe com o valor 1. 
	MOVB R1, [R4]		;Caso isto aconteça, significa que foi pressionada uma tecla que é definida por essa linha e coluna.
	
	AND R1, R2		; Isola o primeiro nibble de menor peso que corresponde à informação 
	JNZ	volta_tec	;recebida pela "PUSH MATRIX" (o 4º bit corresponde ao valor do clock1).
	SHR R3, 1		; Executa um "SHR" a "R3" de forma a testar a linha seguinte.
	JZ	volta_tec
	JMP testa_tec_1
volta_tec:
	POP R2
	RET

;* -- conv_tec ----------------------------------------------------------------
;* 
;* Descrição: Esta rotina converte o valor da coluna e da linha da tecla
;*	      pressionada pela "PUSH MATRIX"( R1 e R3 respectivamente),
;*	      no valor da mesma, colocando o seu valor em "R3".
;*	      
;*
;* Parâmetros: 	R1(Coluna da tecla), R3(Linha da tecla)
;* Retorna: R3 
;* Destrói: --
;* Notas: --
conv_tec:	
	PUSH R4
	PUSH R5
	
	MOV R4, R1
	CLR R5
conv_tec_COL:			; A cada iteração incrementa a "R5" 1 e executa a "R4" um "SHR" até que este seja igual a zero,
	ADD R5, 1		;contando assim a quantidade de zeros à direita de "R4" e obtendo o valor da ordem do único bit a 1 de "R1".
	SHR R4, 1
	JNZ conv_tec_COL
	MOV R1, R5
	
	MOV R4, R3
	CLR R5
conv_tec_LIN:			; A cada iteração incrementa a "R5" 1 e executa a "R4" um "SHR" até que este seja igual a zero,
	ADD R5, 1		;contando assim a quantidade de zeros a direita de "R4" e obtendo o valor da ordem do único bit a 1 de "R3".
	SHR R4, 1		
	JNZ conv_tec_LIN
	MOV R3, R5
	
	SUB R1, 1
	SUB R3, 1
	MOV R5, 4		; Aplica a seguinte fórmula para calcular o valor da tecla pressionada na "PUSH MATRIX",
	MUL R3, R5		;algo que apenas é possível através de uma fórmula devido ao facto das teclas terem valores sequenciais.
	ADD R3, R1		; ("R1" - 1 + ("R3" - 1) * 4)
			
	POP R5
	POP R4
	RET
	
;* -- desenha_canhao ----------------------------------------------------------------
;* 
;* Descrição: Desenha no PIXEL-SCREEN um canhão, composto por dois pixeis, um na última posição vertical
;*	      e outro imediatamente acima, os dois na posição horizontal do valor do registo "R1".
;*	      
;*
;* Parâmetros: 	R1(Valor horizontal do canhão.)
;* Retorna: --
;* Destrói: --
;* Notas: --
desenha_canhao:
	PUSH R2
	PUSH R3

	MOV R3, 2d		; "R3"=2d indica à rotina "escreve_PS" para executar o "modo bala", que desenha dois pixeis verticais,	
				;como é pretendido.
	MOV R2, MAX_PS		; MAX_PS corresponde a última posição do PIXEL-SCREEN, neste contexto última posição vertical.
	CALL escreve_PS		; Desenha o canhão.
	
	POP R3
	POP R2
	RET
	
;* -- preenche_tab_tec ----------------------------------------------------------------
;* 
;* Descrição: Preenche a tabela "tab_teclas" com as rotinas a executar para cada umas das teclas
;*	      da "PUSH MATRIX" e coloca a rotina associada a cada tecla na posição da tabela correspondente.
;*	      
;*
;* Parâmetros: --
;* Retorna: --
;* Destrói: --
;* Notas: --
preenche_tab_tec:
	PUSH R0
	PUSH R1
	PUSH R2
	
	MOV R0, tab_teclas
	MOV R1, 16d		; 16 é o número de teclas existente no "PUSH MATRIX".
	MOV R2, no_tec		; Rotina a colocar em teclas não associadas a nenhuma acção.
	
preeche_tab_tec1:		; Coloca em todas as posições da tabela "tab_teclas" a rotina "no_tec".
	MOV [R0], R2
	ADD R0, 2
	SUB R1, 1
	JNZ preeche_tab_tec1
	
	MOV R0, tab_teclas	
	
	MOV R2, TEC_START	; Coloca a rotina associada ao reiniciar do jogo na posição associada à tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, reboot
	MOV [R2], R1
	
	MOV R2, TEC_PAUSE	; Coloca a rotina associada a colocar o jogo em pausa na posição associada à tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, pause
	MOV [R2], R1
	
	MOV R2, TEC_END		; Coloca a rotina associada a terminar o jogo na posição associada à tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, termina
	MOV [R2], R1
	
	MOV R2, TEC_CANH_E	; Coloca a rotina associada a deslocar o canhão para a esquerda na posição associada à tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, tec_canhao_esq	
	MOV [R2], R1
	
	MOV R2, TEC_CANH_D	; Coloca a rotina associada a deslocar o canhão para a direita na posição associada à tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, tec_canhao_dir
	MOV [R2], R1
	
	MOV R2, TEC_FIRE	; Coloca a rotina associada a disparar uma bala no jogo na posição associada à tecla.
	SHL R2, 1
	ADD R2, R0
	MOV R1, fire_bala
	MOV [R2], R1
	
	POP R0
	POP R1
	POP R2
	RET
