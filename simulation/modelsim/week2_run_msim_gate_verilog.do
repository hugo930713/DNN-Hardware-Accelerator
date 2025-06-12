transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {week2.vo}

vlog -vlog01compat -work work +incdir+C:/Users/m_User/Desktop/DNN-Hardware-Accelerator {C:/Users/m_User/Desktop/DNN-Hardware-Accelerator/tb_top.v}

vsim -t 1ps -L altera_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L gate_work -L work -voptargs="+acc"  tb_top

add wave *
view structure
view signals
run -all
