package keys;

import ceramic.Shape;
import ceramic.Quad;
import ceramic.Border;
import viewport.Pivot;
import keyson.Axis;

/**
 * Draws a enter shaped rectangle with nice rounded corners
 */
class EnterShapedKey extends KeyRenderer {
	@content public var legendBorder: Quad;
	@content public var shape: String;
	// North is the further away member of the pair
	@content public var widthNorth: Float;
	@content public var heightNorth: Float;
	// South is the closer member of the piar
	@content public var widthSouth: Float;
	@content public var heightSouth: Float;
	@content public var offsetSouthX: Float;
	// Segments can be 1...many (10 or below is sane)
	@content public var segments: Int = 10;

	public var top: Shape;
	public var bottom: Shape;

	// we are in the 1U = 100 units of scale ratio here:
	// this is the preset for OEM/Cherry profile keycaps (TODO more presets)
	static inline var topX: Float = 100 / 8;
	static inline var topY: Float = (100 / 8) * 0.25;

	static inline var topOffset: Float = (100 / 8) * 2;
	static inline var roundedCorner: Float = (100 / 1 / 8);

	//TODO define legend snap points

	var selected: Bool = false;

	var offsetL: Float;
	var offsetR: Float;
	var offsetT: Float;
	var offsetB: Float;
	var localRadius: Float;
	var localWidth: Float;
	var localHeight: Float;

	override public function computeContent() {
		this.offsetB = heightSouth - heightNorth;
		this.offsetL = widthSouth - widthNorth;

		// TODO  There is still some oddity to fix with BEA and XT_2U
		if (this.border != null) {
			if (this.selected != null)
				this.selected = this.border.visible;
			this.border.destroy();
		}
		this.border = new Border();

		if (this.shape == 'BAE' || this.shape == 'XT_2U') {
			this.width = widthSouth;
		}
		this.border.pos(0, 0);

		if (this.heightNorth > this.heightSouth) { // north element is the narrow one?
			if (this.widthNorth > this.widthSouth) {
				this.border.size(this.widthNorth, this.heightNorth);
			} else {
				this.border.size(this.widthSouth, this.heightNorth);
			}
		} else {
			if (this.widthNorth > this.widthSouth) {
				this.border.size(this.widthNorth, this.heightSouth);
			} else {
				this.border.size(this.widthSouth, this.heightSouth);
			}
		}

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
		this.top = enterShape(widthNorth - topOffset, heightNorth - topOffset, widthSouth - topOffset, heightSouth - topOffset, topColor,
			0.0, 0.0);
		this.top.pos(topX, topY);
		this.top.depth = 5;
		this.add(this.top);
		trace('entershaped: ${this.top.x}');

		// TODO fix the size to reflect the enter shape offset(s)
		if (this.legendBorder != null) {
			this.legendBorder.destroy();
		}
		this.legendBorder = new Quad();
		this.legendBorder.pos(0 + this.legendOffset[Axis.X], 0 + this.legendOffset[Axis.Y]);
		final width = if (widthNorth - topOffset > widthSouth - topOffset) {
				widthSouth - topOffset;
			} else {
				widthNorth - topOffset;
			}
		final height = if (heightNorth - topOffset < heightSouth - topOffset) {
				heightSouth - topOffset;
			} else {
				heightNorth - topOffset;
			}

		this.legendBorder.size(width - this.legendOffset[Axis.X] * 2, height - this.legendOffset[Axis.Y] * 2);
		this.legendBorder.visible = false;
//		this.legendBorder.color = 0xFFA7F070; // sweetie-16 lime
//		this.legendBorder.depth = 6;
		// do note we referece from the top edge, not keycap bottom edge!
		this.top.add(legendBorder);

		if (this.bottom != null)
			this.bottom.destroy();
		this.bottom = enterShape(widthNorth, heightNorth, widthSouth, heightSouth, bottomColor, 0.0, 0.0);
		this.bottom.depth = 0;
		this.add(this.bottom);

		// FIXUPS and special cases:
		if (this.shape == 'BAE' || this.shape == 'XT_2U') {
			// all this swing is to get the shape to align right
			this.top.x = (widthSouth - widthNorth + topX);
			this.bottom.x = (widthSouth - widthNorth);
			
			// TODO align the pivot too
		} else if (this.shape == 'ISO') {
			// all this swing is to get the shape to align right
			this.legendBorder.x = (widthNorth - widthSouth + this.legendOffset[Axis.X]);
		}
		if (this.shape == 'XT_2U') {
			// move legends to the bottom horizontal segment
				this.legendBorder.size(widthSouth - topOffset - this.legendOffset[Axis.X] * 2, heightSouth - topOffset - this.legendOffset[Axis.Y] * 2);
				this.legendBorder.pos(widthNorth - widthSouth + this.legendOffset[Axis.X], heightNorth - heightSouth + this.legendOffset[Axis.Y]);
			}


		super.computeContent();
	}

	function enterShape(widthNorth: Float, heightNorth: Float, widthSouth: Float, heightSouth: Float, color: Int, posX: Float, posY: Float) {
		final sine = [for (angle in 0...segments + 1) Math.sin(Math.PI / 2 * angle / segments)];
		final cosine = [for (angle in 0...segments + 1) Math.cos(Math.PI / 2 * angle / segments)];

		var points = []; // re-clear the array since we are pushing only

		/**
		 * the shape has 4 corner types:
		 * +--------+
		 * |7      F|
		 * |        |
		 * |J      L|
		 * +--------+
		 * the string is picked so its feature points to an corner
		 *    +-----+
		 * 7  |7   F|
		 * +--+L    | <-the BAE case (we start counting from top leftmost corner)
		 * |J      L|
		 * +--------+
		 */

		var recipe: String = "777777"; // default is BAE
		var signumL: Array<Int> = [];
		var signumR: Array<Int> = [];
		var signumT: Array<Int> = [];
		var signumB: Array<Int> = [];

		// clockwise around we go:
		switch shape {
			case 'BAE Inverted':
				localWidth = widthNorth;
				localHeight = heightSouth;
				recipe = "7FLNLJ";
				/**
				 *        012345
				 * 7 #### F
				 *   ### NL
				 * J     L
				 */
				signumL = [0, 0, 0, 0, 0, 0];
				signumR = [0, 0, 0, -1, -1, 0];
				signumT = [0, 0, 0, 0, 0, 0];
				signumB = [0, 0, -1, -1, 0, 0];
			case 'BAE' | 'XT_2U':
				localWidth = widthSouth;
				localHeight = heightNorth;
				recipe = "7FLJZV";
				/**
				 *    7   F
				 * ZV  ##
				 * J #### L
				 */
				signumL = [0, -1, -1, -1, -1, 0];
				signumR = [0, 0, 0, 0, 0, 0];
				signumT = [0, 0, 0, 0, 0, 0];
				signumB = [0, 0, 0, 0, -1, -1];
			case 'ISO Inverted':
				localWidth = widthSouth;
				localHeight = heightNorth;
				recipe = "7FDYLJ";
				/**
				 * 7 ### F
				 *   ####DF
				 * J     L
				 */
				signumL = [0, 0, 0, 0, 0, 0];
				signumR = [0, -1, -1, 0, 0, 0];
				signumT = [0, 0, 0, 0, 0, 0];
				signumB = [0, 0, -1, -1, 0, 0];
			case 'AEK' | 'ISO':
				localWidth = widthNorth;
				localHeight = heightSouth;
				recipe = "7FLJIJ";
				/**
				 * 7 #### F
				 * J I###
				 *   J   L
				 */
				signumL = [0, 0, 0, 1, 1, 0];
				signumR = [0, 0, 0, 0, 0, 0];
				signumT = [0, 0, 0, 0, 0, 0];
				signumB = [0, 0, 0, 0, -1, -1];
		}
		this.localRadius = roundedCorner;
		size(localWidth, localHeight);

		if (recipe.length != 6) {
			throw "Recipe must be six characters long";
		}

		for (turn in 0...6) {
			switch shape {
				case 'AEK' | 'ISO' | 'BAE Inverted':
					offsetT = Math.abs(heightNorth - heightSouth) * signumT[turn]; // TODO account for gapX and gapY
					offsetB = Math.abs(heightNorth - heightSouth) * signumB[turn];
				case 'ISO Inverted' | 'BAE' | 'XT_2U': // to draw proper lower member height:
					offsetT = Math.abs(heightSouth) * signumT[turn]; // TODO account for gapX and gapY
					offsetB = Math.abs(heightSouth) * signumB[turn];
			}

			offsetL = Math.abs(widthNorth - widthSouth) * signumL[turn];
			offsetR = Math.abs(widthNorth - widthSouth) * signumR[turn];

			switch (recipe.charAt(turn)) {
				case "7":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localRadius * (1 - cosine[pointPairIndex]));
						points.push(posY + offsetT + offsetB + localRadius * (1 - sine[pointPairIndex]));
					}
				case "N":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localWidth + localRadius * (1 - cosine[segments - pointPairIndex]));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (1 - sine[segments - pointPairIndex]));
					}
				case "Z":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localRadius * (1 - cosine[pointPairIndex]));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (1 - sine[pointPairIndex]));
					}
				case "F":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localWidth + localRadius * (cosine[segments - pointPairIndex] - 1));
						points.push(posY + offsetT + offsetB + localRadius * (1 - sine[segments - pointPairIndex]));
					}
				case "Y":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localWidth + localRadius * (cosine[segments - pointPairIndex] - 1));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (1 - sine[segments - pointPairIndex]));
					}
				case "I":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localRadius * (cosine[pointPairIndex] - 1));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (1 - sine[pointPairIndex]));
					}
				case "L":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localWidth + localRadius * (cosine[pointPairIndex] - 1));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (sine[pointPairIndex] - 1));
					}
				case "V":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localRadius * (cosine[segments - pointPairIndex] - 1));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (sine[segments - pointPairIndex] - 1));
					}
				case "J":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localRadius * (1 - cosine[segments - pointPairIndex]));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (sine[segments - pointPairIndex] - 1));
					}
				case "D":
					for (pointPairIndex in 0...segments) {
						points.push(posX + offsetL + offsetR + localWidth + localRadius * (1 - cosine[pointPairIndex]));
						points.push(posY + offsetT + offsetB + localHeight + localRadius * (sine[pointPairIndex] - 1));
					}
			}
		}

		var form = new Shape();
		form.color = color;
		form.points = points;
		return form;
	}
}
