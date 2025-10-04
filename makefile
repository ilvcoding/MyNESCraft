all: game

game: code.asm
	@ echo "\033[1;32mAssembling Game\033[0m"
	@ ca65 code.asm -o game.o -t nes
	@ echo "\033[1;34mAssembly Done\033[0m\n"
	@ echo "\033[1;32mLinking Game\033[0m"
	@ ld65 game.o -o game.nes -C nes.cfg -m game.map
	@ echo "\033[1;34mDone!\033[0m"
