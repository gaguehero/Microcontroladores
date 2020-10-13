// gpio.c
// Desenvolvido para a placa EK-TM4C1294XL
// Inicializa as portas J e N
// Prof. Guilherme Peron


#include <stdint.h>

#include "tm4c1294ncpdt.h"

  
#define GPIO_PORTJ  (0x0100) //bit 8
#define GPIO_PORTN  (0x1000) //bit 12
#define TIMER2  (0x0004) //bit 2

void Invertepino0(void);
uint8_t ativaTimer = 0;
// -------------------------------------------------------------------------------
// Fun��o GPIO_Init
// Inicializa os ports J e N
// Par�metro de entrada: N�o tem
// Par�metro de sa�da: N�o tem
void GPIO_Init(void)
{
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R = (GPIO_PORTJ | GPIO_PORTN);
	//1b.   ap�s isso verificar no PRGPIO se a porta est� pronta para uso.
  while((SYSCTL_PRGPIO_R & (GPIO_PORTJ | GPIO_PORTN) ) != (GPIO_PORTJ | GPIO_PORTN) ){};
	
	// 2. Limpar o AMSEL para desabilitar a anal�gica
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTN_PCTL_R = 0x00;

	// 4. DIR para 0 se for entrada, 1 se for sa�da
	GPIO_PORTJ_AHB_DIR_R = 0x00;
	GPIO_PORTN_DIR_R = 0x03; //BIT0 | BIT1
		
	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem fun��o alternativa	
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTN_AFSEL_R = 0x00; 
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTJ_AHB_DEN_R = 0x03;   //Bit0 e bit1
	GPIO_PORTN_DEN_R = 0x03; 		   //Bit0 e bit1
	
	// 7. Habilitar resistor de pull-up interno, setar PUR para 1
	GPIO_PORTJ_AHB_PUR_R = 0x03;   //Bit0 e bit1	
	
	//Interrup��es
	// 8. Desabilitar a interrup��o no reg GPIOM.
	GPIO_PORTJ_AHB_IM_R = 0x00;
	
	//9. Como vamos capturar interrup��es durante pressionamento ou libera��o das chaves, configurar como borda
	GPIO_PORTJ_AHB_IS_R = 0x00;
	
	//10. Configurar borda �nica em ambos os pinos
	GPIO_PORTJ_AHB_IBE_R = 0x00;
	
	//11. Borda de descida para J0
	GPIO_PORTJ_AHB_IEV_R  = 0x01;
	
	//12. Garantir que a interrup��o ser� atendida, fazer ACK no J0
	GPIO_PORTJ_AHB_ICR_R = 0x01;
	
	// 13. Ativar as interrup��es em ambos no J0
	GPIO_PORTJ_AHB_IM_R = 0x01;
	
	// Interrup��o n�mero 51
	// 14. Setar a prioridade no NVIC
	uint32_t aux = 5;
	aux = aux << 29;
	NVIC_PRI12_R = aux;
	
	// 15. Habilitar interrup��es no NVIC
	aux = 1;
	aux = aux << 19;
	NVIC_EN1_R = aux;	
}	

void TIMER_Init(void)
{
		//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCTIMER
		SYSCTL_RCGCTIMER_R = TIMER2;
		//1b.   ap�s isso verificar no PRTIMER se a porta est� pronta para uso.
		while((SYSCTL_PRTIMER_R & TIMER2 ) != (TIMER2) ){};
		
		//2.Desabilitar o timer2 para fazer as configura��es
		TIMER2_CTL_R = 0x00;
		
		//3. Conforme calculamos os valores, colocar o timer2 no modo 32 bits ent�o escrever 0x00 nos bits respectivos do registrador GPTMCFG.
		TIMER2_CFG_R = 0x00;
		
		//4. Como vamos usar o timerA e vamos contar v�rias vezes, vamos coloc�-lo no modo peri�dico, colocando 2 no campo respectivo do registrador GPTMTAMR
		TIMER2_TAMR_R = 0x02;
			
		//5. Carregar o valor de contagem no registrador timerA no registrador GPTMTAILR
		TIMER2_TAILR_R = 55999999;
			
		//6. Como n�o temos prescale, deixar o registrador GPTMTAPR zerado.
		TIMER2_TAPR_R = 0x00;
		
		//7. Como vamos utilizar o timerA, setar o bit TnTOCINT no registrador GPTMICR, para garantir que a primeira interrup��o seja atendida.
		TIMER2_ICR_R = 0x01;
			
		//8. a) Como vamos utilizar interrup��o para estouro do timer, escrever 1 no bit TATOIM do registrador GPTMIMR
		TIMER2_IMR_R = 0x01;
		
		// Interrup��o n�mero 23
		//8. b) Setar a prioridade da interrup��o do timer respectivo no respectivo registrador NVIC Priority Register.
		uint32_t aux = 4;
		aux = aux << 29;
		NVIC_PRI5_R = aux;
		
		//8. c) Habilitar a interrup��o do timer respectivo no respectivo registrador NVIC Interrupt Enable Register
		aux = 1;
		aux = aux << 23;
		NVIC_EN0_R = aux;
		
}
// -------------------------------------------------------------------------------
// Fun��o PortJ_Input
// L� os valores de entrada do port J
// Par�metro de entrada: N�o tem
// Par�metro de sa�da: o valor da leitura do port
uint32_t PortJ_Input(void)
{
	return GPIO_PORTJ_AHB_DATA_R;
}

// -------------------------------------------------------------------------------
// Fun��o PortN_Output
// Escreve os valores no port N
// Par�metro de entrada: Valor a ser escrito
// Par�metro de sa�da: n�o tem
void PortN_Output(uint32_t valor)
{
    uint32_t temp;
    //vamos zerar somente os bits menos significativos
    //para uma escrita amig�vel nos bits 0 e 1
    temp = GPIO_PORTN_DATA_R & 0xFC;
    //agora vamos fazer o OR com o valor recebido na fun��o
    temp = temp | valor;
    GPIO_PORTN_DATA_R = temp; 
}


//Rotina de Tratamento de interrup��o
void Timer2A_Handler()
{
	TIMER2_ICR_R = 0X01;
	Invertepino0();
}
void GPIOPortJ_Handler()
{
		GPIO_PORTJ_AHB_RIS_R = PortJ_Input();
		GPIO_PORTJ_AHB_ICR_R = 0x01;
		if (ativaTimer)
		{
			TIMER2_CTL_R  = 0X00;
			ativaTimer=0;
		}
		else
		{
			TIMER2_CTL_R  = 0X01;
			ativaTimer=1;
		}
}


