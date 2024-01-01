package viewport;

import haxe.ds.GenericStack;
import ceramic.Scene;
import ceramic.Visual;
import keyson.Axis;
import keyson.Keyson.Keyboard;

class Viewport extends Scene {
	public var keyboard: Keyboard;
	public var inputMap: Input;
	public var selected: Map<Int, KeyRenderer> = [];

	// Everything inside the viewport is stored here
	var universe: Visual = new Visual();
	// This queue goes through all of the actions every frame
	// Eventually we can use this to "rewind" and undo
	var actionQueue: GenericStack<Action> = new GenericStack<Action>();
	// The square that shows where the placed key is going to be located
	var cursor: Cursor = new Cursor(unit, unit);

	// Constants
	inline static final unit = 100;
	inline static final quarterUnit = unit / 4;
	inline static final movementSpeed: Int = 1000;
	inline static final zoom = 2;
	inline static final originX: Float = 510;
	inline static final originY: Float = 60;

	// Gap between the different keys
	final gapX: Int;
	final gapY: Int;

	// UI Accessors
	public var statusBar: haxe.ui.containers.HBox;

	override public function new(keyboard: Keyboard) {
		super();

		// Initialize variables
		this.keyboard = keyboard;
		this.universe = new Visual();
		this.universe.pos(originX, originY);

		// Set the gap between the keys based on the keyson file
		gapX = Std.int((this.keyboard.keyStep[Axis.X] - this.keyboard.capSize[Axis.X]) / this.keyboard.keyStep[Axis.X] * unit);
		gapY = Std.int((this.keyboard.keyStep[Axis.Y] - this.keyboard.capSize[Axis.Y]) / this.keyboard.keyStep[Axis.Y] * unit);

		// Create cursor object
		this.cursor.create();

		// Define the inputs
		this.inputMap = new Input();
	}
	
	/**
	 * Called when scene has finished preloading
	 */
	override function create() {
		for (key in this.keyboard.keys) {
			drawKey(key);
		}
		this.add(universe);
	}

	/**
	 * Here, you can add code that will be executed at every frame
	 */
	override function update(delta: Float) {
		moveViewportCamera(delta);
		cursorUpdate();
		if (this.actionQueue.isEmpty() == false) {
			final action = this.actionQueue.pop();
			action.act();
		}
	}

	/**
	 * Handles the movement of the viewport camera/universe
	 */
	public inline function moveViewportCamera(delta: Float) {
		if (inputMap.pressed(UP)) {
			this.universe.y += movementSpeed * delta;
		}
		if (inputMap.pressed(LEFT)) {
			this.universe.x += movementSpeed * delta;
		}
		if (inputMap.pressed(DOWN)) {
			this.universe.y -= movementSpeed * delta;
		}
		if (inputMap.pressed(RIGHT)) {
			this.universe.x -= movementSpeed * delta;
		}
	}

	/**
	 * Handles the position of the cursor and key placing, removing, and other manipulations
	 */
	public function cursorUpdate() {
		// Difference between Int and Float division by 25!
		final moduloX = ((this.universe.x / 25) - Std.int(this.universe.x / 25)) * 25;
		final moduloY = ((this.universe.y / 25) - Std.int(this.universe.y / 25)) * 25;

		// The real screen coordinates we should draw our placing curor on
		final screenPosX = Std.int((screen.pointerX - unit / 2) / 25) * 25 + moduloX;
		final screenPosY = Std.int((screen.pointerY - unit / 2) / 25) * 25 + moduloY;

		// The keyson space (U/100) coordinates we should draw the to_be_placed_key on:
		final snappedPosX = (Std.int((screenPosX + unit / 2 - this.universe.x) / 25) * 25 / 100) - 0.5;
		final snappedPosY = (Std.int((screenPosY + unit / 2 - this.universe.y) / 25) * 25 / 100) - 0.5;

		// Position the cursor right on top of the keycaps
		this.cursor.pos(screenPosX - gapX / 2, screenPosY - gapY / 2); 

		// Check for key presses and queue appropriate action
		if (inputMap.justPressed(PLACE_1U)) {
			actionQueue.add(new PlaceKey(this, snappedPosX, snappedPosY));
		} else if (inputMap.justPressed(DELETE_SELECTED)) {
			actionQueue.add(new DeleteKeys(this));
		}
		
		// Adjust the status bar with the position of the cursor
		this.statusBar.findComponent("status").text = 'cursor pos: $snappedPosX x $snappedPosY';
	}

	/**
	 * Draws and adds a key to the universe
	 */
	public function drawKey(k: keyson.Keyson.Key) {
		final key: KeyRenderer = KeyMaker.createKey(this.keyboard, k, unit, this.gapX, this.gapY, this.keyboard.keysColor);
		key.pos(unit * k.position[Axis.X], unit * k.position[Axis.Y]);
		key.onPointerDown(key, (_) -> {
			if (key.border.visible) {
				selected.remove(k.keyId);
			} else {
				selected[k.keyId] = key;
			}
			key.select();
		});
		this.universe.add(key.create());

		/**
		 * A ceramic visual does not inherit the size of it's children
		 * Hence we must set it ourselves
		 * We will end up with the biggest value once the loop is over
		 */
		if (key.width + key.x > this.universe.width) {
			this.universe.width = key.width + this.gapX + key.x;
		} 

		if (key.height + key.y > this.universe.height) {
			this.universe.height = key.height + this.gapY + key.y;
		}
	}
}
