// main.c
// Desenvolvido para a placa EK-TM4C1294XL


#include <stdint.h>

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void GPIO_Init(void);
void GPIOPortJ_Handler(void);
uint32_t PortJ_Input(void);
void PortN_Output(uint32_t leds);
void PortF_Output(uint32_t leds);
void Pisca_leds(void);

typedef enum estSemaforo
{
	Est1,
	Est2,
	Est3,
	Est4,
	Est5,
	Est6
} estadosSemaforo;
estadosSemaforo estados = Est1;
uint8_t flag=0;

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	while (1)
	{
      switch (estados){
				case Est1:
					if(flag){
						Pisca_leds();				//subrotina de piscar o led 
						flag=0;}						//limpa a flag
					else{
						PortN_Output(0x03);    //Vermelho Led 1 e Led 2 acesos
						PortF_Output(0x11);		  //Vermelho Led 3 e Led 4 acesos
						SysTick_Wait1ms(1000);}  //aguarda 1 segundo
					estados= Est2;				 //próximo estado
				break;
				case Est2:
					PortN_Output(0x03);		 //Vermelho Led 1 e Led 2 acesos
					PortF_Output(0x10);		 //Verde  Led 3 aceso e 4 apagado
					SysTick_Wait1ms(6000); //aguarda 6 segundo
					estados= Est3;				 //próximo estado
				break;					
				case Est3:
					PortN_Output(0x03);		 //Vermelho Led 1 e Led 2 acesos
					PortF_Output(0x01);		 //Amarelo Led 3 apagado e 4 aceso	
					SysTick_Wait1ms(2000); //aguarda 2 segundo
					estados= Est4;				 //próximo estado
				break;										
				case Est4:
					PortN_Output(0x03);		 //Vermelho Led 1 e Led 2 acesos
					PortF_Output(0x11);		 //Vermelho Led 3 e Led 4 acesos
					SysTick_Wait1ms(1000); //aguarda 1 segundo
					estados= Est5;				 //próximo estado
				break;					
				case Est5:
					PortN_Output(0x02);			//Verde Led 1 aceso e Led 2 apagado
					PortF_Output(0x11);			//Vermelho Led 3 e Led 4 acesos
					SysTick_Wait1ms(6000);  //aguarda 6 segundo
					estados= Est6;				  //próximo estado
				break;
				case Est6:
					PortN_Output(0x01);			//Amarelo Led 1 apagado e Led 2 aceso
					PortF_Output(0x11);			//Vermelho Led 3 e Led 4 acesos
					SysTick_Wait1ms(2000);  //aguarda 2 segundo
					estados= Est1;				  //próximo estado
				break;}
	}
}

void Pisca_leds(void)
{
	uint16_t i;
	for(i=0;i<10;i++){
	PortN_Output(0x2);
	PortF_Output(0x01);
	SysTick_Wait1ms(250);
	PortN_Output(0x1);
	PortF_Output(0x10);
	SysTick_Wait1ms(250);}
}

