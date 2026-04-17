`timescale 1ns/1ps

module tb_spi_wb_x1_top;

    // ------------------------------------------------------------------------
    // clocks / reset
    // ------------------------------------------------------------------------
    reg clk;         // WB clock = 50 MHz
    reg user_clk;
    reg rst;
    reg user_rst;

    // SPI master pins
    reg  spi_sclk;
    reg  spi_cs_n;
    reg  spi_mosi;
    wire spi_miso;

    // passthrough pins for existing slave
    reg  ScanInCC;
    reg  ScanInDL;
    reg  ScanInDR;
    reg  TM;
    wire ScanOutCC;

    reg  Iref;
    reg  Vcc_read;
    reg  Vcomp;
    reg  Bias_comp2;
    reg  Vcc_wl_read;
    reg  Vcc_wl_set;
    reg  Vbias;
    reg  Vcc_wl_reset;
    reg  Vcc_set;
    reg  dc_bias;

    // ------------------------------------------------------------------------
    // constants
    // ------------------------------------------------------------------------
    localparam [7:0]  SPI_CMD_WRITE = 8'h60;
    localparam [7:0]  SPI_CMD_READ  = 8'h40;

    localparam [31:0] WRITE_DATA_1  = 32'hC210_0093;
    localparam [31:0] WRITE_DATA_2  = 32'h4210_0000;
    localparam [31:0] DUMMY_DATA    = 32'h0000_0000;

    reg [39:0] rx_frame_1;
    reg [39:0] rx_frame_2;
    reg [39:0] rx_frame_3;

    // ------------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------------
    spi_wb_x1_top dut (
        .clk         (clk),
        .rst         (rst),
        .user_clk    (user_clk),
        .user_rst    (user_rst),

        .spi_sclk    (spi_sclk),
        .spi_cs_n    (spi_cs_n),
        .spi_mosi    (spi_mosi),
        .spi_miso    (spi_miso),

        .ScanInCC    (ScanInCC),
        .ScanInDL    (ScanInDL),
        .ScanInDR    (ScanInDR),
        .TM          (TM),
        .ScanOutCC   (ScanOutCC),

        .Iref        (Iref),
        .Vcc_read    (Vcc_read),
        .Vcomp       (Vcomp),
        .Bias_comp2  (Bias_comp2),
        .Vcc_wl_read (Vcc_wl_read),
        .Vcc_wl_set  (Vcc_wl_set),
        .Vbias       (Vbias),
        .Vcc_wl_reset(Vcc_wl_reset),
        .Vcc_set     (Vcc_set),
        .dc_bias     (dc_bias)
    );

    // ------------------------------------------------------------------------
    // clocks
    // ------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #25  clk = ~clk;      // 20 MHz
    end

    initial begin
        user_clk = 1'b0;
        forever #25  user_clk = ~user_clk;
    end

    // ------------------------------------------------------------------------
    // SPI master task
    // SPI mode-0 at 20 MHz:
    // period = 50 ns, low = 25 ns, high = 25 ns
    // ------------------------------------------------------------------------
    task spi_transfer_40;
        input  [39:0] tx_frame;
        output [39:0] rx_out;
        integer i;
        begin
            rx_out   = 40'd0;
            spi_cs_n = 1'b1;
            spi_sclk = 1'b0;
            spi_mosi = 1'b0;
            #100;

            spi_cs_n = 1'b0;

            for (i = 39; i >= 0; i = i - 1) begin
                // low phase
                spi_mosi = tx_frame[i];
                #100;

                // rising edge: sample MISO
                spi_sclk   = 1'b1;
                rx_out[i]  = spi_miso;

                // high phase
                #100;
                spi_sclk = 1'b0;
            end

            #100;
            spi_cs_n = 1'b1;
            spi_mosi = 1'b0;
            #100;
        end
    endtask

    // ------------------------------------------------------------------------
    // stimulus
    // ------------------------------------------------------------------------
    initial begin
        // defaults
        rst          = 1'b1;
        user_rst     = 1'b1;

        spi_sclk     = 1'b0;
        spi_cs_n     = 1'b1;
        spi_mosi     = 1'b0;

        ScanInCC     = 1'b0;
        ScanInDL     = 1'b0;
        ScanInDR     = 1'b0;
        TM           = 1'b0;

        Iref         = 1'b0;
        Vcc_read     = 1'b0;
        Vcomp        = 1'b0;
        Bias_comp2   = 1'b0;
        Vcc_wl_read  = 1'b0;
        Vcc_wl_set   = 1'b0;
        Vbias        = 1'b0;
        Vcc_wl_reset = 1'b0;
        Vcc_set      = 1'b0;
        dc_bias      = 1'b0;

        #200;
        rst      = 1'b0;
        user_rst = 1'b0;
        #200;

        $display("====================================================");
        $display("Transaction 1: SPI WRITE 0x%08h", WRITE_DATA_1);
        $display("====================================================");
        spi_transfer_40({SPI_CMD_WRITE, WRITE_DATA_1}, rx_frame_1);
        $display("Returned MISO frame during WRITE1 = 0x%010h", rx_frame_1);
				
				// repeat (50) @(posedge clk);

        $display("====================================================");
        $display("Transaction 2: SPI WRITE 0x%08h", WRITE_DATA_2);
        $display("====================================================");
        spi_transfer_40({SPI_CMD_WRITE, WRITE_DATA_2}, rx_frame_2);
        $display("Returned MISO frame during WRITE2 = 0x%010h", rx_frame_2);

        $display("====================================================");
        $display("Delay 300 WB clocks");
        $display("====================================================");
        repeat (150) @(posedge clk);

        $display("====================================================");
        $display("Transaction 3: SPI READ");
        $display("====================================================");
        spi_transfer_40({SPI_CMD_READ, DUMMY_DATA}, rx_frame_3);
        $display("Returned MISO frame during READ   = 0x%010h", rx_frame_3);

        $display("----------------------------------------------------");
        $display("Internal observation");
        $display("dut.u_wb_slave.core_inst.ip_fifo[0]  = 0x%08h", dut.u_wb_slave.core_inst.ip_fifo[0]);
        $display("dut.u_wb_slave.core_inst.ip_fifo[1]  = 0x%08h", dut.u_wb_slave.core_inst.ip_fifo[1]);
        $display("dut.u_wb_slave.core_inst.op_fifo[0]  = 0x%08h", dut.u_wb_slave.core_inst.op_fifo[0]);
        $display("dut.u_wb_master.rdata                = 0x%08h", dut.u_wb_master.rdata);
        $display("----------------------------------------------------");
				
				//////////////////////////////////////////////////////////////
				
				// repeat (30) @(posedge clk);
				
				spi_transfer_40({SPI_CMD_WRITE, 32'hC210_004E}, rx_frame_1);
				spi_transfer_40({SPI_CMD_WRITE, WRITE_DATA_2}, rx_frame_2);
				repeat (150) @(posedge clk);
				spi_transfer_40({SPI_CMD_READ, DUMMY_DATA}, rx_frame_3);
				
				// repeat (30) @(posedge clk);
				
				spi_transfer_40({SPI_CMD_WRITE, 32'hC210_0093}, rx_frame_1);
				spi_transfer_40({SPI_CMD_WRITE, WRITE_DATA_2}, rx_frame_2);
				repeat (150) @(posedge clk);
				spi_transfer_40({SPI_CMD_READ, DUMMY_DATA}, rx_frame_3);
				
			
				//////////////////////////////////////////////////////////////

        #200;
        $finish;
    end

endmodule