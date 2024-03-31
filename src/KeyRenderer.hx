package;

class KeyRenderer extends ceramic.Visual {
	@content public var topColor: ceramic.Color;
	@content public var bottomColor: ceramic.Color;
	@content public var legendOffset: Array<Float>;
	@content public var legends: Array<LegendRenderer>;
	public var legendSnapPoints: Array<Array<Float>>;

/**
 * legendSnapPoints are just like anchor points:
 * [
 * [ 0.0, 0.0], [ 0.5, 0.0], [ 1.0, 0.0],
 * [ 0.0, 0.5], [ 0.5, 0.5], [ 1.0, 0.5],
 * [ 0.0, 1.0], [ 0.5, 1.0], [ 1.0, 1.0]
 * ]
 * 
 */
	public var border: ceramic.Border;
	@content public var pivot: viewport.Pivot;
	@content public var sourceKey: keyson.Keyson.Key;

	public function select() {
		border.visible = true;
		pivot.visible = true;
	}

	// explicit deselection is sometimes unavoidable
	public function deselect() {
		border.visible = false;
		pivot.visible = false;
	}

	override public function computeContent() {
		for (l in legends) {
			l.depth = 50;
			this.add(l);
		}

		super.computeContent();
	}
}
