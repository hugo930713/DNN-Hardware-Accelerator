onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/clk
add wave -noupdate /tb_top/rst_n
add wave -noupdate /tb_top/valid_in
add wave -noupdate /tb_top/pixel_in
add wave -noupdate /tb_top/img_width
add wave -noupdate /tb_top/img_height
add wave -noupdate /tb_top/padding_mode
add wave -noupdate /tb_top/dout
add wave -noupdate /tb_top/valid_out
add wave -noupdate /tb_top/conv_result
add wave -noupdate /tb_top/relu_result
add wave -noupdate /tb_top/valid_conv_out
add wave -noupdate /tb_top/valid_relu_out
add wave -noupdate /tb_top/debug_win_out0
add wave -noupdate /tb_top/debug_win_out1
add wave -noupdate /tb_top/debug_win_out2
add wave -noupdate /tb_top/debug_win_out3
add wave -noupdate /tb_top/debug_win_out4
add wave -noupdate /tb_top/debug_win_out5
add wave -noupdate /tb_top/debug_win_out6
add wave -noupdate /tb_top/debug_win_out7
add wave -noupdate /tb_top/debug_win_out8
add wave -noupdate /tb_top/valid_window_out
add wave -noupdate /tb_top/f_out
add wave -noupdate /tb_top/f_in
add wave -noupdate /tb_top/i
add wave -noupdate /tb_top/j
add wave -noupdate /tb_top/current_row
add wave -noupdate /tb_top/current_col
add wave -noupdate /tb_top/original_r
add wave -noupdate /tb_top/original_c
add wave -noupdate /tb_top/pixel_count
add wave -noupdate /tb_top/conv_count
add wave -noupdate /tb_top/relu_count
add wave -noupdate /tb_top/pool_count
add wave -noupdate /tb_top/window_count
add wave -noupdate /tb_top/expected_window_count
add wave -noupdate /tb_top/expected_conv_count
add wave -noupdate /tb_top/expected_pool_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {173709 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 330
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
configure wave -timelineunits ns
update
WaveRestoreZoom {124188 ps} {745142 ps}
