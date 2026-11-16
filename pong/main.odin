package pong

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"


Ball :: struct {
	x, y:             i32,
	speed_x, speed_y: i32,
	radius:           i32,
}

ball_draw :: proc(b: Ball) {
	rl.DrawCircle(b.x, b.y, f32(b.radius), YELLOW)
}

ball_update :: proc(b: ^Ball) {
	b.x += b.speed_x
	b.y += b.speed_y
	if b.y + b.radius >= rl.GetScreenHeight() || b.y - b.radius <= 0 {
		b.speed_y *= -1
	}

	if b.x + b.radius >= rl.GetScreenWidth() {
		b.speed_x *= -1
		cpu_score += 1
		ball_reset(b)
	}
	if b.x - b.radius <= 0 {
		b.speed_x *= -1
		player_score += 1
		ball_reset(b)
	}
}

ball_reset :: proc(b: ^Ball) {
	b.x = rl.GetScreenWidth() / 2
	b.y = rl.GetScreenHeight() / 2

	choices: [2]int = {-1, 1}

	b.speed_x *= i32(rand.choice(choices[:]))
	b.speed_y *= i32(rand.choice(choices[:]))
}

Paddle :: struct {
	x, y:          i32,
	speed:         i32,
	width, height: i32,
}

paddle_draw :: proc(p: Paddle) {
	rl.DrawRectangleRounded(
		rl.Rectangle{f32(p.x), f32(p.y), f32(p.width), f32(p.height)},
		0.8,
		0,
		rl.RAYWHITE,
	)
}

paddle_limit_movement :: proc(p: ^Paddle) {
	if p.y <= 0 {
		p.y = 0
	}
	if p.y + p.height >= rl.GetScreenHeight() {
		p.y = rl.GetScreenHeight() - p.height
	}
}

paddle_update :: proc(p: ^Paddle) {
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) || rl.IsKeyDown(.J) {
		p.y += p.speed
	}
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) || rl.IsKeyDown(.K) {
		p.y -= p.speed
	}
	paddle_limit_movement(p)
}

paddle_cpu_update :: proc(p: ^Paddle, ball_y: i32) {
	if p.y + p.height / 2 > ball_y {
		p.y -= p.speed
	}
	if p.y + p.height / 2 <= ball_y {
		p.y += p.speed
	}
	paddle_limit_movement(p)
}

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 800

GREEN :: rl.Color{38, 185, 154, 255}
DARK_GREEN :: rl.Color{20, 160, 133, 255}
LIGHT_GREEN :: rl.Color{129, 204, 184, 255}
YELLOW :: rl.Color{243, 213, 91, 255}

player_score := 0
cpu_score := 0

ball: Ball
player: Paddle
cpu: Paddle

main :: proc() {
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_HIGHDPI})
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Pong Pong!")
	rl.SetTargetFPS(60)

	ball = Ball {
		x       = SCREEN_WIDTH / 2,
		y       = SCREEN_HEIGHT / 2,
		speed_x = 7,
		speed_y = 7,
		radius  = 20,
	}

	player = Paddle {
		x      = SCREEN_WIDTH - 25 - 10,
		y      = SCREEN_HEIGHT / 2 - 100 / 2,
		width  = 25,
		height = 100,
		speed  = 6,
	}

	cpu = Paddle {
		x      = 10,
		y      = SCREEN_HEIGHT / 2 - 100 / 2,
		width  = 25,
		height = 100,
		speed  = 6,
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		// Update
		ball_update(&ball)
		paddle_update(&player)
		paddle_cpu_update(&cpu, ball.y)

		// Collision
		if rl.CheckCollisionCircleRec(
			{f32(ball.x), f32(ball.y)},
			f32(ball.radius),
			{f32(player.x), f32(player.y), f32(player.width), f32(player.height)},
		) {
			ball.speed_x *= -1
		}

		if rl.CheckCollisionCircleRec(
			{f32(ball.x), f32(ball.y)},
			f32(ball.radius),
			{f32(cpu.x), f32(cpu.y), f32(cpu.width), f32(cpu.height)},
		) {
			ball.speed_x *= -1
		}

		// Drawing
		rl.ClearBackground(DARK_GREEN)
		rl.DrawRectangle(SCREEN_WIDTH / 2, 0, SCREEN_WIDTH, SCREEN_HEIGHT, GREEN)
		rl.DrawCircle(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 150, LIGHT_GREEN)
		rl.DrawLine(SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT, rl.RAYWHITE)
		ball_draw(ball)
		paddle_draw(cpu)
		paddle_draw(player)
		rl.DrawText(fmt.caprintf("%d", cpu_score), SCREEN_WIDTH / 4, 20, 80, rl.RAYWHITE)
		rl.DrawText(fmt.caprintf("%d", player_score), 3 * SCREEN_WIDTH / 4, 20, 80, rl.RAYWHITE)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
