; Exemplo.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 12/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma fun��o do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a fun��o Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma fun��o externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; fun��o <func>
		IMPORT  PLL_Init
		IMPORT  SysTick_Init
		IMPORT  SysTick_Wait1ms			
		IMPORT  GPIO_Init
		IMPORT	PortF_Output
        IMPORT  PortN_Output
        IMPORT  PortJ_Input

; -------------------------------------------------------------------------------
; Fun��o main()
Start  
; Comece o c�digo aqui <======================================================
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init              ;Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO
	MOV R4, #2_0001 ;Reg do Passeio (One Hot)
	MOV R5, #2_00000000 ;Reg do Contador Bin�rio
	MOV R6, #1000 ; Reg da Velocidade 
	MOV R7, #2_01 ;Reg de Modo (One Hot)

MainLoop
	BL TestaChave
	CMP R7, #2_01
	BLEQ	Passeio
	BLNE	Contador
	MOV R0, R6
	BL SysTick_Wait1ms ;AGUARDA UM SEGUNDO
	B	MainLoop

;Fun��o de Testa Chave
TestaChave
	PUSH {LR}
	BL PortJ_Input ;L� o estado das chaves
	MOV R9,R0 		;Guarda o valor de R0
	MOV R8, #100 ;aguarda 100ms para evitar efeito debouncing
	BL SysTick_Wait1ms ;sub rotina para aguardar 100ms
Verifica_SW1	
	CMP R9, #2_00000010			 ;Verifica se somente a chave SW1 est� pressionada
	BNE Verifica_SW2             ;Se o teste falhou, pula
	BL TrocaModo				;Vai para a subrotina de mudan�a de modo
	BL FimdoTeste 
Verifica_SW2	
	CMP R9, #2_00000001			 ;Verifica se somente a chave SW2 est� pressionada
	BNE Verifica_Ambas           ;Se o teste falhou, pula
	BL TrocaVelocidade			;Vai para a subrotina de mudan�a de velocidade
	BL FimdoTeste 
Verifica_Ambas					
	CMP R9, #2_00000000			 ;Verifica se ambas as chaves est�o pressionadas
	BNE FimdoTeste          		;Se o teste falhou, pula
	BL TrocaModo				;Vai para a subrotina de mudan�a de modo
	BL TrocaVelocidade			;Vai para a subrotina de mudan�a de velocidade
	BL FimdoTeste 
TrocaModo
	CMP R7, #2_01 ;VERIFICA SE EST� NO PRIMEIRO MODO
	ITE EQ
	LSLEQ R7, #1 ;SE SIM, TROCA PARA O SEGUNDO
	LSRNE R7, #1 ;SE N�O, VOLTA PARA O PRIMEIRO
	BX LR
TrocaVelocidade
	CMP R6, #1000 
	BEQ Mil
	CMP R6, #500
	BEQ Quinhentos
	CMP R6, #200
	BEQ Duzentos
Mil ;se mil, baixa pra 500
	MOV R6, #500
	BX LR
Quinhentos ;se quinhentos, baixa pra 200
	MOV R6, #200
	BX LR
Duzentos ;se duzentos, sobe pra 1000
	MOV R6, #1000
	BX LR
FimdoTeste
	BL PortJ_Input				 ;Chama a subrotina que l� o estado das chaves e coloca o resultado em R0
	CMP	R0, #2_00000011			 ;Verifica se nenhuma chave est� pressionada
	BNE FimdoTeste		 		 ;Se falhar, loop
	POP {LR}
	BX LR


	

;Fun��o do Passeio de Cela
Passeio ;Utilizando OneHot pra facilitar visualiza��o
	PUSH {LR}
	MOV R8, #0
	MOV R9, #0
;POSI��O 1
	CMP R4, #2_000001 ;TESTA SE O PRIMEIRO LED DEVE SER ACESO
	ITTT EQ
	MOVEQ R8, #2_00000010 ;GUARDA NUM REG TEMPOR�RIO
	LSLEQ R4, #1
	BEQ	FinalSwitch
;POSI��O 2	
	CMP R4, #2_000010
	ITT EQ
	MOVEQ R8, #2_00000001
	LSLEQ R4, #1
	BEQ	FinalSwitch
;POSI��O 3	
	CMP R4, #2_000100
	ITT EQ
	MOVEQ R9, #2_00010000
	LSLEQ R4, #1
	BEQ	FinalSwitch
;POSI��O 4	
	CMP R4, #2_001000
	ITT EQ
	MOVEQ R9, #2_00000001
	LSLEQ R4, #1
	BEQ	FinalSwitch
;POSI��O 5
	CMP R4, #2_010000
	ITT EQ
	MOVEQ R9, #2_00010000
	LSLEQ R4, #1
	BEQ	FinalSwitch
;POSI��O 6	
	CMP R4, #2_100000
	ITT EQ
	MOVEQ R8, #2_00000001
	MOVEQ R4, #1
FinalSwitch
	MOV R0, R9
	BL PortF_Output
	MOV R0, R8
	BL PortN_Output
	POP {LR}
	BX LR
	
;Fun��o do Contador Bin�rio
Contador
	PUSH {LR}
	AND R8, R5, #2_1100 ;mascara para pegar os bits da porta N
	LSR R8, #2			;posicionando os bits da porta N
	AND R9, R5, #2_0010 ;mascara para pegar os bits da porta F
	AND R10, R5, #2_0001 ;mascara para pegar os bits da porta F
	LSL R9, #3 ;posicionando o bit 4 da porta F
	ORR R0, R9, R10	;posicionando corretamente com o ORR os bits da porta F
	BL PortF_Output
	MOV R0, R8
	BL PortN_Output
	POP {LR}
	CMP R5, #15 ;comparando o valor do contador com o m�ximo
	ITE NE
	ADDNE R5, #1 ;se for menor, incrementa
	MOVEQ R5, #0 ;se for igual, zera
	BX LR
;Fun��o do Contador
	
    ALIGN                           ; garante que o fim da se��o est� alinhada 
    END                             ; fim do arquivo
