// main.c
// Desenvolvido para a placa EK-TM4C1294XL


#include <stdint.h>

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void GPIO_Init(void);
void UART_Init (void);
void TIMER_Init(void);
void PortN_Output(uint32_t leds);
uint8_t PortA_Reception(void);
void printString(uint8_t*);
void atualizaTimers(uint8_t);


int main(void)
{
	PLL_Init();
	SysTick_Init();
	UART_Init();
	GPIO_Init();
	TIMER_Init();
	uint8_t caracter;
	uint8_t c1[13]="\nLED a 20%\r\n";
	uint8_t c2[13]="\nLED a 40%\r\n";
	uint8_t c3[13]="\nLED a 60%\r\n";
	uint8_t c4[13]="\nLED a 80%\r\n";
	uint8_t c5[13]="\nLED a 99%\r\n";
	uint8_t c0[13]="\nLED a 01%\r\n";
	while (1)
	{
    caracter=PortA_Reception();
		switch(caracter){
			case '1':			//Brilho do LED a 20% do máximo;
			atualizaTimers(caracter);
			printString(c1);
			break;
			case '2':			//Brilho do LED a 40% do máximo;
			atualizaTimers(caracter);
			printString(c2);
			break;
			case '3':			//Brilho do LED a 60% do máximo;
			atualizaTimers(caracter);
			printString(c3);
			break;
			case '4':			//Brilho do LED a 80% do máximo;
			atualizaTimers(caracter);
			printString(c4);
			break;
			case '5':			//Brilho do LED a 99% do máximo;
			atualizaTimers(caracter);
			printString(c5);
			break;
			default:		//Brilho do LED a 1% do máximo;
			atualizaTimers(caracter);
			printString(c0);
			break;
		}
		
	}
}

