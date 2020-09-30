import haxe.display.Display.Package;
import Data;

using Extensions;
using Lambda;

class CalcResults {
	private static function lvlEntry(lvl:Int):XpEntry {
		final entry:Null<XpEntry> = Data.STATS.find((entry) -> entry.lvl == lvl);
		if (entry == null) {
			throw "level not in data table: " + lvl;
		}

		return entry;
	}

	private static function isCloserTo(a:Float, b:Float, target:Float):Bool {
		return Math.abs(a - target) < Math.abs(b - target);
	}

	private static function estimateLvlFromHp(hp:Float):Int {
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.hp, best.hp, hp)) entry else best, Data.STATS[0]).lvl;
	}

	private static function estimateLvlFromDmg(dmg:Float):Int {
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.dmg, best.dmg, dmg)) entry else best, Data.STATS[0]).lvl;
	}

	private static function playerHitProb(lvl:Int, ac:Float):Float {
		final acDiff:Float = ac - lvlEntry(lvl).ac;
		final hitDiff:Float = acDiff * Data.PROB_INCREMENTS;
		return (Data.PLAYER_HITPROB - hitDiff).clamp(Data.MIN_HIT, Data.MAX_HIT);
	}

	private static function creatureHitProb(lvl:Int, hit:Float):Float {
		final atkDiff:Float = hit - lvlEntry(lvl).hit;
		final hitDiff:Float = atkDiff * Data.PROB_INCREMENTS;
		return (Data.CREATURE_HITPROB + hitDiff).clamp(Data.MIN_HIT, Data.MAX_HIT);
	}

	private static function estimateLvlFromFe(ferocity:Float):Int {
		return Data.STATS.slice(1)
			.fold((entry, best : XpEntry) -> if (isCloserTo(entry.ferocity, best.ferocity, ferocity)) entry else best, Data.STATS[0])
			.lvl;
	}

	private static function estimateLvlFromEn(endurance:Float):Int {
		return Data.STATS.slice(1)
			.fold((entry, best : XpEntry) -> if (isCloserTo(entry.endurance, best.endurance, endurance)) entry else best, Data.STATS[0])
			.lvl;
	}

	private static function estimateLvlFromEnFe(endurance:Float, ferocity:Float):Int {
		final prod:Float = endurance * ferocity;
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.product, best.product, prod)) entry else best, Data.STATS[0]).lvl;
	}

	private static function acAdjustment(hp:Float, endurance:Float):Float {
		final hitProb:Float = (hp / endurance).clamp(Data.MIN_HIT, Data.MAX_HIT);
		final hitAdjustment:Float = hitProb - Data.PLAYER_HITPROB;
		return hitAdjustment / Data.PROB_INCREMENTS;
	}

	private static function hitAdjustment(dmg:Float, ferocity:Float):Float {
		final hitProb:Float = (ferocity / dmg).clamp(Data.MIN_HIT, Data.MAX_HIT);
		final hitAdjustment:Float = hitProb - Data.CREATURE_HITPROB;
		return hitAdjustment / Data.PROB_INCREMENTS;
	}

	private static function getEnduranceRange(hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>, lvl:Int):Range {
		var endurance:Float = estimateEn(hp, ac, dmg, hit, lvl);
		var dist:Float;
		if (lvl == Data.MIN_LVL) {
			final next:Float = estimateEn(hp, ac, dmg, hit, lvl, 1);
			dist = (next - endurance) / 2.0;
		} else if (lvl == Data.MAX_LVL) {
			final prev:Float = estimateEn(hp, ac, dmg, hit, lvl, -1);
			dist = (endurance - prev) / 2.0;
		} else {
			final prev:Float = estimateEn(hp, ac, dmg, hit, lvl, -1);
			final next:Float = estimateEn(hp, ac, dmg, hit, lvl, 1);
			dist = Math.min((endurance - prev) / 2.0, (next - endurance) / 2.0);
		}

		return new Range(Math.max(1.0, endurance - dist), endurance + dist);
	}

	private static function getFerocityRange(hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>, lvl:Int):Range {
		var ferocity:Float = estimateFe(hp, ac, dmg, hit, lvl);
		var dist:Float;
		if (lvl == Data.MIN_LVL) {
			final next:Float = estimateFe(hp, ac, dmg, hit, lvl, 1);
			dist = next - ferocity;
		} else if (lvl == Data.MAX_LVL) {
			final prev:Float = estimateFe(hp, ac, dmg, hit, lvl, -1);
			dist = ferocity - prev;
		} else {
			final prev:Float = estimateFe(hp, ac, dmg, hit, lvl, -1);
			final next:Float = estimateFe(hp, ac, dmg, hit, lvl, 1);
			dist = Math.min((ferocity - prev) / 2.0, (next - ferocity) / 2.0);
		}

		return new Range(Math.max(0.0, ferocity - dist), ferocity + dist);
	}

	private static function estimateEn(hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>, lvl:Null<Int>, ?lvlAdjustment:Int = 0):Float {
		if (hp != null && ac != null) {
			lvl = (if (lvl != null) lvl else estimateLvlFromHp(hp));
			return hp / playerHitProb(lvl, ac);
		} else if (hp == null && dmg != null) {
			final ferocity:Float = estimateFe(hp, ac, dmg, hit, lvl, lvlAdjustment);
			lvl = (if (lvl != null) lvl else estimateLvlFromFe(ferocity)) + lvlAdjustment;
			return lvlEntry(lvl).product / ferocity;
		}

		lvl = (if (lvl != null) lvl else Data.STATS[0].lvl) + lvlAdjustment;
		return lvlEntry(lvl).endurance;
	}

	private static function estimateFe(hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>, lvl:Null<Int>, ?lvlAdjustment:Int = 0):Float {
		if (dmg != null && hit != null) {
			lvl = if (lvl != null) lvl else estimateLvlFromDmg(dmg);
			return dmg * creatureHitProb(lvl, hit);
		} else if (dmg == null && hp != null) {
			final endurance:Float = estimateEn(hp, ac, dmg, hit, lvl, lvlAdjustment);
			lvl = (if (lvl != null) lvl else estimateLvlFromEn(endurance)) + lvlAdjustment;
			return lvlEntry(lvl).product / endurance;
		}

		lvl = (if (lvl != null) lvl else Data.STATS[0].lvl) + lvlAdjustment;
		return lvlEntry(lvl).ferocity;
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

	private function endurance():Float {
		return if (enMem == null) enMem = estimateEn(hpMem, acMem, dmgMem, hitMem, lvlMem) else enMem;
	}

	private function ferocity():Float {
		return if (feMem == null) feMem = estimateFe(hpMem, acMem, dmgMem, hitMem, lvlMem) else feMem;
	}

	public function level():Int {
		if (lvlMem != null) {
			return lvlMem;
		}

		final lvlEst:Int = estimateLvlFromEnFe(endurance(), ferocity());
		return lvlEst;
	}

	public function hp():Range {
		if (hpMem != null) {
			return hpMem.toRange();
		}

		final lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromEn(endurance());
		final endRange:Range = getEnduranceRange(hpMem, acMem, dmgMem, hitMem, lvl);

		if (acMem != null) {
			return endRange.times(playerHitProb(lvl, acMem));
		}

		return endRange.times(Data.PLAYER_HITPROB);
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

	public function dmg():Range {
		if (dmgMem != null) {
			return dmgMem.toRange();
		}

		final lvl:Int = if (lvlMem != null) lvlMem else estimateLvlFromFe(ferocity());
		final ferRange:Range = getFerocityRange(hpMem, acMem, dmgMem, hitMem, lvl);

		if (hitMem != null) {
			return ferRange.div(creatureHitProb(lvl, hitMem));
		}

		return return ferRange.div(Data.CREATURE_HITPROB);
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
