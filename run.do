vlib work
vmap work work

vlog +acc +sv spi_wb_x1_top.v tb_spi_wb_x1_top.v 

vsim work.tb_spi_wb_x1_top

add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_spi_slave/*
add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_ctrl/*
add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_wb_master/*
add wave -position insertpoint /tb_spi_wb_x1_top/dut/u_spi_slave/cmd_shift
add wave -position insertpoint /tb_spi_wb_x1_top/dut/u_spi_slave/rx_shift
add wave -position insertpoint /tb_spi_wb_x1_top/dut/u_spi_slave/tx_shift
add wave -position insertpoint /tb_spi_wb_x1_top/dut/u_spi_slave/bit_cnt
add wave -position insertpoint /tb_spi_wb_x1_top/dut/u_spi_slave/cmd_type
add wave -position insertpoint /tb_spi_wb_x1_top/dut/u_spi_slave/tx_loaded

run -all