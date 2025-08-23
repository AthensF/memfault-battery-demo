#include "stm32f4xx.h"
#include "memfault/components.h"
#include <stdio.h>
#include <string.h>

// Battery simulation parameters (FAST DEMO MODE)
#define BATTERY_MAX_VOLTAGE_MV    4200  // 4.2V fully charged
#define BATTERY_MIN_VOLTAGE_MV    3000  // 3.0V empty
#define BATTERY_DRAIN_RATE_MV     50    // 50mV per second (25x faster!)
#define BATTERY_LOW_THRESHOLD     20    // 20% warning
#define BATTERY_CRITICAL_THRESHOLD 10   // 10% critical
#define BATTERY_EMPTY_THRESHOLD   0     // 0% empty

// Global variables
static volatile uint32_t g_tick_count = 0;
static uint32_t g_battery_voltage_mv = BATTERY_MAX_VOLTAGE_MV;
static bool g_low_battery_warned = false;
static bool g_critical_battery_warned = false;

// Simple delay function
void delay_ms(uint32_t ms) {
    uint32_t start = g_tick_count;
    while ((g_tick_count - start) < ms) {
        __WFI(); // Wait for interrupt
    }
}

// SysTick interrupt handler
void SysTick_Handler(void) {
    g_tick_count++;
    
    // Simulate battery drain every second (1000ms)
    if (g_tick_count % 1000 == 0) {
        if (g_battery_voltage_mv > BATTERY_MIN_VOLTAGE_MV) {
            g_battery_voltage_mv -= BATTERY_DRAIN_RATE_MV;
        }
    }
}

// Calculate battery percentage from voltage
uint8_t get_battery_percentage(uint32_t voltage_mv) {
    if (voltage_mv >= BATTERY_MAX_VOLTAGE_MV) return 100;
    if (voltage_mv <= BATTERY_MIN_VOLTAGE_MV) return 0;
    
    return (uint8_t)(((voltage_mv - BATTERY_MIN_VOLTAGE_MV) * 100) / 
                     (BATTERY_MAX_VOLTAGE_MV - BATTERY_MIN_VOLTAGE_MV));
}

// Simple UART output (for debugging/logging)
void uart_send_string(const char* str) {
    // In real hardware, this would send to UART
    // For now, just a placeholder that Memfault can capture
    memfault_platform_log(kMemfaultPlatformLogLevel_Info, "%s", str);
}

// Check battery status and trigger events
void check_battery_status(void) {
    uint8_t battery_percent = get_battery_percentage(g_battery_voltage_mv);
    char buffer[100];
    
    // Log current battery status
    snprintf(buffer, sizeof(buffer), "Battery: %lumV (%u%%)", 
             g_battery_voltage_mv, battery_percent);
    uart_send_string(buffer);
    
    // Update Memfault metrics
    memfault_metrics_heartbeat_set_unsigned(MEMFAULT_METRICS_KEY(battery_voltage_mv), g_battery_voltage_mv);
    memfault_metrics_heartbeat_set_unsigned(MEMFAULT_METRICS_KEY(battery_percent), battery_percent);
    
    // Trigger events at critical thresholds
    if (battery_percent <= BATTERY_EMPTY_THRESHOLD) {
        MEMFAULT_TRACE_EVENT_WITH_LOG(BatteryEmpty, "Battery empty - shutting down!");
        uart_send_string("CRITICAL: Battery empty!");
        // In real system, would trigger shutdown
        while(1) { __WFI(); } // Simulate shutdown
    }
    else if (battery_percent <= BATTERY_CRITICAL_THRESHOLD && !g_critical_battery_warned) {
        MEMFAULT_TRACE_EVENT_WITH_LOG(BatteryCritical, "Battery critically low!");
        uart_send_string("WARNING: Battery critically low!");
        g_critical_battery_warned = true;
    }
    else if (battery_percent <= BATTERY_LOW_THRESHOLD && !g_low_battery_warned) {
        MEMFAULT_TRACE_EVENT_WITH_LOG(BatteryLow, "Battery low warning");
        uart_send_string("WARNING: Battery low!");
        g_low_battery_warned = true;
    }
}

int main(void) {
    // Initialize system
    SystemInit();
    
    // Configure SysTick for 1ms interrupts
    SysTick_Config(SystemCoreClock / 1000);
    
    // Initialize Memfault
    memfault_platform_boot();
    
    uart_send_string("Battery simulation started!");
    uart_send_string("Starting with full battery (4.2V, 100%)");
    
    while (1) {
        // Check battery status every 2 seconds (faster for demo)
        check_battery_status();
        
        // Send heartbeat to Memfault periodically
        memfault_metrics_heartbeat_debug_trigger();
        
        delay_ms(2000); // 2 second intervals
    }
    
    return 0;
}