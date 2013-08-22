@start coffee -wc js/main.coffee js/game.coffee js/input.game.coffee js/utilities.game.coffee
@start serve -p 8080
@ping 127.0.0.1
@start http://127.0.0.1:8080