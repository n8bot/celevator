local nbsounds = {
	--At the moment this is everything except the nudging buzzer
	"celevator_brake_apply",
	"celevator_brake_release",
	"celevator_cabinet_close",
	"celevator_cabinet_open",
	"celevator_car_run",
	"celevator_car_start",
	"celevator_car_stop",
	"celevator_chime_down",
	"celevator_chime_up",
	"celevator_controller_start",
	"celevator_controller_stop",
	"celevator_door_close",
	"celevator_door_open",
	"celevator_door_reverse",
	"celevator_drive_run",
	"celevator_motor_accel",
	"celevator_motor_decel",
	"celevator_motor_fast",
	"celevator_motor_slow",
	"celevator_pi_beep",
}

for _,i in ipairs(nbsounds) do digistuff.register_nb_sound(i,i) end
