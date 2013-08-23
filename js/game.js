// Generated by CoffeeScript 1.6.3
(function() {
  var OverworldControls,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  OverworldControls = (function() {
    var MenuHandler, MovementHandler;

    MenuHandler = (function(_super) {
      __extends(MenuHandler, _super);

      MenuHandler.minHold = 100;

      MenuHandler.openMenu = 16;

      MenuHandler.openInventory = 69;

      MenuHandler.openRoster = 81;

      function MenuHandler(syndicator, owc) {
        MenuHandler.__super__.constructor.call(this, syndicator);
        this.overworldInterface = owc;
      }

      MenuHandler.prototype.shouldHandleSignal = function(code, duration) {
        if (duration >= this.constructor.minHold) {
          return code === this.constructor.openMenu;
        } else {
          return false;
        }
      };

      MenuHandler.prototype.handleSignalOff = function(signal) {
        if (signal === this.constructor.openMenu) {
          return this.overworldInterface.openMenu();
        }
      };

      return MenuHandler;

    })(InputEventDelegater);

    MovementHandler = (function(_super) {
      __extends(MovementHandler, _super);

      MovementHandler.moveCodes = {
        65: "left",
        87: "up",
        83: "down",
        68: "right"
      };

      MovementHandler.holdRunning = 32;

      MovementHandler.minHold = 30;

      MovementHandler.prototype.direction = null;

      function MovementHandler(syndicator, owc) {
        this.endMovement = __bind(this.endMovement, this);
        this.changeMovement = __bind(this.changeMovement, this);
        this.startMovement = __bind(this.startMovement, this);
        this.handleSignalOff = __bind(this.handleSignalOff, this);
        this.handleSignalOn = __bind(this.handleSignalOn, this);
        this.shouldHandleSignal = __bind(this.shouldHandleSignal, this);
        MovementHandler.__super__.constructor.call(this, syndicator);
        this.overworldInterface = owc;
      }

      MovementHandler.prototype.shouldHandleSignal = function(code, duration) {
        return code in this.constructor.moveCodes || code === this.constructor.holdRunning;
      };

      MovementHandler.prototype.handleSignalOn = function(signal) {
        var direction;
        if (signal in this.constructor.moveCodes) {
          direction = this.constructor.moveCodes[signal];
          if (this.currentDirection === null) {
            return this.startMovement(this.constructor.moveCodes[signal]);
          } else if (this.currentDirection !== direction) {
            return this.changeMovement(this.constructor.moveCodes[signal]);
          }
        } else if (signal === this.constructor.holdRunning && !this.overworldInterface.game.heroEntity.running) {
          console.log("Now running");
          return this.overworldInterface.game.heroEntity.running = true;
        }
      };

      MovementHandler.prototype.handleSignalOff = function(signal) {
        if (signal in this.constructor.moveCodes) {
          if (this.constructor.moveCodes[signal] === this.currentDirection) {
            this.currentDirection = null;
            return this.endMovement();
          }
        } else if (signal === this.constructor.holdRunning && this.overworldInterface.game.heroEntity.running) {
          console.log("No longer running.");
          return this.overworldInterface.game.heroEntity.running = false;
        }
      };

      MovementHandler.prototype.startMovement = function(direction) {
        this.currentDirection = direction;
        return this.overworldInterface.game.heroEntity.startMoving(this.currentDirection);
      };

      MovementHandler.prototype.changeMovement = function(direction) {
        this.currentDirection = direction;
        return this.overworldInterface.game.heroEntity.changeDirection(this.currentDirection);
      };

      MovementHandler.prototype.endMovement = function() {
        return this.overworldInterface.game.heroEntity.stopMoving();
      };

      return MovementHandler;

    })(InputEventDelegater);

    function OverworldControls(player, gameInterface, game) {
      this.player = player;
      this.gameInterface = gameInterface;
      this.game = game;
      this.openMenu = __bind(this.openMenu, this);
      this.disable = __bind(this.disable, this);
      this.enable = __bind(this.enable, this);
      this.syndicator = new Syndicator();
      this.keyboard = new Keyboard(this.syndicator);
      this.menuHandler = new MenuHandler(this.syndicator, this);
      this.movementHandler = new MovementHandler(this.syndicator, this);
    }

    OverworldControls.prototype.enable = function() {
      this.menuHandler.enable();
      return this.movementHandler.enable();
    };

    OverworldControls.prototype.disable = function() {
      this.menuHandler.disable();
      return this.movementHandler.disable();
    };

    OverworldControls.prototype.openMenu = function() {
      return this.gameInterface.gameMode("saving");
    };

    return OverworldControls;

  }).call(this);

  this.OverworldEntity = (function() {
    OverworldEntity.prototype.position = {
      x: ko.observable(0),
      y: ko.observable(0)
    };

    OverworldEntity.prototype.sprite = null;

    OverworldEntity.prototype.direction = "down";

    OverworldEntity.prototype.speedMultiplier = 1.0;

    OverworldEntity.maxSpeedPeek = 3.0;

    OverworldEntity.prototype.nextStepCompletion = 0;

    OverworldEntity.prototype.running = false;

    OverworldEntity.prototype.stepTimer = null;

    function OverworldEntity(cls, mapObject, onLoad) {
      var _this = this;
      if (onLoad == null) {
        onLoad = null;
      }
      this.stopMoving = __bind(this.stopMoving, this);
      this.confirmStep = __bind(this.confirmStep, this);
      this.resetStep = __bind(this.resetStep, this);
      this.advanceStep = __bind(this.advanceStep, this);
      this.getTargetPosition = __bind(this.getTargetPosition, this);
      this.roundStep = __bind(this.roundStep, this);
      this.changeDirection = __bind(this.changeDirection, this);
      this.startMoving = __bind(this.startMoving, this);
      this.render = __bind(this.render, this);
      if (onLoad === null) {
        onLoad = function() {
          return null;
        };
      }
      this.spriteClass = cls;
      this.stepTimer = new RepeatingFunction(20, false, this.advanceStep);
      this.mapObject = mapObject;
      OverworldSprite.loadSprite(this.spriteClass, function(spr) {
        _this.sprite = spr;
        return onLoad(_this.sprite);
      });
    }

    OverworldEntity.prototype.render = function(context, tw, th) {
      return this.sprite.render(context, this.position.x(), this.position.y(), this.direction, this.nextStepCompletion, tw, th);
    };

    OverworldEntity.prototype.startMoving = function(direction) {
      this.direction = direction;
      return this.stepTimer.resume();
    };

    OverworldEntity.prototype.changeDirection = function(direction) {
      this.direction = direction;
      this.speedMultiplier = 1.0;
      return this.roundStep();
    };

    OverworldEntity.prototype.roundStep = function() {
      if (this.nextStepProgress >= 50) {
        return this.confirmStep();
      } else {
        return this.resetStep();
      }
    };

    OverworldEntity.prototype.getTargetPosition = function(cb) {
      var basePosition;
      basePosition = {
        x: this.position.x(),
        y: this.position.y()
      };
      if (this.direction === 'up') {
        basePosition.y--;
      } else if (this.direction === 'down') {
        basePosition.y++;
      } else if (this.direction === 'left') {
        basePosition.x--;
      } else if (this.direction === 'right') {
        basePosition.x++;
      }
      return cb(basePosition);
    };

    OverworldEntity.prototype.advanceStep = function() {
      var _this = this;
      this.getTargetPosition(function(targetPosition) {
        var stopMoving;
        stopMoving = function(b) {
          if (b) {
            _this.resetStep();
            return _this.stopMoving();
          }
        };
        stopMoving(targetPosition.x < 0);
        stopMoving(targetPosition.x < 0);
        stopMoving(targetPosition.y < 0);
        stopMoving(targetPosition.x >= _this.mapObject.width);
        return stopMoving(targetPosition.y >= _this.mapObject.layers[0].length / _this.mapObject.width);
      });
      this.nextStepCompletion += 10;
      if (this.nextStepCompletion >= 100) {
        return this.confirmStep();
      }
    };

    OverworldEntity.prototype.resetStep = function() {
      return this.nextStepCompletion = 0;
    };

    OverworldEntity.prototype.confirmStep = function() {
      if (this.direction === 'left') {
        this.position.x(this.position.x() - 1);
      } else if (this.direction === 'right') {
        this.position.x(this.position.x() + 1);
      } else if (this.direction === 'up') {
        this.position.y(this.position.y() - 1);
      } else if (this.direction === 'down') {
        this.position.y(this.position.y() + 1);
      }
      return this.resetStep();
    };

    OverworldEntity.prototype.stopMoving = function() {
      this.roundStep();
      this.speedMultiplier = 1.0;
      return this.stepTimer.pause();
    };

    return OverworldEntity;

  })();

  this.HeroEntity = (function(_super) {
    __extends(HeroEntity, _super);

    function HeroEntity(saveInfo, mapObject, onLoad) {
      if (onLoad == null) {
        onLoad = null;
      }
      if (onLoad === null) {
        onLoad = function() {
          return null;
        };
      }
      HeroEntity.__super__.constructor.call(this, "hero_" + saveInfo.gender, mapObject, onLoad);
      this.saveInfo = saveInfo;
      this.position = this.saveInfo.position;
    }

    return HeroEntity;

  })(OverworldEntity);

  this.OverworldSprite = (function() {
    OverworldSprite.cache = {};

    OverworldSprite.loadSprite = function(cls, cb) {
      if (cls in OverworldSprite.cache) {
        return cb(OverworldSprite.cache[cls]);
      } else {
        return new OverworldSprite(cls, function(sprite) {
          return cb(OverworldSprite.cache[cls] = sprite);
        });
      }
    };

    function OverworldSprite(overworldClass, cb) {
      var _this = this;
      this.overworldClass = overworldClass;
      this.render = __bind(this.render, this);
      this.calculateBlit = __bind(this.calculateBlit, this);
      this.image = new Image();
      this.image.src = "overworld/" + this.overworldClass + ".png";
      this.image.onload = function(event) {
        return cb(_this);
      };
    }

    OverworldSprite.prototype.calculateBlit = function(x, y, frameStep, direction, tw, th) {
      var animationFrame, blitX, blitY, spriteHeight, spriteWidth, _ref, _ref1;
      _ref = [x * tw, y * th], blitX = _ref[0], blitY = _ref[1];
      _ref1 = [parseInt(this.image.width) / 4, parseInt(this.image.height) / 3], spriteWidth = _ref1[0], spriteHeight = _ref1[1];
      if (this.image.width > tw) {
        blitX -= (spriteWidth - tw) / 2;
      }
      if (spriteHeight > th) {
        blitY -= spriteHeight - th;
      }
      animationFrame = 0;
      frameStep -= 34;
      while (frameStep > 0) {
        animationFrame += 1;
        frameStep -= 34;
      }
      if (direction === 'right') {
        blitX += Math.floor(animationFrame / 3.0 * tw);
      } else if (direction === 'left') {
        blitX -= Math.floor(animationFrame / 3.0 * tw);
      } else if (direction === 'up') {
        blitY -= Math.floor(animationFrame / 3.0 * th);
      } else if (direction === 'down') {
        blitY += Math.floor(animationFrame / 3.0 * th);
      }
      return {
        x: blitX,
        y: blitY,
        frame: animationFrame
      };
    };

    OverworldSprite.prototype.render = function(context, x, y, direction, frameStep, tw, th) {
      var animationFrame, blitX, blitY, frames, sliceX, sliceY, spriteHeight, spriteWidth, _ref, _ref1, _ref2;
      _ref = [x * tw, y * th], blitX = _ref[0], blitY = _ref[1];
      _ref1 = [parseInt(this.image.width) / 4, parseInt(this.image.height) / 3], spriteWidth = _ref1[0], spriteHeight = _ref1[1];
      if (this.image.width > tw) {
        blitX -= (spriteWidth - tw) / 2;
      }
      if (spriteHeight > th) {
        blitY -= spriteHeight - th;
      }
      animationFrame = 0;
      frameStep -= 34;
      while (frameStep > 0) {
        animationFrame += 1;
        frameStep -= 34;
      }
      if (direction === 'right') {
        blitX += Math.floor(animationFrame / 3.0 * tw);
      } else if (direction === 'left') {
        blitX -= Math.floor(animationFrame / 3.0 * tw);
      } else if (direction === 'up') {
        blitY -= Math.floor(animationFrame / 3.0 * th);
      } else if (direction === 'down') {
        blitY += Math.floor(animationFrame / 3.0 * th);
      }
      frames = {
        "down": 0,
        "up": 1,
        "left": 2,
        "right": 3
      };
      _ref2 = [frames[direction] * spriteWidth, animationFrame * spriteHeight], sliceX = _ref2[0], sliceY = _ref2[1];
      return context.drawImage(this.image, sliceX, sliceY, spriteWidth, spriteHeight, blitX, blitY, spriteWidth, spriteHeight);
    };

    return OverworldSprite;

  }).call(this);

  this.GamePlay = (function() {
    GamePlay.prototype.running = false;

    GamePlay.prototype.handle = null;

    GamePlay.tileWidth = 16;

    GamePlay.tileHeight = 16;

    function GamePlay(canvas, _interface) {
      this.canvas = canvas;
      this["interface"] = _interface;
      this.requestFrame = __bind(this.requestFrame, this);
      this.pause = __bind(this.pause, this);
      this.getTileSlice = __bind(this.getTileSlice, this);
      this.getOverworlds = __bind(this.getOverworlds, this);
      this.drawOverworlds = __bind(this.drawOverworlds, this);
      this.changePlayerMovement = __bind(this.changePlayerMovement, this);
      this.endPlayerMovement = __bind(this.endPlayerMovement, this);
      this.startPlayerMovement = __bind(this.startPlayerMovement, this);
      this.frame = __bind(this.frame, this);
      this.play = __bind(this.play, this);
      this.getSave = __bind(this.getSave, this);
      this.overworldResponse = new OverworldControls(null, this["interface"], this);
      this["interface"].currentSave();
    }

    GamePlay.prototype.getSave = function(cb) {
      return cb(this["interface"].currentSave());
    };

    GamePlay.prototype.loadedMap = null;

    GamePlay.prototype.tileset = null;

    GamePlay.prototype.heroEntity = null;

    GamePlay.prototype.play = function() {
      var allowPlay, checkBack, mapLoaded, playerLoaded, _ref,
        _this = this;
      allowPlay = function() {
        _this.running = true;
        _this.overworldResponse.enable();
        _this.requestFrame(_this.frame);
        return true;
      };
      _ref = [!(this.tileset === null || this.loadedMap === null), !this.heroEntity === null], mapLoaded = _ref[0], playerLoaded = _ref[1];
      checkBack = function() {
        if (mapLoaded && playerLoaded) {
          return allowPlay();
        } else {
          return false;
        }
      };
      if (!checkBack()) {
        if (!mapLoaded) {
          return this["interface"].loadMap(1, function(mapObject, tileset) {
            _this.loadedMap = mapObject;
            _this.tileset = tileset;
            mapLoaded = true;
            return _this.getSave(function(saveInfo) {
              return _this.heroEntity = new HeroEntity(saveInfo, _this.loadedMap, function() {
                playerLoaded = true;
                return checkBack();
              });
            });
          });
        }
      }
    };

    GamePlay.prototype.frame = function() {
      var _this = this;
      return this.getSave(function(save) {
        var blitX, blitY, cameraAdjustX, cameraAdjustY, context, frame, layer, mapx, mapy, playerPositionInfo, playerPositionX, playerPositionY, playerSpriteHeight, playerSpriteWidth, tile, tileH, tileHeight, tileW, tileWidth, tilex, tiley, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;
        _ref = [16, 32], playerSpriteWidth = _ref[0], playerSpriteHeight = _ref[1];
        _ref1 = [save.position.x(), save.position.y()], playerPositionX = _ref1[0], playerPositionY = _ref1[1];
        _ref2 = [_this.canvas.width / 2, _this.canvas.height / 2], cameraAdjustX = _ref2[0], cameraAdjustY = _ref2[1];
        _ref3 = [_this.constructor.tileWidth, _this.constructor.tileHeight], tileW = _ref3[0], tileH = _ref3[1];
        playerPositionInfo = _this.heroEntity.sprite.calculateBlit(_this.heroEntity.position.x(), _this.heroEntity.position.y(), _this.heroEntity.nextStepCompletion, _this.heroEntity.direction, tileW, tileH);
        cameraAdjustX -= playerPositionInfo.x;
        cameraAdjustY -= playerPositionInfo.y;
        context = _this.canvas.getContext("2d");
        context.clearRect(-cameraAdjustX, -cameraAdjustY, _this.canvas.width, _this.canvas.height);
        context.setTransform(1, 0, 0, 1, cameraAdjustX, cameraAdjustY);
        frame = 0;
        _ref4 = _this.loadedMap.layers;
        for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
          layer = _ref4[_i];
          _ref5 = [0, 0], mapx = _ref5[0], mapy = _ref5[1];
          for (_j = 0, _len1 = layer.length; _j < _len1; _j++) {
            tile = layer[_j];
            if (tile >= 0) {
              _ref6 = _this.getTileSlice(tile, frame), tilex = _ref6[0], tiley = _ref6[1], tileWidth = _ref6[2], tileHeight = _ref6[3];
              _ref7 = [mapx * tileWidth, mapy * tileHeight], blitX = _ref7[0], blitY = _ref7[1];
              context.drawImage(_this.tileset, tilex, tiley, tileWidth, tileHeight, blitX, blitY, tileWidth, tileHeight);
            }
            if (++mapx >= _this.loadedMap.width) {
              mapy += 1;
              mapx = 0;
            }
          }
        }
        _this.drawOverworlds(context);
        _this.requestFrame(_this.frame);
        return null;
      });
    };

    GamePlay.prototype.startPlayerMovement = function(direction) {
      return null;
    };

    GamePlay.prototype.endPlayerMovement = function() {
      return null;
    };

    GamePlay.prototype.changePlayerMovement = function(direction) {
      return null;
    };

    GamePlay.prototype.drawOverworlds = function(context) {
      var ow, _i, _len, _ref, _results;
      _ref = this.getOverworlds(true);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        ow = _ref[_i];
        _results.push(ow.render(context, this.constructor.tileWidth, this.constructor.tileHeight));
      }
      return _results;
    };

    GamePlay.prototype.getOverworlds = function(includeHero) {
      var r;
      return r = includeHero ? [this.heroEntity] : [];
    };

    GamePlay.prototype.getTileSlice = function(tileNumber) {
      return [tileNumber * this.constructor.tileWidth, 0, this.constructor.tileWidth, this.constructor.tileHeight];
    };

    GamePlay.prototype.pause = function(halt) {
      if (halt == null) {
        halt = false;
      }
      this.overworldResponse.disable();
      if (halt) {
        if (requestAnimationFrame !== null) {
          cancelRequestAnimFrame(this.handle);
        } else {
          clearTimeout(this.handle);
        }
      }
      return this.running = false;
    };

    GamePlay.prototype.requestFrame = function(cb) {
      if (requestAnimationFrame !== null) {
        return this.handle = requestAnimFrame(cb);
      } else {
        return this.handle = setTimeout(cb, 1000 / 64);
      }
    };

    return GamePlay;

  })();

}).call(this);
