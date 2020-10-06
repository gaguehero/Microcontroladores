// gpio.c
// Desenvolvido para a placa EK-TM4C1294XL
// Inicializa as portas J e N
// Prof. Guilherme Peron


#include <stdint.h>

#include "tm4c1294ncpdt.h"

#define GPIO_PORTJ  (0x0100) //bit 8
#define GPIO_PORTF  (0x0020) //bit 6
#define GPIO_PORTN  (0x1000) //bit 12
  
extern uint8_t flag;
// -------------------------------------------------------------------------------
// Fun��o GPIO_Init
// Inicializa os ports J, F e N
// Par�metro de entrada: N�o tem
// Par�metro de sa�da: N�o tem
void GPIO_Init(void)
{
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R = (GPIO_PORTJ | GPIO_PORTN | GPIO_PORTF);
	//1b.   ap�s isso verificar no PRGPIO se a porta est� pronta para uso.
  while((SYSCTL_PRGPIO_R & (GPIO_PORTJ | GPIO_PORTN | GPIO_PORTF) ) != (GPIO_PORTJ | GPIO_PORTN | GPIO_PORTF) ){};
	
	// 2. Limpar o AMSEL para desabilitar a anal�gica
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTF_AHB_AMSEL_R = 0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTF_AHB_PCTL_R = 0x00;
	GPIO_PORTN_PCTL_R = 0x00;
		
	// 4. DIR para 0 se for entrada, 1 se for sa�da
	GPIO_PORTJ_AHB_DIR_R = 0x00;
	GPIO_PORTF_AHB_DIR_R = 0x11; //BIT 0 | BIT 4
	GPIO_PORTN_DIR_R = 0x03; //BIT0 | BIT1

	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem fun��o alternativa	
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTF_AHB_AFSEL_R = 0x00;
	GPIO_PORTN_AFSEL_R = 0x00; 
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTJ_AHB_DEN_R = 0x03;   //Bit0 e bit1
	GPIO_PORTF_AHB_DEN_R = 0x11;	//Bit0 e bit4
	GPIO_PORTN_DEN_R = 0x03; 		 //Bit0 e bit1
	
	// 7. Habilitar resistor de pull-up interno, setar PUR para 1
	GPIO_PORTJ_AHB_PUR_R = 0x03;   //Bit0 e bit1	
	
	//Interrup��es
	// 8. Desabilitar a interrup��o no reg GPIOM.
	GPIO_PORTJ_AHB_IM_R = 0x00;
	
	//9. Como vamos capturar interrup��es durante pressionamento ou libera��o das chaves, configurar como borda
	GPIO_PORTJ_AHB_IS_R = 0x00;
	
	//10. Configurar borda �nica em ambos os pinos
	GPIO_PORTJ_AHB_IBE_R = 0x00;
	
	//11. Borda de descida para J0 e J1
	GPIO_PORTJ_AHB_IEV_R  = 0x03;
	
	//12. Garantir que a interrup��o ser� atendida, fazer ACK para ambos os pinos
	GPIO_PORTJ_AHB_ICR_R = 0x03;
	
	// 13. Ativar as interrup��es em ambos os pinos
	GPIO_PORTJ_AHB_IM_R = 0x03;
	
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
void PortF_Output(uint32_t valor)
{
    uint32_t temp;
    //vamos zerar somente os bits menos significativos
    //para uma escrita amig�vel nos bits 0 e 1
    temp = GPIO_PORTF_AHB_DATA_R & 0xEE;
    //agora vamos fazer o OR com o valor recebido na fun��o
    temp = temp | valor;
    GPIO_PORTF_AHB_DATA_R = temp; 
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
void GPIOPortJ_Handler()
{
		GPIO_PORTJ_AHB_RIS_R = PortJ_Input();
		GPIO_PORTJ_AHB_ICR_R = 0x03;
		flag=1;
}

