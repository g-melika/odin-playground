package playground

import rl "vendor:raylib"

SCREEEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

main :: proc() {
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_HIGHDPI})
	rl.InitWindow(SCREEEN_WIDTH, SCREEN_HEIGHT, "Hellope!")
	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.DrawText("Hellop!", SCREEEN_WIDTH / 2 - 35, SCREEN_HEIGHT / 2, 20, rl.LIGHTGRAY)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
