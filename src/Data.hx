using Lambda;

class XpEntry {
	public final lvl:Int;
	public final hp:Float;
	public final ac:Float;
	public final dmg:Float;
	public final hit:Float;
	public final endurance:Float;
	public final ferocity:Float;
	public final product:Float;

	public function new(lvl:Int, hp:Float, ac:Float, dmg:Float, hit:Float) {
		this.lvl = lvl;
		this.hp = hp;
		this.ac = ac;
		this.dmg = dmg;
		this.hit = hit;

		endurance = hp / Data.PLAYER_HITPROB;

		// adjusting dmg for creature hit rate for a better estimate of how dangerous it is
		ferocity = dmg * Data.CREATURE_HITPROB;

		product = endurance * ferocity;
	}
}

class Data {
	public static inline final PLAYER_HITPROB:Float = 0.6;
	public static inline final CREATURE_HITPROB:Float = 0.6;
	public static inline final MIN_HIT:Float = 0.05;
	public static inline final MAX_HIT:Float = 0.95;
	public static inline final PROB_INCREMENTS:Float = 0.05;
	public static final STATS:Array<XpEntry> = [
		new XpEntry(-3, 14.81336806, 14, 1.807830801, 5), new XpEntry(-2, 16.22723167, 14, 1.98037942, 5), new XpEntry(-1, 17.77604167, 14, 2.169396961, 5),
		new XpEntry(0, 19.47267801, 14, 2.376455304, 5), new XpEntry(1, 21.33125, 14, 2.603276353, 5), new XpEntry(2, 22.53402778, 14, 4.515669516, 5),
		new XpEntry(3, 30.04097222, 14, 6.428062678, 5), new XpEntry(4, 32.39097222, 15, 8.34045584, 6), new XpEntry(5, 53.70069444, 16, 10.252849, 7),
		new XpEntry(6, 54.80069444, 16, 12.16524217, 7), new XpEntry(7, 56.50694444, 16, 14.07763533, 7), new XpEntry(8, 59.20694444, 17, 16.16096866, 8),
		new XpEntry(9, 62.99444444, 18, 18.09472934, 9), new XpEntry(10, 62.99444444, 18, 20.24216524, 9), new XpEntry(11, 79.43541667, 18, 22.19729345, 9),
		new XpEntry(12, 79.43541667, 18, 27.48575499, 9), new XpEntry(13, 81.87291667, 19, 29.71866097, 10),
		new XpEntry(14, 89.12916667, 19, 31.95156695, 10), new XpEntry(15, 91.98125, 19, 34.18447293, 10), new XpEntry(16, 93.78125, 19, 40.51994302, 10),
		new XpEntry(17, 127.835, 20, 43.00925926, 11), new XpEntry(18, 127.835, 20, 45.4985755, 11), new XpEntry(19, 130.11, 20, 52.0477208, 11),
		new XpEntry(20, 150.9808333, 20, 55.60541311, 11), new XpEntry(21, 168.8017033, 20, 62.16874181, 11),
		new XpEntry(22, 188.7260417, 20, 69.50676638, 11), new XpEntry(23, 211.0021291, 20, 77.71092726, 11),
		new XpEntry(24, 235.9075521, 20, 86.88345798, 11), new XpEntry(25, 263.7526614, 20, 97.13865908, 11),
		new XpEntry(26, 294.8844401, 20, 108.6043225, 11), new XpEntry(27, 329.6908268, 20, 121.4233238, 11),
		new XpEntry(28, 368.6055501, 20, 135.7554031,
			11), new XpEntry(29, 412.1135335, 20, 151.7791548, 11), new XpEntry(30, 460.7569377, 20, 169.6942539, 11)];
	public static final MIN_LVL:Int = Data.STATS.slice(1).fold((entry : XpEntry, min : XpEntry) -> if (entry.lvl < min.lvl) entry else min, Data.STATS[0]).lvl;
	public static final MAX_LVL:Int = Data.STATS.slice(1).fold((entry : XpEntry, max : XpEntry) -> if (entry.lvl > max.lvl) entry else max, Data.STATS[0]).lvl;
}
