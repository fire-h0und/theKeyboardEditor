package keys;

import ceramic.Border;
import ceramic.RoundedRect;
import ceramic.Quad;
import viewport.Pivot;
import keyson.Axis;

class RectangularKey extends KeyRenderer {
	/**
	 * we are in the 1U = 100 units of scale ratio here:
	 * this is the preset for OEM/Cherry profile keycaps (
	 * TODO: more presets
	 */
	var topX: Float = 100 / 8;
	var topY: Float = (100 / 8) * 0.25;

	static inline var topOffset: Float = (100 / 8) * 2;
	static inline var roundedCorner: Float = 100 / 8;

	//TODO define legend snap points

//	@content public var legendCells: Quad;
	var top: RoundedRect;
	var bottom: RoundedRect;
	var selected: Bool = false;

	override public function computeContent() {
		// on recompute we clear old obsolete shapes
		if (this.border != null) {
			if (this.selected != null)
				this.selected = this.border.visible;
			this.border.destroy();
		}
		this.border = new Border();
		this.border.pos(0, 0);
		this.border.size(this.width, this.height);
		this.border.borderColor = 0xFFB13E53; // sweetie-16 red (UI theme 2ndary accent color!)
		this.border.borderPosition = MIDDLE;
		this.border.borderSize = 2;
		this.border.depth = 10;
		this.border.visible = this.selected;
		this.add(this.border);

		if (this.pivot != null)
			this.pivot.destroy();
		this.pivot = new Pivot();
		this.pivot.pos(0, 0);
		this.pivot.depth = 500; // ueber alles o/
		this.pivot.visible = this.selected;
		this.add(this.pivot);

		if (this.top != null)
			this.top.destroy();
		final top = new RoundedRect();
		top.size(width - topOffset, height - topOffset);
		top.radius(roundedCorner);
		top.color = topColor;
		top.depth = 5;
		top.pos(topX, topY);
		this.add(top);

		if (this.bottom != null)
			this.bottom.destroy();
		final bottom = new RoundedRect();
		bottom.size(width, height);
		bottom.radius(roundedCorner);
		bottom.color = bottomColor;
		bottom.depth = 0;
		bottom.pos(0, 0);
		this.add(bottom);

		if (this.legendCells != null)
			this.legendCells.destroy();

		for (index in 0...12) {
			legendCells.add(new Quad());
			//cell.pos(this.legendOffset[Axis.X], this.legendOffset[Axis.Y]);
			final X = KeyMaker.snapAtThirds (index) * top.width / 3;
			if (index < 10) {
				final Y = KeyMaker.snapAtThirds (Std.int(index / 3)) * top.height / 3;
			} else {
				// for sideprint legends snap at middle vertically and compress the height in half
				final Y = KeyMaker.snapAtThirds (Std.int(index / 3)) * top.height / 3 + (top.height + ( bottom.height - top.height )/2) ;
			}
			legendCells.items[index].anchor (KeyMaker.snapAtThirds (index), KeyMaker.snapAtThirds (Std.int(index / 3)));
			legendCells.items[index].pos (X, Y);
			legendCells.items[index].size (0.8 * top.width / 3, 0.8 * top.height / 3);
			legendCells.items[index].visible = true;
			legendCells.items[index].color = 0xFFA7F070; // sweetie-16 lime
			legendCells.items[index].depth = 6;
		}
		top.add(legendCells);

		super.computeContent();
	}
}
