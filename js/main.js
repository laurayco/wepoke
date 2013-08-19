// Generated by CoffeeScript 1.6.3
(function() {
  var openUrl,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  openUrl = function(url, method) {
    var req;
    if (method == null) {
      method = 'GET';
    }
    req = typeof XMLHttpRequest !== "undefined" && XMLHttpRequest !== null ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
    req.open(method, url, true);
    return req;
  };

  this.GameLoader = (function() {
    function GameLoader(opts) {
      this.prepare = __bind(this.prepare, this);
      this.loadMap = __bind(this.loadMap, this);
      this.saveGame = __bind(this.saveGame, this);
      this.saveGameState = __bind(this.saveGameState, this);
      this.startNewGame = __bind(this.startNewGame, this);
      this.chooseSave = __bind(this.chooseSave, this);
      this.exploreGame = __bind(this.exploreGame, this);
      this._currentMode = __bind(this._currentMode, this);
      var _this = this;
      this.canvas = opts.gameCanvas;
      this.game = null;
      this.currentSave = ko.observable(null);
      this.currentSave.subscribe(function(saveObject) {
        if (saveObject !== null && _this.game === null) {
          _this.game = new GamePlay(_this.canvas, _this);
          return _this.game.play();
        }
      });
      this.availableSaves = ko.observableArray([]);
      this.gameMode = ko.observable("exploring");
      this.gameMode.subscribe(function(newValue) {
        if (_this.currentSave() === null) {
          throw {
            type: "LogicFlow",
            message: "You can't set the game mode without an active save.",
            detail: newValue
          };
        }
      });
      this.currentMode = ko.computed(this._currentMode);
      this.currentMode.subscribe(function(mode) {
        if (mode === 'loading' || mode === 'choosing') {
          return;
        }
        if (_this.currentSave() === null) {
          throw {
            type: "LogicFlow",
            message: "You can't change the game mode without an active save.",
            detail: newValue
          };
        }
      });
      this.database = new GameDatabase();
    }

    GameLoader.prototype._currentMode = function() {
      if (this.currentSave() === null) {
        if (this.availableSaves().length < 1) {
          return "loading";
        } else {
          return "choosing";
        }
      } else {
        return this.gameMode();
      }
    };

    GameLoader.prototype.exploreGame = function() {
      if (this.gameMode() !== "exploring") {
        return this.gameMode("exploring");
      }
    };

    GameLoader.prototype.chooseSave = function(saveData) {
      return this.currentSave(new GameSave(saveData));
    };

    GameLoader.prototype.startNewGame = function() {
      return this.chooseSave(this.defaultSave());
    };

    GameLoader.prototype.saveGameState = function(save, callback) {
      if (save == null) {
        save = null;
      }
      if (callback == null) {
        callback = null;
      }
      if (!(save instanceof GameSave)) {
        throw {
          type: "LogicFlow",
          message: "You can't save a game that doesn't exist.",
          detail: "An attempt to save a non-save object was made."
        };
      }
      return this.database.saveGame(save.exportForSave(), callback);
    };

    GameLoader.prototype.saveGame = function() {
      var _this = this;
      return this.saveGameState(this.currentSave(), function(errors) {
        if (errors === null) {
          return _this.exploreGame();
        } else {
          return console.log(errors);
        }
      });
    };

    GameLoader.prototype.defaultSave = function() {
      return {
        id: Date.now(),
        name: null,
        storage: [],
        roster: [],
        inventory: [],
        currency: 2000,
        location: [],
        position: {
          x: 0,
          y: 0,
          z: 0
        },
        variables: {},
        flags: []
      };
    };

    GameLoader.prototype.loadMap = function(mapID, callback) {
      var oldMode, running, _ref,
        _this = this;
      _ref = [this.game.running, this.gameMode()], running = _ref[0], oldMode = _ref[1];
      this.gameMode("loading");
      if (running) {
        this.game.pause;
      }
      return this.database.getMap(mapID, function(mapObject, errors) {
        var tileset;
        if (mapObject !== null) {
          _this.gameMode(oldMode);
          if (running) {
            _this.game.play;
          }
          tileset = new Image();
          tileset.src = "tileset/" + mapObject.tileset + ".png";
          return tileset.onload = function(event) {
            return callback(mapObject, tileset);
          };
        }
      });
    };

    GameLoader.prototype.prepare = function() {
      var _this = this;
      return this.database.prepare(function(errors) {
        var allSaves, finalizeSaves, handleSave;
        if (errors === null) {
          allSaves = [];
          handleSave = function(save) {
            return allSaves.push(save);
          };
          finalizeSaves = function() {
            if (allSaves.length > 0) {
              return _this.availableSaves(allSaves);
            } else {
              return _this.startNewGame();
            }
          };
          return _this.database.readAll("gameSaves", handleSave, finalizeSaves);
        } else {
          return console.log(errors);
        }
      });
    };

    return GameLoader;

  })();

  this.GameSave = (function() {
    function GameSave(data) {
      this.exportForSave = __bind(this.exportForSave, this);
      this.name = ko.observable(data.name);
      this.storage = ko.observableArray(data.storage);
      this.roster = ko.observableArray(data.roster);
      this.inventory = ko.observableArray(data.inventory);
      this.currency = ko.observable(data.currency);
      this.location = ko.observableArray(data.location);
      this.id = data.id;
      this.position = ko.mapping.fromJS(data.position);
      this.gender = data.gender || "m";
    }

    GameSave.prototype.exportForSave = function() {
      return {
        id: ko.utils.unwrapObservable(this.id),
        name: ko.utils.unwrapObservable(this.name),
        storage: ko.utils.unwrapObservable(this.storage),
        roster: ko.utils.unwrapObservable(this.roster),
        inventory: ko.utils.unwrapObservable(this.inventory),
        currency: ko.utils.unwrapObservable(this.currency),
        location: ko.utils.unwrapObservable(this.location),
        position: ko.mapping.toJS(this.position),
        gender: this.gender
      };
    };

    return GameSave;

  })();

  this.GameDatabase = (function() {
    function GameDatabase() {
      this.readAll = __bind(this.readAll, this);
      this.saveGame = __bind(this.saveGame, this);
      this.storeMap = __bind(this.storeMap, this);
      this.downloadMap = __bind(this.downloadMap, this);
      this.getMap = __bind(this.getMap, this);
      this.ready = __bind(this.ready, this);
    }

    GameDatabase.prototype.iddb = null;

    GameDatabase.prototype.ready = function() {
      return this.iddb !== null;
    };

    GameDatabase.prototype.prepare = function(cb) {
      var request, that, _ref,
        _this = this;
      _ref = [this, indexedDB.open("wepokedb", 2)], that = _ref[0], request = _ref[1];
      request.onupgradeneeded = this._setupDatabase;
      request.onsuccess = function(event) {
        _this.iddb = event.target.result;
        return cb(null);
      };
      return request.onerror = function(event) {
        return cb(event);
      };
    };

    GameDatabase.prototype._setupDatabase = function(event) {
      var database, mapStore, pokedexStore, saveStore;
      database = event.target.result;
      saveStore = database.createObjectStore("gameSaves", {
        keyPath: "id"
      });
      pokedexStore = database.createObjectStore("pokedex", {
        keyPath: "id"
      });
      return mapStore = database.createObjectStore("maps", {
        keyPath: "id"
      });
    };

    GameDatabase.prototype.getMap = function(id, cb) {
      var beenDone, mapStore, req, transaction, triggerDownloadMap,
        _this = this;
      transaction = this.iddb.transaction(["maps"], 'readwrite');
      mapStore = transaction.objectStore("maps");
      req = mapStore.get(id);
      beenDone = false;
      triggerDownloadMap = function() {
        if (!beenDone) {
          beenDone = true;
          return _this.downloadMap(id, function(mapObject) {
            return cb(mapObject);
          });
        }
      };
      req.onsuccess = function(event) {
        if (event.target.result != null) {
          return cb(event.target.result);
        } else {
          return triggerDownloadMap();
        }
      };
      req.onerror = function(event) {
        console.log(event);
        return triggerDownloadMap();
      };
      return null;
    };

    GameDatabase.prototype.downloadMap = function(id, cb) {
      var url,
        _this = this;
      url = openUrl("map/" + id + ".json");
      url.send();
      return url.onreadystatechange = function(event) {
        var mapObject;
        if (url.readyState === 4) {
          mapObject = JSON.parse(url.responseText);
          _this.storeMap(mapObject);
          return cb(mapObject);
        }
      };
    };

    GameDatabase.prototype.storeMap = function(map) {
      var mapStore, transaction;
      transaction = this.iddb.transaction(["maps"], 'readwrite');
      mapStore = transaction.objectStore("maps");
      return mapStore.put(map);
    };

    GameDatabase.prototype.saveGame = function(save, cb) {
      var req, saveStore, transaction;
      if (cb == null) {
        cb = null;
      }
      if (cb === null) {
        cb = function(errors) {
          return console.log(errors);
        };
      }
      transaction = this.iddb.transaction(["gameSaves"], "readwrite");
      saveStore = transaction.objectStore("gameSaves");
      req = saveStore.put(save);
      req.onerror = cb;
      return req.onsuccess = function(event) {
        return cb(null);
      };
    };

    GameDatabase.prototype.readAll = function(store, individualCallback, finalCallback) {
      var cursorRequest, transaction;
      transaction = this.iddb.transaction([store], "readwrite");
      cursorRequest = transaction.objectStore(store).openCursor();
      return cursorRequest.onsuccess = function(event) {
        if (event.target.result === null) {
          return finalCallback();
        } else {
          individualCallback(event.target.result.value);
          return event.target.result["continue"]();
        }
      };
    };

    return GameDatabase;

  })();

  this.knockoutSetup = function(settings) {
    var thing;
    thing = new GameLoader(settings);
    thing.prepare();
    ko.applyBindings(thing);
    return thing;
  };

  this.resetDatabase = function() {
    return indexedDB.deleteDatabase("wepokedb");
  };

}).call(this);
