class Range {
	public final min:Float;
	public final max:Float;
	public final average:Float;

	public function new(min:Float, max:Float) {
		if (min < max) {
			this.min = min;
			this.max = max;
		} else {
			this.max = min;
			this.min = max;
		}

		this.average = (this.max + this.min) / 2.0;
	}

	public function times(factor:Float):Range {
		return new Range(min * factor, max * factor);
	}

	public function div(quotient:Float):Range {
		return new Range(min / quotient, max / quotient);
	}
}
