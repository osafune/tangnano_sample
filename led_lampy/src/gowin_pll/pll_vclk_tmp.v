//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.2.01Beta
//Part Number: GW1N-LV1QN48C6/I5
//Created Time: Fri Nov 08 20:08:43 2019

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    pll_vclk your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
