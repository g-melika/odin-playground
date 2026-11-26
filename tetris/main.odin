package tetris

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Vec2 :: rl.Vector2

DARK_GREY := rl.Color{26, 31, 40, 255}
GREEN := rl.Color{47, 230, 23, 255}
RED := rl.Color{232, 18, 18, 255}
ORANGE := rl.Color{226, 116, 17, 255}
YELLOW := rl.Color{237, 234, 4, 255}
PURPLE := rl.Color{166, 0, 247, 255}
CYAN := rl.Color{21, 204, 209, 255}
BLUE := rl.Color{13, 64, 216, 255}
LIGHT_BLUE := rl.Color{59, 85, 162, 255}
DARK_BLUE := rl.Color{44, 44, 127, 255}

COLORS := []rl.Color{DARK_GREY, GREEN, RED, ORANGE, YELLOW, PURPLE, CYAN, BLUE}

N_ROWS :: 20
N_COLS :: 10
CELL_SIZE :: 30
SCREEN_PADDING :: 10
MARGIN :: 1

last_update_time: f64 = 0

Grid :: [N_ROWS][N_COLS]i32

grid_print :: proc(grid: Grid) {
	for row in grid {
		for cell in row {
			fmt.printf("%d ", cell)
		}
		fmt.println()
	}
}

grid_draw :: proc(g: Grid) {
	for row, y in g {
		for cell, x in row {
			rl.DrawRectangle(
				i32(x) * CELL_SIZE + MARGIN + SCREEN_PADDING,
				i32(y) * CELL_SIZE + MARGIN + SCREEN_PADDING,
				CELL_SIZE - MARGIN,
				CELL_SIZE - MARGIN,
				COLORS[cell],
			)
		}
	}
}

grid_is_cell_empty :: proc(g: Grid, pos: Pos) -> bool {
	if g[pos.row][pos.col] == 0 {
		return true
	}
	return false
}

grid_is_row_full :: proc(g: Grid, row: int) -> bool {
	for col in 0 ..< N_COLS {
		if g[row][col] == 0 {
			return false
		}
	}
	return true
}

grid_clear_row :: proc(g: ^Grid, row: int) {
	for col in 0 ..< N_COLS {
		g[row][col] = 0
	}
}

grid_move_row_down :: proc(g: ^Grid, row, num_rows: int) {
	for col in 0 ..< N_COLS {
		g[row + num_rows][col] = g[row][col]
		g[row][col] = 0
	}
}

grid_clear_full_rows :: proc(g: ^Grid) -> int {
	completed := 0

	for row := N_ROWS - 1; row >= 0; row -= 1 {
		if grid_is_row_full(g^, row) {
			grid_clear_row(g, row)
			completed += 1
		} else if completed > 0 {
			grid_move_row_down(g, row, completed)
		}
	}

	return completed
}

Block_Type :: enum {
	L,
	J,
	I,
	O,
	S,
	T,
	Z,
}

block_type_all :: proc() -> [dynamic]Block_Type {
	blocks := make([dynamic]Block_Type, len(Block_Type))
	for type, i in Block_Type {
		blocks[i] = type
	}

	return blocks
}

block_type_rand :: proc(blocks: ^[dynamic]Block_Type) -> Block_Type {
	if len(blocks) < 1 {
		delete(blocks^)
		blocks^ = block_type_all()
	}
	i := rand.int_max(len(blocks))
	block_type := blocks[i]
	unordered_remove(blocks, i)
	return block_type
}

Pos :: struct {
	row: i32,
	col: i32,
}

pos_is_outside :: proc(pos: Pos) -> bool {
	if pos.row >= 0 && pos.row < N_ROWS && pos.col >= 0 && pos.col < N_COLS {
		return false
	}
	return true
}

Block :: struct {
	id:       i32,
	rotation: i32, // 0..=3
	cells:    [4][4]Pos,
	offset:   Pos,
}

block_make :: proc(type: Block_Type) -> (b: Block) {
	#partial switch type {
	case .L:
		b = Block {
			id       = 1,
			rotation = 0,
			cells    = {
				{{0, 2}, {1, 0}, {1, 1}, {1, 2}},
				{{0, 1}, {1, 1}, {2, 1}, {2, 2}},
				{{1, 0}, {1, 1}, {1, 2}, {2, 0}},
				{{0, 0}, {0, 1}, {1, 1}, {2, 1}},
			},
			offset   = {0, 3},
		}
	case .J:
		b = Block {
			id     = 2,
			cells  = {
				{{0, 0}, {1, 0}, {1, 1}, {1, 2}},
				{{0, 1}, {0, 2}, {1, 1}, {2, 1}},
				{{1, 0}, {1, 1}, {1, 2}, {2, 2}},
				{{0, 1}, {1, 1}, {2, 0}, {2, 1}},
			},
			offset = {0, 3},
		}
	case .I:
		b = Block {
			id     = 3,
			cells  = {
				{{1, 0}, {1, 1}, {1, 2}, {1, 3}},
				{{0, 2}, {1, 2}, {2, 2}, {3, 2}},
				{{2, 0}, {2, 1}, {2, 2}, {2, 3}},
				{{0, 1}, {1, 1}, {2, 1}, {3, 1}},
			},
			offset = {-1, 3},
		}
	case .O:
		b = Block {
			id     = 4,
			cells  = {
				{{0, 0}, {0, 1}, {1, 0}, {1, 1}},
				{{0, 0}, {0, 1}, {1, 0}, {1, 1}},
				{{0, 0}, {0, 1}, {1, 0}, {1, 1}},
				{{0, 0}, {0, 1}, {1, 0}, {1, 1}},
			},
			offset = {0, 4},
		}
	case .S:
		b = Block {
			id     = 5,
			cells  = {
				{{0, 1}, {0, 2}, {1, 0}, {1, 1}},
				{{0, 1}, {1, 1}, {1, 2}, {2, 2}},
				{{1, 1}, {1, 2}, {2, 0}, {2, 1}},
				{{0, 0}, {1, 0}, {1, 1}, {2, 1}},
			},
			offset = {0, 3},
		}
	case .T:
		b = Block {
			id     = 6,
			cells  = {
				{{0, 1}, {1, 0}, {1, 1}, {1, 2}},
				{{0, 1}, {1, 1}, {1, 2}, {2, 1}},
				{{1, 0}, {1, 1}, {1, 2}, {2, 1}},
				{{0, 1}, {1, 0}, {1, 1}, {2, 1}},
			},
			offset = {0, 3},
		}
	case .Z:
		b = Block {
			id     = 7,
			cells  = {
				{{0, 0}, {0, 1}, {1, 1}, {1, 2}},
				{{0, 2}, {1, 1}, {1, 2}, {2, 1}},
				{{1, 0}, {1, 1}, {2, 1}, {2, 2}},
				{{0, 1}, {1, 0}, {1, 1}, {2, 0}},
			},
			offset = {0, 3},
		}
	}
	return
}

block_draw :: proc(b: Block, offset: Vec2) {
	for item in block_cell_pos(b) {
		rl.DrawRectangle(
			i32(item.col) * CELL_SIZE + i32(offset.x),
			i32(item.row) * CELL_SIZE + i32(offset.y),
			CELL_SIZE - MARGIN,
			CELL_SIZE - MARGIN,
			COLORS[b.id],
		)
	}
}

block_move :: proc(b: ^Block, offset: Pos) {
	b.offset.col = b.offset.col + offset.col
	b.offset.row = b.offset.row + offset.row
}

block_rotate :: proc(b: ^Block) {
	b.rotation += 1
	if b.rotation >= len(b.cells) {
		b.rotation = 0
	}
}

block_undo_rotate :: proc(b: ^Block) {
	b.rotation -= 1
	if b.rotation <= 0 {
		b.rotation = len(b.cells) - 1
	}
}

block_cell_pos :: proc(b: Block) -> [4]Pos {
	tiles := b.cells[b.rotation]
	moved_tiles: [4]Pos
	for tile, i in tiles {
		moved_tiles[i] = Pos {
			col = tile.col + b.offset.col,
			row = tile.row + b.offset.row,
		}
	}
	return moved_tiles
}

block_is_outside :: proc(b: Block) -> bool {
	for tile in block_cell_pos(b) {
		if pos_is_outside(tile) {
			return true
		}
	}

	return false
}


Game :: struct {
	grid:         Grid,
	blocks:       [dynamic]Block_Type,
	curr_block:   Block,
	next_block:   Block,
	game_over:    bool,
	score:        u64,
	music:        rl.Music,
	rotate_sound: rl.Sound,
	clear_sound:  rl.Sound,
}

game_make :: proc() -> Game {
	blocks := block_type_all()
	curr_block := block_make(block_type_rand(&blocks))
	next_block := block_make(block_type_rand(&blocks))
	music := rl.LoadMusicStream("assets/music.mp3")
	rotate_sound := rl.LoadSound("assets/rotate.mp3")
	clear_sound := rl.LoadSound("assets/clear.mp3")

	rl.PlayMusicStream(music)

	return Game {
		blocks = blocks,
		curr_block = curr_block,
		next_block = next_block,
		music = music,
		rotate_sound = rotate_sound,
		clear_sound = clear_sound,
	}
}

game_destroy :: proc(g: ^Game) {
	delete(g.blocks)
	rl.UnloadMusicStream(g.music)
	rl.UnloadSound(g.rotate_sound)
	rl.UnloadSound(g.clear_sound)
}

game_reset :: proc(g: ^Game) {
	g.grid = {}
	g.blocks = block_type_all()
	g.curr_block = block_make(block_type_rand(&g.blocks))
	g.next_block = block_make(block_type_rand(&g.blocks))
	g.game_over = false
	g.score = 0
}

game_update_score :: proc(g: ^Game, lines_cleared, move_down_points: int) {
	switch lines_cleared {
	case 1:
		g.score += 100
	case 2:
		g.score += 300
	case 3:
		g.score += 500
	}
	g.score += u64(move_down_points)
}

game_draw :: proc(g: Game) {
	grid_draw(g.grid)
	block_draw(g.curr_block, {MARGIN + SCREEN_PADDING, MARGIN + SCREEN_PADDING})
	#partial switch Block_Type(g.next_block.id - 1) {
	case .I:
		block_draw(g.next_block, {255, 290})
	case .O:
		block_draw(g.next_block, {255, 280})
	case:
		block_draw(g.next_block, {270, 270})
	}
}

game_move_block_left :: proc(g: ^Game) {
	if g.game_over do return
	block_move(&g.curr_block, {0, -1})
	if block_is_outside(g.curr_block) || !game_block_fits(g^) {
		block_move(&g.curr_block, {0, 1})
	}
}

game_move_block_right :: proc(g: ^Game) {
	if g.game_over do return
	block_move(&g.curr_block, {0, 1})
	if block_is_outside(g.curr_block) || !game_block_fits(g^) {
		block_move(&g.curr_block, {0, -1})
	}
}

game_move_block_down :: proc(g: ^Game) {
	if g.game_over do return
	block_move(&g.curr_block, {1, 0})
	if block_is_outside(g.curr_block) || !game_block_fits(g^) {
		block_move(&g.curr_block, {-1, 0})
		game_lock_block(g)
	}
}
game_rotate_block :: proc(g: ^Game) {
	if g.game_over do return
	block_rotate(&g.curr_block)
	if block_is_outside(g.curr_block) {
		block_undo_rotate(&g.curr_block)
	} else {
		rl.PlaySound(g.rotate_sound)
	}
}

game_lock_block :: proc(g: ^Game) {
	tiles := block_cell_pos(g.curr_block)
	for tile in tiles {
		g.grid[tile.row][tile.col] = g.curr_block.id
	}
	g.curr_block = g.next_block
	if !game_block_fits(g^) {
		g.game_over = true
	}
	g.next_block = block_make(block_type_rand(&g.blocks))
	rows_cleared := grid_clear_full_rows(&g.grid)
	if rows_cleared > 0 {
		rl.PlaySound(g.clear_sound)
		game_update_score(g, rows_cleared, 0)
	}
}

game_block_fits :: proc(g: Game) -> bool {
	tiles := block_cell_pos(g.curr_block)
	for tile in tiles {
		if !grid_is_cell_empty(g.grid, tile) {
			return false
		}
	}
	return true
}

game_handle_input :: proc(g: ^Game) {
	key_pressed := rl.GetKeyPressed()

	if g.game_over && key_pressed != .KEY_NULL {
		game_reset(g)
	}

	#partial switch key_pressed {
	case .LEFT, .A, .H:
		game_move_block_left(g)
	case .RIGHT, .D, .L:
		game_move_block_right(g)
	case .DOWN, .S, .J:
		game_update_score(g, 0, 1)
		game_move_block_down(g)
	case .UP, .W, .K:
		game_rotate_block(g)
	}
}


event_triggered :: proc(interval: f64) -> bool {
	curr_time := rl.GetTime()
	if curr_time - last_update_time >= interval {
		last_update_time = curr_time
		return true
	}
	return false
}

main :: proc() {
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_HIGHDPI})
	rl.InitWindow(500, 620, "Tetris!")
	rl.SetTargetFPS(60)
	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	g := game_make()
	defer game_destroy(&g)

	grid_print(g.grid)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.UpdateMusicStream(g.music)

		game_handle_input(&g)

		if event_triggered(0.2) {
			game_move_block_down(&g)
		}

		rl.ClearBackground(DARK_BLUE)
		rl.DrawText("Score", 365, 15, 28, rl.RAYWHITE)
		rl.DrawText("Next", 370, 175, 28, rl.RAYWHITE)
		if g.game_over {
			rl.DrawText("GAME OVER", 320, 450, 28, rl.RAYWHITE)
		}
		rl.DrawRectangleRounded({320, 55, 170, 60}, 0.3, 6, LIGHT_BLUE)
		score_text := fmt.ctprintf("%d", g.score)
		text_size := rl.MeasureText(score_text, 28)
		rl.DrawText(score_text, 320 + (170 - text_size) / 2, 65, 28, rl.RAYWHITE)
		rl.DrawRectangleRounded({320, 215, 170, 180}, 0.3, 6, LIGHT_BLUE)
		game_draw(g)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
