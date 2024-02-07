package viewport;

import keyson.Axis;
import ceramic.Color;

/*
 * Here we convert the shape-string into an actual key shape and bestow the legend(s) upon it :^]
 *
 */
class KeyMaker {
	// create a complete key with all its belonging features
	public static function createKey(keyboard: keyson.Keyson.Keyboard, k: keyson.Keyson.Key, unit: Float, gapX: Int, gapY: Int,
			color: String): KeyRenderer {
		var key: KeyRenderer;

		var width: Float;
		var height: Float;

		var stepWidth: Float = 0;
		var stepHeight: Float = 0;
		var stepOffsetX: Float = 0;
		var stepOffsetY: Float = 0;
		var stepped: Float = 0;

		var widthNorth: Float = 0;
		var heightNorth: Float = 0;
		var widthSouth: Float = 0;
		var heightSouth: Float = 0;
		var offsetSouthX: Float = 0;
		var offsetSouthY: Float = 0;

		// we convert the values into actual ceramic color
		final keyColor: Color = Std.parseInt(k.keysColor) ?? Std.parseInt(color) ?? Color.WHITE;
		final keyShadow: Color = getKeyShadow(keyColor);

		for (t in ["BAE", "ISO", "XT_2U", "AEK"]) { // the special shape cases
			if (k.shape.split(' ').indexOf(t) != -1) { // if shape found found go here
				switch k.shape {
					case "ISO":
						// Normal ISO
						widthNorth = 1.50 * unit - gapX;
						heightNorth = 1.00 * unit - gapY;
						widthSouth = 1.25 * unit - gapX;
						heightSouth = 2.00 * unit - gapY;
					case "ISO Inverted":
						// Inverted ISO
						// This is an ISO enter but with the top of the keycap reversed
						widthNorth = 1.25 * unit - gapX;
						heightNorth = 2.00 * unit - gapY;
						widthSouth = 1.50 * unit - gapX;
						heightSouth = 1.00 * unit - gapY;
					case "BAE":
						// Normal BAE
						widthNorth = 1.50 * unit - gapX;
						heightNorth = 2.00 * unit - gapY;
						widthSouth = 2.25 * unit - gapX;
						heightSouth = 1.00 * unit - gapY;
					case "BAE Inverted":
						// Inverted BAE
						widthNorth = 2.25 * unit - gapX;
						heightNorth = 1.00 * unit - gapY;
						widthSouth = 1.50 * unit - gapX;
						heightSouth = 2.00 * unit - gapY;
					case "XT_2U":
						widthNorth = 1.00 * unit - gapX;
						heightNorth = 2.00 * unit - gapY;
						widthSouth = 2.00 * unit - gapX;
						heightSouth = 1.00 * unit - gapY;
					case "AEK":
						widthNorth = 1.25 * unit - gapX;
						heightNorth = 1.00 * unit - gapY;
						widthSouth = 1.00 * unit - gapX;
						heightSouth = 2.00 * unit - gapY;
				}
			}
		}
		final keySize = Std.parseFloat(k.shape); // every valid size will get caught here
		if (Math.isNaN(keySize) == false) { // aka it is a number
			if (k.shape.split(' ').indexOf("Vertical") != -1) { // it's vertical! '<Number>U Vertical'
				// VERTICAL
				width = unit - gapX;
				height = unit * keySize - gapY;
				if (k.shape.split(' ').indexOf("Stepped") != -1) { // it's a stepped key!
					stepped = Std.parseFloat(k.shape.split('Stepped')[1]) * unit + gapX;
					if (stepped < 0) {
						// NEGATIVE
						stepOffsetY = width + stepped; // stepped is negative so this is actually subtraction!
					} else {
						stepOffsetY = 0;
					}
					stepOffsetX = 0;
					stepHeight = Math.abs(stepped);
					stepWidth = unit - gapY;
				}
			} else {
				width = unit * keySize - gapX;
				height = unit - gapY;
				if (k.shape.split(' ').indexOf("Stepped") != -1) { // it's a stepped key!
					// STEPPED
					stepped = Std.parseFloat(k.shape.split('Stepped')[1]) * unit + gapX;
					if (stepped < 0) {
						// NEGATIVE
						stepOffsetX = width + stepped; // stepped is negative so this is actually subtraction!
					} else {
						stepOffsetX = 0;
					}
					stepOffsetY = 0;
					stepWidth = Math.abs(stepped);
					stepHeight = unit - gapY;
				}
			}
			if (k.shape.split(' ').indexOf("Stepped") != -1) { // it's a stepped key!
				var stepedKey = new keys.SteppedKey();
				stepedKey.size(width, height);
				stepedKey.stepWidth = stepWidth;
				stepedKey.stepHeight = stepHeight;
				stepedKey.stepOffsetX = stepOffsetX;
				stepedKey.stepOffsetY = stepOffsetY;
				stepedKey.stepped = stepped;
				stepedKey.topColor = keyColor;
				stepedKey.bottomColor = keyShadow;
				stepedKey.sourceKey = k;
				key = stepedKey;
			} else {
				key = new keys.RectangularKey();
				key.size(width, height);
				key.topColor = keyColor;
				key.bottomColor = keyShadow;
				key.sourceKey = k;
			}
		} else { // non '<number>U' cases:
			var enterShaped = new keys.EnterShapedKey();
			enterShaped.widthNorth = widthNorth;
			enterShaped.heightNorth = heightNorth;
			enterShaped.widthSouth = widthSouth;
			enterShaped.heightSouth = heightSouth;
			enterShaped.topColor = keyColor;
			enterShaped.bottomColor = keyShadow;
			enterShaped.shape = k.shape;
			enterShaped.sourceKey = k;
			key = enterShaped;
		}

		// here we populate the legends (see function below)
		var keyLegends: Array<LegendRenderer> = KeyMaker.createLegend(keyboard, k, unit); // it is another Visual
		for (l in keyLegends) {
			key.add(l.create()); // adding it to the key visual
		}

		return key;
	}

	// create all legends on a key
	public static function createLegend(keyboard: keyson.Keyson.Keyboard, k: keyson.Keyson.Key, unit: Float): Array<LegendRenderer> {
		var keyLegends: Array<LegendRenderer> = [];
		var legendOffsetX: Float;
		var legendOffsetY: Float;

		for (l in k.legends) { // we can have many labels!
			// default to GRAY if undefined
			var legendColor = Std.parseInt(l.legendColor) ?? Std.parseInt(keyboard.legendColor) ?? Color.GRAY;
			var symbol = new LegendRenderer(l.legend, legendColor);
			// is the legend position set specifically?
			if (l.legendPosition != null) { // yes we account for individual adjustment too!
				legendOffsetX = l.legendPosition[Axis.X] + keyboard.legendPosition[Axis.X];
				legendOffsetY = l.legendPosition[Axis.Y] + keyboard.legendPosition[Axis.Y];
			} else { // no we use the global coordinates
				legendOffsetX = keyboard.legendPosition[Axis.X];
				legendOffsetY = keyboard.legendPosition[Axis.Y];
			}
			// is the fontsize set specifically?
			if (l.legendSize != 0) { // TODO make this detect per key font change
				symbol.fontSize = l.legendSize;
			} else {
				symbol.fontSize = keyboard.keyboardFontSize;
			}

			symbol.depth = 10; // make sure labels render on top
			symbol.pos(legendOffsetX + symbol.topX, legendOffsetY + symbol.topY); // relative to the key shape

			keyLegends.push(symbol);
		}

		return keyLegends;
	}

	static function getKeyShadow(color: Color): Color {
		color.lightnessHSLuv -= 0.15;
		return color;
	}
}
