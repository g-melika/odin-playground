package snake

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Vec2 :: rl.Vector2
Rect :: rl.Rectangle

SCREEN_WIDTH :: 750
SCREEN_HEIGHT :: 750

GREEN :: rl.Color{172, 204, 96, 255}
DARK_GREEN :: rl.Color{43, 51, 42, 255}

CELL_SIZE :: 30
CELL_COUNT :: 25
OFFSET :: 75

UPDATE_INTERVAL :: 0.2

last_update_time: f64

element_in_slice :: proc(elem: Vec2, slice: []Vec2) -> bool {
	for v in slice {
		if elem.x == v.x && elem.y == v.y {
			return true
		}
	}

	return false
}
Food :: struct {
	pos: Vec2,
}

food_make :: proc(body: []Vec2) -> Food {
	f := Food {
		pos = generate_random_pos(body),
	}
	return f
}

food_draw :: proc(f: Food) {
	x := OFFSET + i32(f.pos.x) * CELL_SIZE
	y := OFFSET + i32(f.pos.y) * CELL_SIZE

	rl.DrawRectangle(x + 10, y, 8, 10, DARK_GREEN) // top
	rl.DrawRectangle(x, y + 10, 10, 8, DARK_GREEN) // left
	rl.DrawRectangle(x + 18, y + 10, 10, 8, DARK_GREEN) // right
	rl.DrawRectangle(x + 10, y + 18, 8, 10, DARK_GREEN) // bottom
}

Snake :: struct {
	body:        [dynamic]Vec2,
	direction:   Vec2,
	add_segment: bool,
}

snake_make :: proc() -> Snake {
	s := Snake {
		body      = make([dynamic]Vec2, 3, 100),
		direction = Vec2{1, 0},
	}

	s.body[0] = Vec2{6, 9}
	s.body[1] = Vec2{5, 9}
	s.body[2] = Vec2{4, 9}

	return s
}

snake_draw :: proc(s: Snake) {
	for b in s.body {
		rl.DrawRectangleRounded(
			Rect{OFFSET + b.x * CELL_SIZE, OFFSET + b.y * CELL_SIZE, CELL_SIZE, CELL_SIZE},
			0.5,
			6,
			DARK_GREEN,
		)
	}
}

snake_update :: proc(s: ^Snake) {
	inject_at(&s.body, 0, s.body[0] + s.direction)
	if s.add_segment {
		s.add_segment = false
	} else {
		pop(&s.body)
	}
}

snake_reset :: proc(s: ^Snake) {
	clear(&s.body)
	append(&s.body, Vec2{6, 9})
	append(&s.body, Vec2{5, 9})
	append(&s.body, Vec2{4, 9})
	s.direction = Vec2{1, 0}
}

event_update :: proc() -> bool {
	current_time := rl.GetTime()
	if current_time - last_update_time >= UPDATE_INTERVAL {
		last_update_time = current_time
		return true
	}
	return false
}

collision_with_food :: proc(g: ^Game) {
	if g.snake.body[0] == g.food.pos {
		g.food.pos = generate_random_pos(g.snake.body[:])
		g.snake.add_segment = true
		g.score += 1
		rl.PlaySound(g.eat_sound)
	}
}

collision_with_edges :: proc(g: ^Game) {
	if (g.snake.body[0].x == CELL_COUNT ||
		   g.snake.body[0].x == -1 ||
		   g.snake.body[0].y == CELL_COUNT ||
		   g.snake.body[0].y == -1) {
		rl.PlaySound(g.wall_sound)
		game_over(g)
	}
}

collision_with_tail :: proc(g: ^Game) {
	if len(g.snake.body) > 1 {
		if (element_in_slice(g.snake.body[0], g.snake.body[1:])) {
			game_over(g)
		}
	}
}

generate_random_cell :: proc() -> Vec2 {
	x := rand.int_max(CELL_COUNT)
	y := rand.int_max(CELL_COUNT)
	return Vec2{f32(x), f32(y)}
}

generate_random_pos :: proc(body: []Vec2) -> Vec2 {
	pos := generate_random_cell()
	for element_in_slice(pos, body) {
		pos = generate_random_cell()
	}
	return pos
}

Game :: struct {
	snake:      Snake,
	food:       Food,
	running:    bool,
	score:      i32,
	eat_sound:  rl.Sound,
	wall_sound: rl.Sound,
}

game_make :: proc() -> Game {
	snake := snake_make()
	return Game {
		snake = snake,
		food = food_make(snake.body[:]),
		running = true,
		eat_sound = rl.LoadSound("assets/eat.mp3"),
		wall_sound = rl.LoadSound("assets/wall.mp3"),
	}
}

game_destroy :: proc(g: Game) {
	rl.UnloadSound(g.eat_sound)
	rl.UnloadSound(g.wall_sound)
}

game_draw :: proc(g: Game) {
	food_draw(g.food)
	snake_draw(g.snake)
}

game_update :: proc(g: ^Game) {
	if (g.running) {
		snake_update(&g.snake)
		collision_with_food(g)
		collision_with_edges(g)
		collision_with_tail(g)
	}

}

game_input :: proc(g: ^Game) {
	if (rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) || rl.IsKeyPressed(.K)) &&
	   g.snake.direction.y != 1 {
		g.snake.direction = Vec2{0, -1}
		g.running = true
	}

	if (rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) || rl.IsKeyPressed(.J)) &&
	   g.snake.direction.y != -1 {
		g.snake.direction = Vec2{0, 1}
		g.running = true
	}

	if (rl.IsKeyPressed(.LEFT) || rl.IsKeyPressed(.A) || rl.IsKeyPressed(.H)) &&
	   g.snake.direction.x != 1 {
		g.snake.direction = Vec2{-1, 0}
		g.running = true
	}

	if (rl.IsKeyPressed(.RIGHT) || rl.IsKeyPressed(.D) || rl.IsKeyPressed(.L)) &&
	   g.snake.direction.x != 1 {
		g.snake.direction = Vec2{1, 0}
		g.running = true
	}
}

game_over :: proc(g: ^Game) {
	snake_reset(&g.snake)
	g.running = false
	g.score = 0
}

main :: proc() {
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_HIGHDPI})
	rl.InitWindow(
		2 * OFFSET + CELL_SIZE * CELL_COUNT,
		2 * OFFSET + CELL_SIZE * CELL_COUNT,
		"Retro Snake!",
	)
	rl.SetTargetFPS(60)
	rl.InitAudioDevice()

	game := game_make()
	defer game_destroy(game)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		if event_update() {
			game_update(&game)
		}

		game_input(&game)

		rl.ClearBackground(GREEN)
		border := Rect {
			f32(OFFSET - 5),
			f32(OFFSET - 5),
			f32(CELL_SIZE * CELL_COUNT + 10),
			f32(CELL_SIZE * CELL_COUNT + 10),
		}
		rl.DrawRectangleLinesEx(border, 5, DARK_GREEN)
		rl.DrawText("Retro Snake!", OFFSET - 5, 20, 40, DARK_GREEN)
		rl.DrawText(
			fmt.caprintf("%d", game.score),
			OFFSET - 5,
			OFFSET + CELL_SIZE * CELL_COUNT + 10,
			40,
			DARK_GREEN,
		)
		game_draw(game)


		rl.EndDrawing()
	}
	rl.CloseWindow()
}
