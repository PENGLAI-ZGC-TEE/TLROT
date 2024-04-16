# 可信根说明

## 测试模式说明
在Nanhu V3版本，增加了一个bootrom_disable GPIO，测试时默认不启用可信根的安全启动，若要启用，则在make是添加ROT=1的标识，如make emu ROT=1, 同时需要把SimTop.scala中的riscv_rst_vec地址修改为可信根中bootrom的地址（0x3b200000）。此时，芯片在上电后，首先进行Boortom的自检，检验通过后，CPU从ROM地址开始执行指令。

## 可信根地址空间说明
目前可信根在main/mmio分支中，均占用0x3b000000-0x3b300000 这一段地址，其中0x3b200000-0x3b300000地址段可读可执行

## 可信根存储说明
可信根中存在一个32KB的ROM和两块4KB的SRAM，具体如下：
1. ROM：位于src/main/resources/TLROT/src/lowrisc_prim_generic_rom_0/rtl/prim_generic_rom.sv， 64bit位宽，32KB，depth：'d4096
2. SRAM: 分别是1024 * 39和128 * 312（位宽312）都在src/main/resources/TLROT/src/lowrisc_ip_otbn_0.1/rtl/otbn.sv文件中，名称是prim_ram_1p_scr，例化为imem和dmem，其底层在src/main/resources/TLROT/src/lowrisc_prim_generic_ram_1p_0/rtl/prim_generic_ram_1p.sv，sram_array_1p128x312m39 和 sram_array_1p1024x39m39，为单端口器件，有一个读端口一个写端口,目前均无MBIST端口，均支持最小写入39bit数据

## 可信根DC综合说明
1. 综合时需define SYNTHESIS
2. 由于PUF中RO需要连接计数器，进行计数，即计数器的时钟为RO的输出，应当禁止DC对相关路径进行时序分析优化，因此在DC脚本中加入(根据实际module名字修改)：
- create_clock -name puf_a_clk [get_pins XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf/u_PUF_core/puf_128/puf_inst/CounterA/cnt_in]
- create_clock -name puf_b_clk [get_pins XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf/u_PUF_core/puf_128/puf_inst/CounterB/cnt_in]
- set_false_path -from [get_clock puf_a_clk ] -to [get_clock io_clock]
- set_false_path -from [get_clock puf_b_clk ] -to [get_clock io_clock]
- create_clock -name puf2_a_clk [get_pins XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf2/u_PUF_core/puf_128/puf_inst/CounterA/cnt_in]
- create_clock -name puf2_b_clk [get_pins XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf2/u_PUF_core/puf_128/puf_inst/CounterB/cnt_in]
- set_false_path -from [get_clock puf2_a_clk ] -to [get_clock io_clock]
- set_false_path -from [get_clock puf2_b_clk ] -to [get_clock io_clock]
3. RO因为构成了环，会被DC优化掉，因此需要禁止DC优化这几个器件，在脚本中加入(根据实际module名字修改)：
- set_dont_touch [get cells XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf/u_PUF_core/puf_128/puf_inst/puf_a/puf_array*]
- set_dont_touch [get cells XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf/u_PUF_core/puf_128/puf_inst/puf_b/puf_array*]
- set_dont_touch [get cells XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf2/u_PUF_core/puf_128/puf_inst/puf_a/puf_array*]
- set_dont_touch [get cells XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf2/u_PUF_core/puf_128/puf_inst/puf_b/puf_array*]
4. RO的module名分别为：
- RO_Array128 （包含了128个RO）
- Single_RO （单个RO）

## 可信根后端说明
可信根中有RO PUF，需要保证其布局布线一致，具体如下（每组包含128个RO）：
- XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf/u_PUF_core/puf_128/puf_inst/puf_a/puf_array*
- XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf/u_PUF_core/puf_128/puf_inst/puf_b/puf_array*
- XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf2/u_PUF_core/puf_128/puf_inst/puf_a/puf_array*
- XSTop/misc/periCx/rot/tlrot/u_rot_top/u_puf2/u_PUF_core/puf_128/puf_inst/puf_b/puf_array*