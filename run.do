vlib work
vmap work work

vlog +acc +sv spi_wb_x1_top.v tb_spi_wb_x1_top.v 

vsim work.tb_spi_wb_x1_top

add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_spi_slave/*
add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_ctrl/*
add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_wb_master/*

run -all
