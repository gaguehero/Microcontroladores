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


; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT GPIO_Init            ; Permite chamar GPIO_Init de outro arquivo
		EXPORT PortN_Output			; Permite chamar PortN_Output de outro arquivo
		EXPORT PortJ_Input          ; Permite chamar PortJ_Input de outro arquivo
									

;--------------------------------------------------------------------------------
; Função GPIO_Init
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
GPIO_Init
;=====================
; ****************************************
; Escrever função de inicialização dos GPIO
; Inicializar as portas J e N
; ****************************************
			LDR R0, =SYSCTL_RCGCGPIO_R ;CARREGA ENDEREÇO DO RCGCGPIO
			MOV R1, #GPIO_PORTN ;SETA PORTA N
			ORR R1, #GPIO_PORTJ ;SETA PORTA J
			STR R1, [R0] ;GUARDA OS RESULTADOS DE RCGCGPIO EM R1
	
			LDR R0, =SYSCTL_PRGPIO_R ;CARREGA ENDEREÇO DO PRGPIO PARA ESPERAR OS GPIO ESTAREM PRONTOS
EsperaGPIO	LDR R1, [R0] 
			MOV R2, #GPIO_PORTN
			ORR R2, #GPIO_PORTJ
			TST R1, R2 ;COMPARA COM UM AND R1 E R2
			BEQ EsperaGPIO ;SE FLAG Z=1, LOOP.
;LIMPA AMSEL, DESABILITANDO O I/O ANALÓGICO
			MOV R1, #0x00 ;0 DESABILITA A FUNÇÃO
			LDR R0, =GPIO_PORTN_AHB_AMSEL_R ;CARREGA EM R0 O ENDEREÇO DA AMSEL DA PORTA N
			STR R1, [R0] ;GUARDA O 0, DESABILITANDO O ANALÓGICO
			LDR R0, =GPIO_PORTJ_AHB_AMSEL_R ;MESMA COISA, PORÉM PORTA J
			STR R1, [R0]
;LIMPA PCTL PARA SELECIONAR O GPIO
			LDR R0, =GPIO_PORTN_AHB_PCTL_R ;CARREGA EM R0 O ENDEREÇO DA PCTL DA PORTA N
			STR R1, [R0] ;SELECIONA O MODO GPIO DA PORTA N
			LDR R0, =GPIO_PORTJ_AHB_PCTL_R  ;MESMA COISA, PORÉM PORTA J
			STR R1, [R0]
;DEFINE SE ENTRADA (ZERO) OU SAÍDA (UM)
			LDR R0, =GPIO_PORTN_AHB_DIR_R ;CARREGA O R0 COM O ENDEREÇO DO DIR PARA A PORTA N
			MOV R1, #2_00000010 ;PORTA N0 PARA O LED
			STR R1, [R0] ;GUARDA NO REG
			LDR R0, =GPIO_PORTJ_AHB_DIR_R ;CARREGA O R0 COM O ENDEREÇO DO DIR PARA A PORTA J
			MOV R1, #0x00 ;DEFININDO COMO SAÍDA
			STR R1, [R0] ;GUARDA NO REG
;NÃO SERÁ UTILIZADO NENHUMA FUNC ALTERNATIVA, PORTANTO AFSEL DEVE SER SETADO PARA 0
			MOV R1, #0x00 
			LDR R0, =GPIO_PORTN_AHB_AFSEL_R ;CARREGA O R0 COM O ENDEREÇO DO AFSEL PARA A PORTA N
			STR R1, [R0] ;GUARDA NO REG
			LDR R0, =GPIO_PORTJ_AHB_AFSEL_R ;MESMA COISA, PORÉM PORTA J
			STR R1, [R0]
;SETA OS BITS DE DEN PARA HABILITAR I/O DIGITAL
			LDR R0, =GPIO_PORTN_AHB_DEN_R ;CARREGA O R0 COM O ENDEREÇO DO DEN PARA A PORTA N
			MOV R1, #2_00000010 ;ATIVA O PINO N1 
			STR R1, [R0] ;GUARDA NO REG
			MOV R1, #2_00000001 ;ATIVA O PINO J0
			LDR R0, =GPIO_PORTJ_AHB_DEN_R ;CARREGA O R0 COM O ENDEREÇO DO DEN PARA A PORTA J
			STR R1, [R0] ;GUARDA NO REG
;RESISTOR DE PULL-UP INTERNO, PUR
			LDR R0, =GPIO_PORTJ_AHB_PUR_R ;CARREGA R0 COM O ENDEREÇO DO PUR PARA A PORTA J
			MOV R1, #2_00000001 ;SÓ UMA PORTA SERÁ UTILIZADA, PORTANTO BASTA ATIVAR O PULL-UP EM UM PINO
			STR R1, [R0] ;GUARDA NO REG
			BX LR

; -------------------------------------------------------------------------------
; Função PortN_Output
; Parâmetro de entrada: R0 --> SE O BIT0 ESTÁ LIGADO OU DESLIGADO
; Parâmetro de saída: Não tem
PortN_Output
; ****************************************
; Escrever função que acende ou apaga o LED
; ****************************************
	LDR R1, =GPIO_PORTN_AHB_DATA_R ;CARREGA O VALOR DO OFFSET DO DATA REGISTER
	LDR R2, [R1]
	BIC R2, #2_00000010 ;MASCARA PARA LEITURA APENAS DO ÚLTIMO BIT R2=R2&11111101
	ORR R0, R0, R2 ;OR ENTRE O LIDO PELA PORTA E O PARÂMETRO DE ENTRADA
	STR R0, [R1] ;ESCREVE NA PORTA N O BARRAMENTO DE DADOS DO PINO N0
	BX LR
; -------------------------------------------------------------------------------
; Função PortJ_Input
; Parâmetro de entrada: Não tem
; Parâmetro de saída: R0 --> o valor da leitura
PortJ_Input
; ****************************************
; Escrever função que lê a chave e retorna 
; um registrador se está ativada ou não
; ****************************************
	LDR	R1, =GPIO_PORTJ_AHB_DATA_R ;CARREGA O VALOR DO OFFSET DO DATA REGISTER
	LDR R0, [R1] ;LÊ NO BARRAMENTO O PINO
	BX LR



    ALIGN                           ; garante que o fim da seção está alinhada 
    END                             ; fim do arquivo