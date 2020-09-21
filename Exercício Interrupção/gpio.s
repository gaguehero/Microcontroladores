; gpio.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; Ver 1 19/03/2018
; Ver 2 26/08/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declara��es EQU - Defines
; ========================
; ========================
; Defini��es dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08
; ========================
; Defini��es dos Ports
; PORT K
GPIO_PORTK_LOCK_R			EQU	   0x40061520
GPIO_PORTK_CR_R     		EQU    0x40061524
GPIO_PORTK_AMSEL_R  		EQU    0x40061528
GPIO_PORTK_PCTL_R   		EQU    0x4006152C
GPIO_PORTK_DIR_R    		EQU    0x40061400
GPIO_PORTK_AFSEL_R  		EQU    0x40061420
GPIO_PORTK_DEN_R    		EQU    0x4006151C
GPIO_PORTK_PUR_R    		EQU    0x40061510
GPIO_PORTK_DATA_R   		EQU    0x400613FC
GPIO_PORTK          		EQU    2_000001000000000
; PORT M
GPIO_PORTM_LOCK_R   		EQU    0x40063520
GPIO_PORTM_CR_R     		EQU    0x40063524
GPIO_PORTM_AMSEL_R  		EQU    0x40063528
GPIO_PORTM_PCTL_R   		EQU    0x4006352C
GPIO_PORTM_DIR_R    		EQU    0x40063400
GPIO_PORTM_AFSEL_R  		EQU    0x40063420
GPIO_PORTM_DEN_R    		EQU    0x4006351C
GPIO_PORTM_PUR_R    		EQU    0x40063510
GPIO_PORTM_DATA_R   		EQU    0x400633FC
	
GPIO_PORTM_IS_R     		EQU    0x40063404
GPIO_PORTM_IBE_R    		EQU    0x40063408
GPIO_PORTM_IEV_R    		EQU    0x4006340C
GPIO_PORTM_IM_R     		EQU    0x40063410
GPIO_PORTM_ICR_R       		EQU	   0x4006341C
GPIO_PORTM          		EQU    2_000100000000000
; PORT N
GPIO_PORTN_AHB_LOCK_R    	EQU    0x40064520
GPIO_PORTN_AHB_CR_R      	EQU    0x40064524
GPIO_PORTN_AHB_AMSEL_R   	EQU    0x40064528
GPIO_PORTN_AHB_PCTL_R    	EQU    0x4006452C
GPIO_PORTN_AHB_DIR_R     	EQU    0x40064400
GPIO_PORTN_AHB_AFSEL_R   	EQU    0x40064420
GPIO_PORTN_AHB_DEN_R     	EQU    0x4006451C
GPIO_PORTN_AHB_PUR_R     	EQU    0x40064510	
GPIO_PORTN_AHB_DATA_R    	EQU    0x400643FC
GPIO_PORTN               	EQU    2_001000000000000
	
; NVIC
NVIC_PRI18_R            	EQU    0xE000E448
NVIC_EN2_R              	EQU	   0xE000E108
	


; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma fun��o do arquivo for chamada em outro arquivo	
        EXPORT GPIO_Init            ; Permite chamar GPIO_Init de outro arquivo
		EXPORT PortN_Output
		EXPORT GPIOPortM_Handler
		IMPORT EnableInterrupts
		IMPORT DisableInterrupts
		IMPORT SysTick_Wait1ms
		; ****************************************
		; Exportar as fun��es usadas em outros arquivos
		; ****************************************
									

;--------------------------------------------------------------------------------
; Fun��o GPIO_Init
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
GPIO_Init
;=====================
; ****************************************
; Escrever fun��o de inicializa��o dos GPIO
; Inicializar todas as portas utilizadas.
; ****************************************
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; ap�s isso verificar no PRGPIO se a porta est� pronta para uso.
; enable clock to GPIOF at clock gating register
            LDR     R0, =SYSCTL_RCGCGPIO_R  		;Carrega o endere�o do registrador RCGCGPIO
			MOV		R1, #GPIO_PORTK                 ;Seta o bit da porta K
			ORR     R1, #GPIO_PORTM					;Seta o bit da porta M, fazendo com OR
			ORR     R1, #GPIO_PORTN					;Seta o bit da porta N, fazendo com OR
            STR     R1, [R0]						;Move para a mem�ria os bits das portas no endere�o do RCGCGPIO
 
            LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endere�o do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO  LDR     R1, [R0]						;L� da mem�ria o conte�do do endere�o do registrador
			MOV     R2, #GPIO_PORTK                 ;Seta os bits correspondentes �s portas para fazer a compara��o
			ORR     R2, #GPIO_PORTM                 ;Seta o bit da porta M, fazendo com OR
			ORR     R1, #GPIO_PORTN					;Seta o bit da porta N, fazendo com OR			
            TST     R1, R2							;ANDS de R1 com R2
            BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o la�o. Sen�o continua executando
 
; 2. Limpar o AMSEL para desabilitar a anal�gica
            MOV     R1, #0x00						;Colocar 0 no registrador para desabilitar a fun��o anal�gica
            LDR     R0, =GPIO_PORTK_AMSEL_R     ;Carrega o R0 com o endere�o do AMSEL para a porta K
            STR     R1, [R0]						;Guarda no registrador AMSEL da porta K da mem�ria
            LDR     R0, =GPIO_PORTM_AMSEL_R		;Carrega o R0 com o endere�o do AMSEL para a porta M
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta M da mem�ria
            LDR     R0, =GPIO_PORTN_AHB_AMSEL_R		;Carrega o R0 com o endere�o do AMSEL para a porta N
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta N da mem�ria
 
; 3. Limpar PCTL para selecionar o GPIO
            MOV     R1, #0x00					    ;Colocar 0 no registrador para selecionar o modo GPIO
            LDR     R0, =GPIO_PORTK_PCTL_R		;Carrega o R0 com o endere�o do PCTL para a porta K
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta K da mem�ria
            LDR     R0, =GPIO_PORTM_PCTL_R      ;Carrega o R0 com o endere�o do PCTL para a porta M
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta M da mem�ria
			LDR     R0, =GPIO_PORTN_AHB_PCTL_R      ;Carrega o R0 com o endere�o do PCTL para a porta N
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta N da mem�ria
; 4. DIR para 0 se for entrada, 1 se for sa�da
            LDR     R0, =GPIO_PORTK_DIR_R		;Carrega o R0 com o endere�o do DIR para a porta K
			MOV     R1, #2_10000000					;PK7
            STR     R1, [R0]						;Guarda no registrador
			LDR		R0, =GPIO_PORTN_AHB_DIR_R		;Carrega o R0 com o endere�o do DIR para a porta N
			MOV     R1, #2_00000011                 ;PN1 & PN1 para LED
			STR     R1, [R0]						;Guarda no reg
			; O certo era verificar os outros bits da PF para n�o transformar entradas em sa�das desnecess�rias
            LDR     R0, =GPIO_PORTM_DIR_R			;Carrega o R0 com o endere�o do DIR para a porta M
            MOV     R1, #0x00               		;Colocar 0 no registrador DIR para funcionar com sa�da
            STR     R1, [R0]						;Guarda no registrador PCTL da porta J da mem�ria
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO 
;    Sem fun��o alternativa
            MOV     R1, #0x00						;Colocar o valor 0 para n�o setar fun��o alternativa
            LDR     R0, =GPIO_PORTK_AFSEL_R		    ;Carrega o endere�o do AFSEL da porta F
            STR     R1, [R0]						;Escreve na porta
            LDR     R0, =GPIO_PORTM_AFSEL_R         ;Carrega o endere�o do AFSEL da porta J
            STR     R1, [R0]                        ;Escreve na porta
			LDR     R0, =GPIO_PORTN_AHB_AFSEL_R     ;Carrega o endere�o do AFSEL da porta N
            STR     R1, [R0]                        ;Escreve na porta
; 6. Setar os bits de DEN para habilitar I/O digital
            LDR     R0, =GPIO_PORTK_DEN_R			;Carrega o endere�o do DEN
            MOV     R1, #2_10000000                 ;Ativa os pinos PK7 como I/O Digital
            STR     R1, [R0]						;Escreve no registrador da mem�ria funcionalidade digital 
			
			LDR		R0, =GPIO_PORTN_AHB_DEN_R		;Carrega o endere�o do DEN
			MOV 	R1, #2_00000011					;Ativa os pinos PN0 e PN1 como I/O Digital
			STR		R1, [R0]						;Escreve no reg da mem�ria func digital
 
            LDR     R0, =GPIO_PORTM_DEN_R			;Carrega o endere�o do DEN
			MOV     R1, #2_00000001                 ;Ativa o pino PM0 como I/O Digital      
            STR     R1, [R0]                        ;Escreve no registrador da mem�ria funcionalidade digital
			
; 7. Para habilitar resistor de pull-up interno, setar PUR para 1
			LDR     R0, =GPIO_PORTM_PUR_R			;Carrega o endere�o do PUR para a porta M
			MOV     R1, #2_00000001						;Habilitar funcionalidade digital de resistor de pull-up 
                                                        ;nos bits 0 e 1
            STR     R1, [R0]							;Escreve no registrador da mem�ria do resistor de pull-up	
			
; INTERRUP��ES
; 8.Desabilitar a interrup��o no registrador IM
			LDR R0, =GPIO_PORTM_IM_R		;Carrega o endere�o de IM para a porta M
			MOV R1, #2_00					;Desabilitar interrup��es
			STR R1, [R0]						;Escreve no reg
; 9.Configurar o tipo de interrup��o por borda no registrador IS			
			LDR R0, =GPIO_PORTM_IS_R		;Carrega o endere�o de IS para a porta M
			MOV R1, #2_00					;Por Borda
			STR R1, [R0]						;Escreve no reg
; 10.Configurar borda �nica no registrador IBE
			LDR R0, =GPIO_PORTM_IBE_R		;Carrega o endere�o de IBE para a porta M
			MOV R1, #2_00					;Borda �nica
			STR R1, [R0]						;Escreve no reg
; 11.Configurar borda de descida (bot�o pressionado) no registrador IEV			
			LDR R0, =GPIO_PORTM_IEV_R		;Carrega o endere�o de IEV para a porta M
			MOV R1, #2_00					;Borda de descida
			STR R1, [R0]						;Escreve no reg
; 12.Habilitar a interrup��o no registrador IM
			LDR R0, =GPIO_PORTM_IM_R		;Carrega o endere�o de IM para a porta M
			MOV R1, #2_01					;Habilitar interrup��es
			STR R1, [R0]						;Escreve no reg		

; Interrup��o n�mero 72
; 13. setar a prioridade no NVIC
		LDR		R0, =NVIC_PRI18_R
		MOV 	R1, #3
		LSL 	R1, R1, #5
		STR 	R1, [R0]
; 14. Habilitar interrup�es no NVIC
		LDR 	R0, =NVIC_EN2_R
		MOV 	R1, #1
		LSL 	R1, #8
		STR 	R1, [R0]
            
;retorno            
			BX      LR

; FUN��O OUTPUT
PortN_Output
	LDR R1, =GPIO_PORTN_AHB_DATA_R
	LDR R2, [R1]
	BIC R2, #2_00000011
	ORR R0, R0, R2
	STR R0, [R1]
	BX LR

GPIOPortM_Handler
	LDR R1, =GPIO_PORTM_ICR_R
	MOV R0, #2_00000001
	STR R0, [R1]
	
	EOR R10, R10, #2_1
	
	BX LR
	
	
    ALIGN                           ; garante que o fim da se��o est� alinhada 
    END                             ; fim do arquivo