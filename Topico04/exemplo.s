; Exemplo.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 12/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a função Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma função externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; função <func>

; -------------------------------------------------------------------------------
; Função main()
Start  
; Comece o código aqui <======================================================
; 1)
;	MOV R0, #65
;	MOV R1, #0x1B001B00
;	MOV R2, #5678
;	MOVT R2, #1234
;	LDR R3, =0x20000040
;	STR R0, [R3],#4
;	STR R1, [R3]
;	STR R2, [R3,#4]
;	LDR R4, =0xF0001
;	STR R4, [R3, #8]!
;	MOV R0, #0xCD
;	STRB R0, [R3, #-6]!
;	LDR R7, [R3, #-6]
;	LDR R8, [R3, #2]
;	NOP

; 2)
;	MOV R0, #0xF0
;	MOV R1, #2_01010101
;	ANDS R0, R1
;	MOV R1, #2_11001100
;	MOV R2, #2_00110011
;	ANDS R1, R2
;	MOV R2, #2_10000000
;	MOV R3, #2_00110111
;	ORRS R2, R3
;	MOV R3, #0xABCD
;	MOVT R3, #0xABCD
;	MOV R4, #0xFFFF
;	BICS R3, R4
;	NOP
	
; 3)
;	MOV R0, #701
;	LSRS R0, #5
;	MOV R1, #32067
;	NEG R1, R1
;	LSRS R1, #4
;	MOV R2, #701
;	ASRS R2, #3
;	MOV R3, #32067
;	NEG R3, R3
;	ASRS R3, #4
;	MOV R4, #255
;	LSLS R4, #8
;	MOV R5, #58982
;	NEG R5, R5
;	LSLS R5, #18
;	LDR R6, =0xFABC1234
;	ROR R6, #10
;	MOV R7, #0x4321
;	RRX R7, R7
;	RRX R7, R7
;	NOP

; 4)
;	MOV R0, #101
;	ADDS R0, #253
;	LDR R1, =40543
;	ADD R1, #1500
;	MOV R2, #340
;	SUBS R2, #123
;	MOV R3, #1000
;	SUBS R3, #2000
;	MOV R4, #54378
;	MOV R5, #4
;	MUL R4, R5
;	LDR R5, =11223344
;	LDR R6, =44332211
;	UMULL R6, R5, R5, R6
;	LDR R7, =0xFFFF7560
;	LDR R8, =0xFFFF7560
;	MOV R9, #1000
;	UDIV R7, R9
;	SDIV R8, R9
;	NOP
;	
; 5)
;	MOV R0, #10
;	CMP R0, #9
;	ITTE CS
;		MOVCS R1, #50
;		ADDCS R2, R1, #32
;		MOVCC R3, #75
;	CMP R0, #11
;	ITTE CS
;		MOVCS R1, #50
;		ADDCS R2, R1, #32
;		MOVCC R3, #75
;	NOP
;
; 6)
;	MOV R0, #10
;	LDR R1, =0xFF11CC22
;	MOV R2, #1234
;	MOV R3, #0x300
;	PUSH {R0}
;	PUSH {R1,R2,R3}
;	MOV R1, #60
;	MOV R2, #0x1234
;	POP {R1}
;	POP {R2}
;	POP {R3}
;	POP {R0}
;	NOP
;
; 7)
;	MOV R0, #10
;loop
;	ADD R0, #5 
;	CMP R0, #50
;	BLEQ cinquenta
;	NOP
;	CMP R0, #50
;	BEQ final
;	B loop
;cinquenta
;	MOV R1, R0
;	CMP R1, #50
;	ITE CC
;		ADDCC R1, #1
;		NEGCS R1, R1
;	BX LR
;final
;	NOP
	MOV R0, #0
Contador
	CMP R0, #15
	BIC R1, R0, #2_11111110
	BIC R2, R0, #2_11111101
	BIC R3, R0, #2_11111011
	AND R4, R0, #2_1000
	ITE NE
	ADDNE R0, #1
	MOVEQ R0, #0
	B Contador
	NOP
    ALIGN                           ; garante que o fim da seção está alinhada 
    END                             ; fim do arquivo
