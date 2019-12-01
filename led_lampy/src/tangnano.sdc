create_clock -name CLOCK_24M -period 41.666 -waveform {0 20.833} [get_ports {XTAL_IN}]
create_clock -name video_clk -period 111.109 [get_pins {u_pll/pll_inst/CLKOUT}]

#create_clock -period 10.000 [get_ports {PSRAM_SCK}]
#set_output_delay -clock PSRAM_SCK 4 -max -add_delay [get_ports {PSRAM_CE_n}]
#set_output_delay -clock PSRAM_SCK -1.5 -min -add_delay [get_ports {PSRAM_CE_n}]
#set_output_delay -clock PSRAM_SCK 4 -max -add_delay [get_ports {PSRAM_SIO[*]}]
#set_output_delay -clock PSRAM_SCK -1.5 -min -add_delay [get_ports {PSRAM_SIO[*]}]
#set_input_delay -clock PSRAM_SCK 7.5 -max -add_delay [get_ports {PSRAM_SIO[*]}]
#set_input_delay -clock PSRAM_SCK 2.5 -min -add_delay [get_ports {PSRAM_SIO[*]}]


set_output_delay -clock video_clk -max 5 [get_ports {LCD_DCLK LCD_HSYNC_n LCD_VSYNC_n LCD_DE LCD_R[4] LCD_R[3] LCD_R[2] LCD_R[1] LCD_R[0] LCD_G[5] LCD_G[4] LCD_G[3] LCD_G[2] LCD_G[1] LCD_G[0] LCD_B[4] LCD_B[3] LCD_B[2] LCD_B[1] LCD_B[0]}]
