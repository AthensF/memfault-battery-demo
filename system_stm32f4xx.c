#include "stm32f4xx.h"

uint32_t SystemCoreClock = 16000000;

const uint8_t AHBPrescTable[16] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 6, 7, 8, 9};

void SystemInit(void)
{
    /* Reset the RCC clock configuration to the default reset state */
    RCC->CR |= (uint32_t)0x00000001;         /* Set HSION bit */
    RCC->CFGR = 0x00000000;                  /* Reset CFGR register */
    RCC->CR &= (uint32_t)0xFEF6FFFF;         /* Reset HSEON, CSSON and PLLON bits */
    RCC->PLLCFGR = 0x24003010;               /* Reset PLLCFGR register */
    RCC->CR &= (uint32_t)0xFFFBFFFF;         /* Reset HSEBYP bit */
    RCC->CIR = 0x00000000;                   /* Disable all interrupts */

    /* Configure the Vector Table location add offset address */
#ifdef VECT_TAB_SRAM
    SCB->VTOR = SRAM_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal SRAM */
#else
    SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal FLASH */
#endif
}

void SystemCoreClockUpdate(void)
{
    uint32_t tmp = 0, pllvco = 0, pllp = 2, pllsource = 0, pllm = 2;
    
    /* Get SYSCLK source */
    tmp = RCC->CFGR & RCC_CFGR_SWS;
    
    switch (tmp)
    {
        case 0x00:  /* HSI used as system clock source */
            SystemCoreClock = HSI_VALUE;
            break;
        case 0x04:  /* HSE used as system clock source */
            SystemCoreClock = HSE_VALUE;
            break;
        case 0x08:  /* PLL used as system clock source */
            pllsource = (RCC->PLLCFGR & RCC_PLLCFGR_PLLSRC) >> 22;
            pllm = RCC->PLLCFGR & RCC_PLLCFGR_PLLM;
            
            if (pllsource != 0)
            {
                pllvco = (HSE_VALUE / pllm) * ((RCC->PLLCFGR & RCC_PLLCFGR_PLLN) >> 6);
            }
            else
            {
                pllvco = (HSI_VALUE / pllm) * ((RCC->PLLCFGR & RCC_PLLCFGR_PLLN) >> 6);      
            }
            
            pllp = (((RCC->PLLCFGR & RCC_PLLCFGR_PLLP) >>16) + 1 ) *2;
            SystemCoreClock = pllvco/pllp;
            break;
        default:
            SystemCoreClock = HSI_VALUE;
            break;
    }
    
    /* Compute HCLK frequency */
    tmp = AHBPrescTable[((RCC->CFGR & RCC_CFGR_HPRE) >> 4)];
    SystemCoreClock >>= tmp;
}

uint32_t SysTick_Config(uint32_t ticks) {
  if ((ticks - 1UL) > 0xFFFFFFUL) {
    return (1UL);                                                   /* Reload value impossible */
  }

  SysTick->LOAD  = (uint32_t)(ticks - 1UL);                         /* set reload register */
  SysTick->VAL   = 0UL;                                              /* Load the SysTick Counter Value */
  SysTick->CTRL  = (1UL << 2U) |                                    /* Enable SysTick exception request */
                   (1UL << 1U) |                                    /* Use processor clock */
                   (1UL << 0U);                                     /* Enable SysTick Timer */
  return (0UL);                                                     /* Function successful */
}