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
// Função GPIO_Init
// Inicializa os ports J, F e N
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void GPIO_Init(void)
{
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R = (GPIO_PORTJ | GPIO_PORTN | GPIO_PORTF);
	//1b.   após isso verificar no PRGPIO se a porta está pronta para uso.
  while((SYSCTL_PRGPIO_R & (GPIO_PORTJ | GPIO_PORTN | GPIO_PORTF) ) != (GPIO_PORTJ | GPIO_PORTN | GPIO_PORTF) ){};
	
	// 2. Limpar o AMSEL para desabilitar a analógica
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTF_AHB_AMSEL_R = 0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTF_AHB_PCTL_R = 0x00;
	GPIO_PORTN_PCTL_R = 0x00;
		
	// 4. DIR para 0 se for entrada, 1 se for saída
	GPIO_PORTJ_AHB_DIR_R = 0x00;
	GPIO_PORTF_AHB_DIR_R = 0x11; //BIT 0 | BIT 4
	GPIO_PORTN_DIR_R = 0x03; //BIT0 | BIT1

	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa	
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTF_AHB_AFSEL_R = 0x00;
	GPIO_PORTN_AFSEL_R = 0x00; 
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTJ_AHB_DEN_R = 0x03;   //Bit0 e bit1
	GPIO_PORTF_AHB_DEN_R = 0x11;	//Bit0 e bit4
	GPIO_PORTN_DEN_R = 0x03; 		 //Bit0 e bit1
	
	// 7. Habilitar resistor de pull-up interno, setar PUR para 1
	GPIO_PORTJ_AHB_PUR_R = 0x03;   //Bit0 e bit1	
	
	//Interrupções
	// 8. Desabilitar a interrupção no reg GPIOM.
	GPIO_PORTJ_AHB_IM_R = 0x00;
	
	//9. Como vamos capturar interrupções durante pressionamento ou liberação das chaves, configurar como borda
	GPIO_PORTJ_AHB_IS_R = 0x00;
	
	//10. Configurar borda única em ambos os pinos
	GPIO_PORTJ_AHB_IBE_R = 0x00;
	
	//11. Borda de descida para J0 e J1
	GPIO_PORTJ_AHB_IEV_R  = 0x03;
	
	//12. Garantir que a interrupção será atendida, fazer ACK para ambos os pinos
	GPIO_PORTJ_AHB_ICR_R = 0x03;
	
	// 13. Ativar as interrupções em ambos os pinos
	GPIO_PORTJ_AHB_IM_R = 0x03;
	
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
void PortF_Output(uint32_t valor)
{
    uint32_t temp;
    //vamos zerar somente os bits menos significativos
    //para uma escrita amigável nos bits 0 e 1
    temp = GPIO_PORTF_AHB_DATA_R & 0xEE;
    //agora vamos fazer o OR com o valor recebido na função
    temp = temp | valor;
    GPIO_PORTF_AHB_DATA_R = temp; 
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
void GPIOPortJ_Handler()
{
		GPIO_PORTJ_AHB_RIS_R = PortJ_Input();
		GPIO_PORTJ_AHB_ICR_R = 0x03;
		flag=1;
}

