onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/clk
add wave -noupdate /tb_top/rst_n
add wave -noupdate /tb_top/valid_in
add wave -noupdate /tb_top/din0
add wave -noupdate /tb_top/din1
add wave -noupdate /tb_top/din2
add wave -noupdate /tb_top/din3
add wave -noupdate /tb_top/din4
add wave -noupdate /tb_top/din5
add wave -noupdate /tb_top/din6
add wave -noupdate /tb_top/din7
add wave -noupdate /tb_top/din8
add wave -noupdate /tb_top/dout
add wave -noupdate /tb_top/valid_out
add wave -noupdate /tb_top/conv_result
add wave -noupdate /tb_top/relu_result
add wave -noupdate /tb_top/valid_conv_out
add wave -noupdate /tb_top/valid_relu_out
add wave -noupdate /tb_top/f_out
add wave -noupdate /tb_top/f_in
add wave -noupdate /tb_top/i
add wave -noupdate /tb_top/j
add wave -noupdate /tb_top/pool_i
add wave -noupdate /tb_top/pool_j
add wave -noupdate /tb_top/relu_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {195913792002 ps} {195913816211 ps}
