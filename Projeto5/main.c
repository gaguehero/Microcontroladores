// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Verifica o estado das chaves USR_SW1 e USR_SW2, acende os LEDs 1 e 2 caso estejam pressionadas independentemente
// Caso as duas chaves estejam pressionadas ao mesmo tempo pisca os LEDs alternadamente a cada 500ms.
// Prof. Guilherme Peron

#include <stdint.h>

void PLL_Init(void);
void TIMER_Init(void);
void GPIO_Init(void);
void PortN_Output(uint32_t valor);
uint32_t PortJ_Input(void);
void GPIOPortJ_Handler(void);

uint8_t aceso = 0;

int main(void)
{
	PLL_Init();
	GPIO_Init();
	TIMER_Init();
	while (1){};
}

void Invertepino0(void){
	if (aceso)
	{
		PortN_Output(0x00); //apaga LED
		aceso = 0;
	}
	else
	{
		PortN_Output(0x01); //acende LED
		aceso = 1;
	}
}
