package actions;

import viewport.Viewport;
import keyson.Axis;
import keyson.Keyson;

class PlaceKey extends Action {
	var placed: Keycap; // it holds all info for undo/redo
	var key: keyson.Key;
	final viewport: Viewport;
	final shape: String;
	final device: keyson.Keyboard; // the receiving unit
	final x: Float; // in 1U keyson units
	final y: Float;

	override public function new(viewport: Viewport, device: keyson.Keyboard, shape: String, x: Float, y: Float) {
		super();
		this.viewport = viewport;
		this.device = device;
		this.x = x;
		this.y = y;
		this.shape = shape;
	};

	override public function act(type: ActionType) {
		if (type != Redo) {
			// Create a new keyson key, the second shape is the legend!
			this.key = device.createKey(this.shape, [this.x, this.y], this.shape);
		} else {
			// we already store the key object on redo
			this.key = device.insertKey(this.placed.sourceKey);
		}
		// Draw and place the key
		final keycap: Keycap = KeyMaker.createKey(this.device, key, this.viewport.unit, this.viewport.gapX, this.viewport.gapY,
			Std.parseInt(this.device.defaults.keyColor));
		keycap.pos(this.viewport.unit * this.key.position[Axis.X], this.viewport.unit * this.key.position[Axis.Y]);

		keycap.component('logic', new viewport.components.KeyLogic(viewport));
		for (legend in keycap.legends) {
			legend.component('logic', new viewport.components.LegendLogic(viewport, keycap));
		}

		this.viewport.keyboard.add(keycap);
		this.placed = keycap;
		super.act(type);
	}

	override public function undo() {
		for (key in device.keys) {
			if (placed.sourceKey == key) {
				// clear keyson:
				this.device.removeKey(placed.sourceKey);
				// clear Ceramic:
				this.viewport.keyboard.remove(placed);
			}
		}
		super.undo();
	}
}
