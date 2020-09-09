class FloatExtensions {
	public static inline function clamp(val:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, val));
	}
}
