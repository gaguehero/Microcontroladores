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
// Função GPIO_Init
// Inicializa os ports J e N
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void GPIO_Init(void)
{
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R = (GPIO_PORTJ | GPIO_PORTN);
	//1b.   após isso verificar no PRGPIO se a porta está pronta para uso.
  while((SYSCTL_PRGPIO_R & (GPIO_PORTJ | GPIO_PORTN) ) != (GPIO_PORTJ | GPIO_PORTN) ){};
	
	// 2. Limpar o AMSEL para desabilitar a analógica
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTN_PCTL_R = 0x00;

	// 4. DIR para 0 se for entrada, 1 se for saída
	GPIO_PORTJ_AHB_DIR_R = 0x00;
	GPIO_PORTN_DIR_R = 0x03; //BIT0 | BIT1
		
	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa	
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTN_AFSEL_R = 0x00; 
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTJ_AHB_DEN_R = 0x03;   //Bit0 e bit1
	GPIO_PORTN_DEN_R = 0x03; 		   //Bit0 e bit1
	
	// 7. Habilitar resistor de pull-up interno, setar PUR para 1
	GPIO_PORTJ_AHB_PUR_R = 0x03;   //Bit0 e bit1	
	
	//Interrupções
	// 8. Desabilitar a interrupção no reg GPIOM.
	GPIO_PORTJ_AHB_IM_R = 0x00;
	
	//9. Como vamos capturar interrupções durante pressionamento ou liberação das chaves, configurar como borda
	GPIO_PORTJ_AHB_IS_R = 0x00;
	
	//10. Configurar borda única em ambos os pinos
	GPIO_PORTJ_AHB_IBE_R = 0x00;
	
	//11. Borda de descida para J0
	GPIO_PORTJ_AHB_IEV_R  = 0x01;
	
	//12. Garantir que a interrupção será atendida, fazer ACK no J0
	GPIO_PORTJ_AHB_ICR_R = 0x01;
	
	// 13. Ativar as interrupções em ambos no J0
	GPIO_PORTJ_AHB_IM_R = 0x01;
	
	// Interrupção número 51
	// 14. Setar a prioridade no NVIC
	uint32_t aux = 5;
	aux = aux << 29;
	NVIC_PRI12_R = aux;
	
	// 15. Habilitar interrupções no NVIC
	aux = 1;
	aux = aux << 19;
	NVIC_EN1_R = aux;	
}	

void TIMER_Init(void)
{
		//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCTIMER
		SYSCTL_RCGCTIMER_R = TIMER2;
		//1b.   após isso verificar no PRTIMER se a porta está pronta para uso.
		while((SYSCTL_PRTIMER_R & TIMER2 ) != (TIMER2) ){};
		
		//2.Desabilitar o timer2 para fazer as configurações
		TIMER2_CTL_R = 0x00;
		
		//3. Conforme calculamos os valores, colocar o timer2 no modo 32 bits então escrever 0x00 nos bits respectivos do registrador GPTMCFG.
		TIMER2_CFG_R = 0x00;
		
		//4. Como vamos usar o timerA e vamos contar várias vezes, vamos colocá-lo no modo periódico, colocando 2 no campo respectivo do registrador GPTMTAMR
		TIMER2_TAMR_R = 0x02;
			
		//5. Carregar o valor de contagem no registrador timerA no registrador GPTMTAILR
		TIMER2_TAILR_R = 55999999;
			
		//6. Como não temos prescale, deixar o registrador GPTMTAPR zerado.
		TIMER2_TAPR_R = 0x00;
		
		//7. Como vamos utilizar o timerA, setar o bit TnTOCINT no registrador GPTMICR, para garantir que a primeira interrupção seja atendida.
		TIMER2_ICR_R = 0x01;
			
		//8. a) Como vamos utilizar interrupção para estouro do timer, escrever 1 no bit TATOIM do registrador GPTMIMR
		TIMER2_IMR_R = 0x01;
		
		// Interrupção número 23
		//8. b) Setar a prioridade da interrupção do timer respectivo no respectivo registrador NVIC Priority Register.
		uint32_t aux = 4;
		aux = aux << 29;
		NVIC_PRI5_R = aux;
		
		//8. c) Habilitar a interrupção do timer respectivo no respectivo registrador NVIC Interrupt Enable Register
		aux = 1;
		aux = aux << 23;
		NVIC_EN0_R = aux;
		
}
// -------------------------------------------------------------------------------
// Função PortJ_Input
// Lê os valores de entrada do port J
// Parâmetro de entrada: Não tem
// Parâmetro de saída: o valor da leitura do port
uint32_t PortJ_Input(void)
{
	return GPIO_PORTJ_AHB_DATA_R;
}

// -------------------------------------------------------------------------------
// Função PortN_Output
// Escreve os valores no port N
// Parâmetro de entrada: Valor a ser escrito
// Parâmetro de saída: não tem
void PortN_Output(uint32_t valor)
{
    uint32_t temp;
    //vamos zerar somente os bits menos significativos
    //para uma escrita amigável nos bits 0 e 1
    temp = GPIO_PORTN_DATA_R & 0xFC;
    //agora vamos fazer o OR com o valor recebido na função
    temp = temp | valor;
    GPIO_PORTN_DATA_R = temp; 
}


//Rotina de Tratamento de interrupção
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


