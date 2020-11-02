// gpio.c
// Desenvolvido para a placa EK-TM4C1294XL
// Inicializa as portas J e N
// Prof. Guilherme Peron


#include <stdint.h>

#include "tm4c1294ncpdt.h"

#define GPIO_PORTN  (0x1000) //bit 12
#define GPIO_PORTA  (0x0001) //bit 00
#define UART_0			(0X0001) //bit 00
#define TIMER2  		(0x0004) //bit 02

void printaChar(uint8_t*);
void atualizaTimers(uint8_t);
void reiniciaTimer(uint16_t timer);
void Invertepino0(void);

uint16_t atualTimer, proxTimer, auxAtual;
uint8_t aceso = 1;

// -------------------------------------------------------------------------------
// Função GPIO_Init
// Inicializa os ports J e N
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void GPIO_Init(void)
{
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R = (GPIO_PORTA|GPIO_PORTN);
	//1b.   após isso verificar no PRGPIO se a porta está pronta para uso.
  while((SYSCTL_PRGPIO_R & (GPIO_PORTA|GPIO_PORTN) ) != (GPIO_PORTA|GPIO_PORTN) ){};
	
	// 2. Limpar o AMSEL para desabilitar a analógica
	GPIO_PORTA_AHB_AMSEL_R =0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTA_AHB_PCTL_R = 0x11;
	GPIO_PORTN_PCTL_R = 0x00;

	// 4. DIR para 0 se for entrada, 1 se for saída
	
	GPIO_PORTN_DIR_R = 0x01; //BIT0
		
	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa	
	GPIO_PORTA_AHB_AFSEL_R = 0x03;
	GPIO_PORTN_AFSEL_R = 0x00; 
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTA_AHB_DEN_R = 0x03; 		//BIT 0 e BIT 1
	GPIO_PORTN_DEN_R = 0x01; 		   //Bit0

}	

// -------------------------------------------------------------------------------
void UART_Init (void){
	//1a. Habilitar o clock no módulo UART no registrador RCGCUART 
	SYSCTL_RCGCUART_R = UART_0;
	//1b. Esperar até que a respectiva UART esteja pronta para ser acessada no registrador PRUART
	while((SYSCTL_PRUART_R & (UART_0) ) != (UART_0) ){};
	//2. Garantir que a UART esteja desabilitada antes de fazer as alterações (limpar o bit UARTEN) no registrador UARTCTL
	UART0_CTL_R = 0x00;
	//3. Escrever o baud-rate nos registradores UARTIBRD e UARTFBRD 
	//Para um baud rate de 19200bps e um clock de 80MHz.
	UART0_IBRD_R = 260;
	UART0_FBRD_R = 27;
	//4. Configurar o registrador UARTLCRH para o número de bits, paridade, stop bits e fila
	UART0_LCRH_R = 0X70; //WLEN com largura 8 e fila habilitada
	//5. Garantir que a fonte de clock seja o clock do sistema no registrador UARTCC escrevendo 0
	UART0_CC_R = 0x00;
	//6. Habilitar as flags RXE, TXE e UARTEN no registrador UARTCTL
	UART0_CTL_R = UART_CTL_UARTEN + UART_CTL_RXE + UART_CTL_TXE;		
}

void TIMER_Init(void)
{
		//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCTIMER
		SYSCTL_RCGCTIMER_R = TIMER2;
		//1b.   após isso verificar no PRTIMER se a porta está pronta para uso.
		while((SYSCTL_PRTIMER_R & TIMER2 ) != (TIMER2) ){};
		
		//2.Desabilitar o timer2 para fazer as configurações
		TIMER2_CTL_R = 0x00;
		
		//3. Conforme calculamos os valores, colocar o timer2 no modo 16 bits então escrever 0x04 nos bits respectivos do registrador GPTMCFG.
		TIMER2_CFG_R = 0x04;
		
		//4. Como vamos usar o timerA e vamos contar várias vezes, vamos colocá-lo no modo periódico, colocando 2 no campo respectivo do registrador GPTMTAMR
		TIMER2_TAMR_R = 0x02;
			
		//5. Carregar o valor de contagem no registrador timerA no registrador GPTMTAILR
		TIMER2_TAILR_R = 8;
		atualTimer = TIMER2_TAILR_R;
		proxTimer = 799 - TIMER2_TAILR_R;
		auxAtual = 0;
			
		//6. Como temos prescale, deixar o registrador GPTMTAPR com o valor dele.
		TIMER2_TAPR_R = 99;
		
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
		
		//9) Habilitar o bit TAEN no registrador GPTMCTL para começar o timer. A partir deste momento o timer fará a contagem e quando estourar cairá na rotina de tratamento de interrupção.
		TIMER2_CTL_R  = 0X01;
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
// -------------------------------------------------------------------------------
// Função PortA_Reception
uint8_t PortA_Reception(void)
{
	uint8_t c;
	while((UART0_FR_R & 0x10)); //se fila vazia, aguarda
	c = UART0_DR_R;
	return c;
}
// Função PortA_Envio
// Recebe como parâmetro a string e envia para o PC, caractere por caractere
void PortA_Envio(uint8_t valor){
	while((UART0_FR_R  & 0x20)); //se fila cheia, aguarda
	UART0_DR_R = valor;
}

//Rotina de Tratamento de interrupção
void Timer2A_Handler()
{
	TIMER2_ICR_R = 0X01;
	uint16_t aux = atualTimer;
	atualTimer = proxTimer;
	proxTimer = aux;
	TIMER2_TAILR_R = atualTimer;
	Invertepino0();
}
//Atualiza os timers mediante recebimento de PC
void atualizaTimers(uint8_t chave)
{
	switch(chave){
			case '1':			//Brilho do LED a 20% do máximo;
				if(auxAtual==1)
					break;
				reiniciaTimer(160);
				auxAtual=1;
				break;
			case '2':			//Brilho do LED a 40% do máximo;
				if(auxAtual==2)
					break;
				reiniciaTimer(320);
				auxAtual=2;
				break;
			case '3':			//Brilho do LED a 60% do máximo;
				if(auxAtual==3)
					break;
				reiniciaTimer(479);
				auxAtual=3;
				break;
			case '4':			//Brilho do LED a 80% do máximo;
				if(auxAtual==4)
					break;
				reiniciaTimer(639);
				auxAtual=4;
			break;
			case '5':			//Brilho do LED a 99% do máximo;
				if(auxAtual==5)
					break;
				reiniciaTimer(791);
				auxAtual=5;
				break;
			default:		//Brilho do LED a 1% do máximo;
				if(!auxAtual)
					break;
				reiniciaTimer(8);
				auxAtual=0;
			break;}
}
void printString(uint8_t *string)
{
	while(*string)
	{
		PortA_Envio(*(string++));
	}
}
void reiniciaTimer(uint16_t timer)
{
	TIMER2_CTL_R = 0x00;
	TIMER2_TAILR_R = timer;
	atualTimer = timer;
	proxTimer = 799 - atualTimer;
	aceso = 1;
	PortN_Output(0X01);
	TIMER2_CTL_R  = 0X01;
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
