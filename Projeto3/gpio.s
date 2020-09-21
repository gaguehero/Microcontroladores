; gpio.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; Ver 1 19/03/2018
; Ver 2 26/08/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
; ========================
; ========================
; Definições dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08
; ========================
; Definições dos Ports
; PORT J
GPIO_PORTJ_AHB_LOCK_R    	EQU    0x40060520
GPIO_PORTJ_AHB_CR_R      	EQU    0x40060524
GPIO_PORTJ_AHB_AMSEL_R   	EQU    0x40060528
GPIO_PORTJ_AHB_PCTL_R    	EQU    0x4006052C
GPIO_PORTJ_AHB_DIR_R     	EQU    0x40060400
GPIO_PORTJ_AHB_AFSEL_R   	EQU    0x40060420
GPIO_PORTJ_AHB_DEN_R     	EQU    0x4006051C
GPIO_PORTJ_AHB_PUR_R     	EQU    0x40060510	
GPIO_PORTJ_AHB_DATA_R    	EQU    0x400603FC

GPIO_PORTJ_AHB_IM_R     	EQU    0x40060410
GPIO_PORTJ_AHB_IS_R 	    EQU    0x40060404
GPIO_PORTJ_AHB_IBE_R    	EQU    0x40060408
GPIO_PORTJ_AHB_IEV_R    	EQU	   0x4006040C
GPIO_PORTJ_AHB_ICR_R    	EQU    0x4006041C
GPIO_PORTJ_AHB_RIS_R    	EQU    0x40060414
GPIO_PORTJ               	EQU    2_000000100000000
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
NVIC_PRI12_R            	EQU    0xE000E430
NVIC_EN1_R              	EQU    0xE000E104

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT GPIO_Init            ; Permite chamar GPIO_Init de outro arquivo
		EXPORT PortN_Output
		EXPORT GPIOPortJ_Handler
		IMPORT EnableInterrupts
		IMPORT DisableInterrupts
		IMPORT SysTick_Wait1ms
		; ****************************************
		; Exportar as funções usadas em outros arquivos
		; ****************************************
									

;--------------------------------------------------------------------------------
; Função GPIO_Init
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
GPIO_Init
;=====================
; ****************************************
; Escrever função de inicialização dos GPIO
; Inicializar todas as portas utilizadas.
; ****************************************
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; após isso verificar no PRGPIO se a porta está pronta para uso.
; enable clock to GPIOF at clock gating register
            LDR     R0, =SYSCTL_RCGCGPIO_R  		;Carrega o endereço do registrador RCGCGPIO
			ORR     R1, #GPIO_PORTJ					;Seta o bit da porta J, fazendo com OR
			ORR     R1, #GPIO_PORTN					;Seta o bit da porta N, fazendo com OR
            STR     R1, [R0]						;Move para a memória os bits das portas no endereço do RCGCGPIO
 
            LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endereço do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO  LDR     R1, [R0]						;Lê da memória o conteúdo do endereço do registrador
			MOV     R2, #GPIO_PORTJ                 ;Seta o bit da porta J para poder fazer a comparação
			ORR     R1, #GPIO_PORTN					;Seta o bit da porta N, fazendo com OR			
            TST     R1, R2							;ANDS de R1 com R2
            BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o laço. Senão continua executando
 
; 2. Limpar o AMSEL para desabilitar a analógica
            MOV     R1, #0x00						;Colocar 0 no registrador para desabilitar a função analógica
            LDR     R0, =GPIO_PORTJ_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
            STR     R1, [R0]						;Guarda no registrador AMSEL da porta J da memória
            LDR     R0, =GPIO_PORTN_AHB_AMSEL_R		;Carrega o R0 com o endereço do AMSEL para a porta N
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta N da memória
 
; 3. Limpar PCTL para selecionar o GPIO
            MOV     R1, #0x00					    ;Colocar 0 no registrador para selecionar o modo GPIO
            LDR     R0, =GPIO_PORTJ_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta J da memória
			LDR     R0, =GPIO_PORTN_AHB_PCTL_R      ;Carrega o R0 com o endereço do PCTL para a porta N
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta N da memória
; 4. DIR para 0 se for entrada, 1 se for saída
			LDR		R0, =GPIO_PORTN_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
			MOV     R1, #2_00000001                 ;PN0 para LED
			STR     R1, [R0]						;Guarda no reg
			; O certo era verificar os outros bits da PF para não transformar entradas em saídas desnecessárias
            LDR     R0, =GPIO_PORTJ_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta J
            MOV     R1, #0x00               		;Colocar 0 no registrador DIR para funcionar com saída
            STR     R1, [R0]						;Guarda no registrador PCTL da porta J da memória
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO 
;    Sem função alternativa
            MOV     R1, #0x00						;Colocar o valor 0 para não setar função alternativa
            LDR     R0, =GPIO_PORTJ_AHB_AFSEL_R     ;Carrega o endereço do AFSEL da porta J
            STR     R1, [R0]                        ;Escreve na porta
			LDR     R0, =GPIO_PORTN_AHB_AFSEL_R     ;Carrega o endereço do AFSEL da porta N
            STR     R1, [R0]                        ;Escreve na porta
; 6. Setar os bits de DEN para habilitar I/O digital
			
			LDR		R0, =GPIO_PORTN_AHB_DEN_R			;Carrega o endereço do DEN
			MOV 	R1, #2_00000001						;Ativa os pinos PN0 como I/O Digital
			STR		R1, [R0]							;Escreve no reg da memória func digital
 
            LDR     R0, =GPIO_PORTJ_AHB_DEN_R			;Carrega o endereço do DEN
			MOV     R1, #2_00000011                     ;Ativa os pinos PJ0 e PJ1 como I/O Digital      
            STR     R1, [R0]                            ;Escreve no registrador da memória funcionalidade digital
			
; 7. Para habilitar resistor de pull-up interno, setar PUR para 1
			LDR     R0, =GPIO_PORTJ_AHB_PUR_R			;Carrega o endereço do PUR para a porta J
			MOV     R1, #2_00000011						;Habilitar funcionalidade digital de resistor de pull-up 
                                                        ;nos bits 0 e 1
            STR     R1, [R0]		
; Interrupções
; 8. Desabilitar a interrupção no reg GPIOIM.
			LDR 	R0, =GPIO_PORTJ_AHB_IM_R 
			MOV 	R1, #2_00
			STR 	R1, [R0]
; 9. Como vamos capturar interrupções durante pressionamento ou liberação das chaves, configurar como borda
			LDR 	R0, =GPIO_PORTJ_AHB_IS_R
			MOV 	R1, #2_00
			STR 	R1, [R0]
; 10. Configurar borda única em ambos os pinos
			LDR 	R0, =GPIO_PORTJ_AHB_IBE_R 
			MOV		R1, #2_00
			STR		R1, [R0]
; 11. Borda de descida para J0 e borda de subida para J1
			LDR 	R0, =GPIO_PORTJ_AHB_IEV_R    
			MOV		R1, #2_10
			STR 	R1, [R0]
; 12. Garantir que a interrupção será atendida, fazer ACK para ambos os pinos
			LDR 	R0, =GPIO_PORTJ_AHB_ICR_R
			MOV		R1, #2_11
			STR 	R1, [R0]
; 13. Ativar as interrupções em ambos os pinos
			LDR 	R0, =GPIO_PORTJ_AHB_IM_R
			STR		R1, [R0]

;Interrupção número 51
; 14. Setar a prioridade no NVIC
		LDR		R0, =NVIC_PRI12_R
		MOV 	R1, #5
		LSL 	R1, R1, #29
		STR 	R1, [R0]
; 15. Habilitar interrupções no NVIC
		LDR		R0, =NVIC_EN1_R           
		MOV 	R1, #1
		LSL		R1,R1,#19
		STR		R1, [R0]
	BX LR

; FUNÇÃO OUTPUT
PortN_Output
	LDR R1, =GPIO_PORTN_AHB_DATA_R
	LDR R2, [R1]
	BIC R2, #2_00000001
	ORR R0, R0, R2
	STR R0, [R1]
	BX LR


; HANDLER DA PORTA J
GPIOPortJ_Handler
		LDR 	R0, =GPIO_PORTJ_AHB_RIS_R
		LDR		R2, [R0]
		LDR 	R0, =GPIO_PORTJ_AHB_ICR_R
		MOV		R1, #2_11		;ACK
		STR 	R1, [R0]
		
		CMP		R2, #2_01 ;COMPARA BIT, SE 01 FOI O BIT0, SE FOR O 10 FOI O BIT1
		ITE		EQ
		MOVEQ	R10, #1
		MOVNE	R10, #0
		BX LR


    ALIGN                           ; garante que o fim da seção está alinhada 
    END                             ; fim do arquivo