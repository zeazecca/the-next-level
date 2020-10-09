class FloatExtensions {
	public static function clamp(val:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, val));
	}

	public static function toRange(val:Float):Range {
		return new Range(val, val);
	}

	public static function round(val:Float, precision:Int):Float {
		val *= Math.pow(10.0, precision);
		return Math.fround(val) / Math.pow(10.0, precision);
	}

	public static function iround(val:Float):Int {
		return Std.int(Math.round(val));
	}

	public static function toString(val:Float, precision:Int):String {
		return Std.string(round(val, precision));
	}
}
