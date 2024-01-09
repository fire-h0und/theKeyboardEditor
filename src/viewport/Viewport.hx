package viewport;

import ceramic.Scene;
import ceramic.Visual;
import keyson.Axis;
import keyson.Keyson.Keyboard;
import keyson.Keyson.Key;

class Viewport extends Scene {
	public var keyboard: Keyboard;
	public var inputMap: Input;
	public var selected: Map<Key, KeyRenderer> = [];

	// Everything inside the viewport is stored here
	public var universe: Visual = new Visual();

	// This queue goes through all of the actions every frame
	// Eventually we can use this to "rewind" and undo
	var actionQueue: ActionQueue = new ActionQueue();

	// The square that shows where the placed key is going to be located
	public var cursor: Cursor = new Cursor(unit1U, unit1U);
	public var grid: Grid = new Grid(unit1U, unit1U);

	// Constants
	inline static final unit1U: Float = 100; // TODO unit1U is 1U for keyson key size
	inline static final unitFractionU: Float = Std.int(unit1U / 4); // This is the keyson placement step size
	// for some reason that eludes me setting this to anything lower than 1/5 breaks placing cursor fine alignment?
	inline static final movementSpeed: Int = 1000;
	inline static final zoom = 2;
	inline static final maxZoom = 2.0;
	inline static final minZoom = 0.25;
	inline static final zoomUnit = 1 / 32; // 1/32 is accurate enough for most zooming cases
	inline static final originX: Float = 310;
	inline static final originY: Float = 60;

	// Gap between the different keys
	final gapX: Int;
	final gapY: Int;

	override public function new(keyboard: Keyboard) {
		super();

		// Initialize variables
		this.keyboard = keyboard;
		this.universe.pos(originX, originY);

		// Set the gap between the keys based on the keyson file
		gapX = Std.int((this.keyboard.keyStep[Axis.X] - this.keyboard.capSize[Axis.X]) / this.keyboard.keyStep[Axis.X] * unit1U);
		gapY = Std.int((this.keyboard.keyStep[Axis.Y] - this.keyboard.capSize[Axis.Y]) / this.keyboard.keyStep[Axis.Y] * unit1U);

		// Create cursor object
		this.cursor.create();

		//		this.grid.offsetX = originX - gapX / 2;
		//		this.grid.offsetY = originY - gapY / 2;
		this.grid.offsetX = -gapX / 2;
		this.grid.offsetY = -gapY / 2;
		this.grid.subStepX = unitFractionU;
		this.grid.subStepY = unitFractionU;
		this.grid.create();
		this.grid.x = originX;
		this.grid.y = originY;
		//		this.grid.anchorX = originX - gapX / 2;
		//		this.grid.anchorY = originY - gapY / 2;

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
		this.actionQueue.act();
	}

	/**
	 * Handles the movement of the viewport camera/universe
	 */
	public inline function moveViewportCamera(delta: Float) {
		// temporary 1/4 unit aligned fixed stepping for good grid alignment:
		if (inputMap.pressed(UP)) {
			this.universe.y += unitFractionU * this.universe.scaleY;
			this.grid.y += unitFractionU * this.universe.scaleY;
		}
		if (inputMap.pressed(LEFT)) {
			this.universe.x += unitFractionU * this.universe.scaleX;
			this.grid.x += unitFractionU * this.universe.scaleX;
		}
		if (inputMap.pressed(DOWN)) {
			this.universe.y -= unitFractionU * this.universe.scaleY;
			this.grid.y -= unitFractionU * this.universe.scaleY;
		}
		if (inputMap.pressed(RIGHT)) {
			this.universe.x -= unitFractionU * this.universe.scaleX;
			this.grid.x -= unitFractionU * this.universe.scaleX;
		}
		/* once somebody fixes rounding errors for the gryd alignment please uncomment this and erase the above TIA
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
		 */
		// ZOOMING!
		if (inputMap.pressed(ZOOM_IN)) {
			this.universe.scaleX = if (this.universe.scaleX < maxZoom) this.universe.scaleX + zoomUnit else maxZoom; // nothing like nice predictable results
			this.universe.scaleY = if (this.universe.scaleY < maxZoom) this.universe.scaleY + zoomUnit else maxZoom;
			this.cursor.scaleX = this.universe.scaleX;
			this.cursor.scaleY = this.universe.scaleY;
			this.grid.scaleX = this.universe.scaleX;
			this.grid.scaleY = this.universe.scaleY;
			StatusBar.inform('Zoom at: ${this.universe.scaleX}');
		} else if (inputMap.pressed(ZOOM_OUT)) {
			this.universe.scaleX = if (this.universe.scaleX > minZoom) this.universe.scaleX - zoomUnit else minZoom;
			this.universe.scaleY = if (this.universe.scaleY > minZoom) this.universe.scaleY - zoomUnit else minZoom;
			this.cursor.scaleX = this.universe.scaleX;
			this.cursor.scaleY = this.universe.scaleY;
			this.grid.scaleX = this.universe.scaleX;
			this.grid.scaleY = this.universe.scaleY;
			StatusBar.inform('Zoom at: ${this.universe.scaleX}');
		}
	}

	/**
	 * Handles the position of the cursor and key placing, removing, and other manipulations
	 */
	public function cursorUpdate() {
		// presuming both our axes are scaled uniformly and in accord:
		final scale = this.universe.scaleX;
		final ScaledUnitFractionU = unitFractionU * scale;
		final scaledUnit1U = unit1U * scale;
		
		// Difference between Int and Float division by unitFractionU!
		final moduloX = (((this.universe.x / ScaledUnitFractionU) - Std.int(this.universe.x / ScaledUnitFractionU)) * ScaledUnitFractionU); // we scale the step only here!
		final moduloY = (((this.universe.y / ScaledUnitFractionU) - Std.int(this.universe.y / ScaledUnitFractionU)) * ScaledUnitFractionU); // this is in pixels

		// The real screen coordinates we should draw our placing curor on
		final screenPosX = (Std.int((screen.pointerX - scaledUnit1U / 2) / ScaledUnitFractionU) * ScaledUnitFractionU + moduloX); // this is in pixels
		final screenPosY = (Std.int((screen.pointerY - scaledUnit1U / 2) / ScaledUnitFractionU) * ScaledUnitFractionU + moduloY); // why does it work at 1:1 scale?

		// The keyson space (1U) coordinates we would draw the to_be_placed_key on:
		final snappedPosX = (Std.int((screenPosX - this.universe.x) / ScaledUnitFractionU) * ScaledUnitFractionU / scaledUnit1U);
		final snappedPosY = (Std.int((screenPosY - this.universe.y) / ScaledUnitFractionU) * ScaledUnitFractionU / scaledUnit1U);

		// Position the cursor right on top of the keycaps
		this.cursor.pos(screenPosX - gapX / 2 * scale, screenPosY - gapY / 2 * scale);

		// Check for key presses and queue appropriate action
		if (inputMap.justPressed(PLACE_1U)) { // key [p] for 1U?
			this.actionQueue.push(new PlaceKey(this, snappedPosX, snappedPosY, "1U"));
		} else if (inputMap.justPressed(PLACE_ISO)) { // key [i] for ISO?
			this.actionQueue.push(new PlaceKey(this, snappedPosX, snappedPosY, "2U"));
		} else if (inputMap.justPressed(DELETE_SELECTED)) { // key [del] for delete?
			this.actionQueue.push(new DeleteKeys(this));
		}

		if (inputMap.justPressed(UNDO)) {
			this.actionQueue.undo();
		}

		// Adjust the status bar with the position of the cursor
		StatusBar.pos(snappedPosX, snappedPosY); // can only have 2 args
	}

	/**
	 * Draws and adds a key to the universe
	 */
	public function drawKey(k: Key): Visual {
		if (this.keyboard.keys.contains(k) == false) {
			throw "Key does not exist inside the Keyson keyboard";
		}

		final key: KeyRenderer = KeyMaker.createKey(this.keyboard, k, unit1U, this.gapX, this.gapY, this.keyboard.keysColor);
		key.pos(unit1U * k.position[Axis.X], unit1U * k.position[Axis.Y]);
		key.onPointerDown(key, (_) -> {
			if (key.border.visible) {
				selected.remove(k);
				StatusBar.inform('Deselected key: "${k.legends[0].symbol}" at: ${k.position}');
			} else {
				selected[k] = key;
				StatusBar.inform('Selected key: "${k.legends[0].symbol}" at: ${k.position}');
			}
			key.select();
		});

		final createdKey = key.create();
		this.universe.add(createdKey);

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

		return createdKey;
	}
}