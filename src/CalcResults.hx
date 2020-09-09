import Data;

using Extensions;
using Lambda;

class CalcResults {
	private static inline function lvlEntry(lvl:Int):XpEntry {
		final entry:Null<XpEntry> = Data.STATS.find((entry) -> entry.lvl == lvl);
		if (entry == null) {
			throw "level not in data table: " + lvl;
		}

		return entry;
	}

	private static inline function isCloserTo(a:Float, b:Float, target:Float):Bool {
		return Math.abs(a - target) < Math.abs(b - target);
	}

	private static inline function estimateLvlFromHp(hp:Float):Int {
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.hp, best.hp, hp)) entry else best, Data.STATS[0]).lvl;
	}

	private static inline function estimateLvlFromDmg(dmg:Float):Int {
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.dmg, best.dmg, dmg)) entry else best, Data.STATS[0]).lvl;
	}

	private static inline function playerHitProb(lvl:Int, ac:Float):Float {
		final acDiff:Float = ac - lvlEntry(lvl).ac;
		final hitDiff:Float = acDiff * Data.PROB_INCREMENTS;
		return (Data.PLAYER_HITPROB - hitDiff).clamp(Data.MIN_HIT, Data.MAX_HIT);
	}

	private static inline function creatureHitProb(lvl:Int, hit:Float):Float {
		final atkDiff:Float = hit - lvlEntry(lvl).hit;
		final hitDiff:Float = atkDiff * Data.PROB_INCREMENTS;
		return (Data.CREATURE_HITPROB + hitDiff).clamp(Data.MIN_HIT, Data.MAX_HIT);
	}

	private static inline function estimateLvlFromFe(ferocity:Float):Int {
		return Data.STATS.slice(1)
			.fold((entry, best : XpEntry) -> if (isCloserTo(entry.ferocity, best.ferocity, ferocity)) entry else best, Data.STATS[0])
			.lvl;
	}

	private static inline function estimateLvlFromEn(endurance:Float):Int {
		return Data.STATS.slice(1)
			.fold((entry, best : XpEntry) -> if (isCloserTo(entry.endurance, best.endurance, endurance)) entry else best, Data.STATS[0])
			.lvl;
	}

	private static inline function estimateLvlFromEnFe(endurance:Float, ferocity:Float):Int {
		final prod:Float = endurance * ferocity;
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.product, best.product, prod)) entry else best, Data.STATS[0]).lvl;
	}

	private static inline function acAdjustment(hp:Float, endurance:Float):Float {
		final hitProb:Float = (hp / endurance).clamp(Data.MIN_HIT, Data.MAX_HIT);
		final hitAdjustment:Float = hitProb - Data.PLAYER_HITPROB;
		return hitAdjustment / Data.PROB_INCREMENTS;
	}

	private static inline function hitAdjustment(dmg:Float, ferocity:Float):Float {
		final hitProb:Float = (ferocity / dmg).clamp(Data.MIN_HIT, Data.MAX_HIT);
		final hitAdjustment:Float = hitProb - Data.CREATURE_HITPROB;
		return hitAdjustment / Data.PROB_INCREMENTS;
	}

	private var enMem:Null<Float>;
	private var feMem:Null<Float>;
	private var lvlMem:Null<Int>;
	private var hpMem:Null<Float>;
	private var acMem:Null<Float>;
	private var dmgMem:Null<Float>;
	private var hitMem:Null<Float>;

	public function new(lvl:Null<Int>, hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>) {
		lvlMem = lvl;
		hpMem = hp;
		acMem = ac;
		dmgMem = dmg;
		hitMem = hit;
	}

	private function estimateEn():Float {
		if (hpMem != null && acMem != null) {
			final lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromHp(hpMem);
			return hpMem / playerHitProb(lvl, acMem);
		} else if (hpMem == null && dmgMem != null) {
			final lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromFe(ferocity());
			return lvlEntry(lvl).product / ferocity();
		}

		final lvl:Int = if (lvlMem != null) lvlMem else Data.STATS[0].lvl;
		return lvlEntry(lvl).endurance;
	}

	private function estimateFe():Float {
		if (dmgMem != null && hitMem != null) {
			final lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromDmg(dmgMem);
			return dmgMem * creatureHitProb(lvl, hitMem);
		} else if (dmgMem == null && hpMem != null) {
			final lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromEn(endurance());
			return lvlEntry(lvl).product / endurance();
		}

		final lvl:Int = if (lvlMem != null) lvlMem else Data.STATS[0].lvl;
		return lvlEntry(lvl).ferocity;
	}

	private function endurance():Float {
		return if (enMem == null) enMem = estimateEn() else enMem;
	}

	private function ferocity():Float {
		return if (feMem == null) feMem = estimateFe() else feMem;
	}

	public function level():Int {
		if (lvlMem != null) {
			return lvlMem;
		}

		final lvlEst:Int = estimateLvlFromEnFe(endurance(), ferocity());
		return lvlEst;
	}

	public function hp():Float {
		if (hpMem != null) {
			return hpMem;
		}

		if (acMem != null) {
			var lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromEn(endurance());
			return endurance() * playerHitProb(lvl, acMem);
		}

		return endurance() * Data.PLAYER_HITPROB;
	}

	public function ac():Float {
		if (acMem != null) {
			return acMem;
		}

		var lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromEn(endurance());
		if (hpMem != null) {
			return lvlEntry(lvl).ac - acAdjustment(hpMem, endurance());
		}

		return lvlEntry(lvl).ac;
	}

	public function dmg():Float {
		if (dmgMem != null) {
			return dmgMem;
		}

		if (hitMem != null) {
			var lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromFe(ferocity());
			return ferocity() / creatureHitProb(lvl, hitMem);
		}

		return ferocity() / Data.CREATURE_HITPROB;
	}

	public function hit():Float {
		if (hitMem != null) {
			return hitMem;
		}

		var lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromFe(ferocity());
		if (dmgMem != null) {
			return lvlEntry(lvl).hit + hitAdjustment(dmgMem, ferocity());
		}

		return lvlEntry(lvl).hit;
	}
}
