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

	private static function isSmallerAndCloserTo(a:Float, b:Float, target:Float):Bool {
		return a <= target && isCloserTo(a, b, target);
	}

	private static function estimateLvlFromHp(hp:Float):Int {
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.hp, best.hp, hp)) entry else best, Data.DEFAULT).lvl;
	}

	private static function estimateLvlFromDmg(dmg:Float):Int {
		return Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isCloserTo(entry.dmg, best.dmg, dmg)) entry else best, Data.DEFAULT).lvl;
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
			.fold((entry, best : XpEntry) -> if (isCloserTo(entry.ferocity, best.ferocity, ferocity)) entry else best, Data.DEFAULT)
			.lvl;
	}

	private static function estimateLvlFromEn(endurance:Float):Int {
		return Data.STATS.slice(1)
			.fold((entry, best : XpEntry) -> if (isCloserTo(entry.endurance, best.endurance, endurance)) entry else best, Data.DEFAULT)
			.lvl;
	}

	private static function estimateLvlFromEnFe(endurance:Float, ferocity:Float):Float {
		final prod:Float = endurance * ferocity;
		final lvl: Int = Data.STATS.slice(1).fold((entry, best : XpEntry) -> if (isSmallerAndCloserTo(entry.product, best.product, prod)) entry else best, Data.DEFAULT).lvl;
		var adj: Float = 0.0;
		if (lvl != Data.MAX_LVL) {
			final current: Float = lvlEntry(lvl).product;
			final next: Float = lvlEntry(lvl + 1).product;
			adj = (prod - current) / (next - current);
		}
		return (lvl + adj).clamp(Data.MIN_LVL, Data.MAX_LVL);
	}

	private static function acAdjustment(hp:Float, endurance:Float):Float {
		final hitProb:Float = (hp / endurance).clamp(Data.MIN_HIT, Data.MAX_HIT);
		final hitAdjustment:Float = hitProb - Data.PLAYER_HITPROB;
		return hitAdjustment / Data.PROB_INCREMENTS;
	}

	private static function hitAdjustment(dmg:Float, ferocity:Float):Float {
		final hitProb:Float = (ferocity / dmg).clamp(Data.MIN_HIT, Data.MAX_HIT);
		final hitAdjustment:Float = Data.CREATURE_HITPROB - hitProb;
		return hitAdjustment / Data.PROB_INCREMENTS;
	}

	private static function estimateEn(hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>, lvl:Null<Int>, ?lvlAdjustment:Int = 0):Float {
		if (hp != null && ac != null) {
			lvl = (if (lvl != null) lvl else estimateLvlFromHp(hp));
			return hp / playerHitProb(lvl, ac);
		} else if (dmg != null && hit != null) {
			final ferocity:Float = estimateFe(hp, ac, dmg, hit, lvl, lvlAdjustment);
			lvl = (if (lvl != null) lvl else estimateLvlFromFe(ferocity)) + lvlAdjustment;
			return lvlEntry(lvl).product / ferocity;
		}

		lvl = (if (lvl != null) lvl else Data.DEFAULT.lvl) + lvlAdjustment;
		return lvlEntry(lvl).endurance;
	}

	private static function estimateFe(hp:Null<Float>, ac:Null<Float>, dmg:Null<Float>, hit:Null<Float>, lvl:Null<Int>, ?lvlAdjustment:Int = 0):Float {
		if (dmg != null && hit != null) {
			lvl = if (lvl != null) lvl else estimateLvlFromDmg(dmg);
			return dmg * creatureHitProb(lvl, hit);
		} else if (hp != null && ac != null) {
			final endurance:Float = estimateEn(hp, ac, dmg, hit, lvl, lvlAdjustment);
			lvl = (if (lvl != null) lvl else estimateLvlFromEn(endurance)) + lvlAdjustment;
			return lvlEntry(lvl).product / endurance;
		}

		lvl = (if (lvl != null) lvl else Data.DEFAULT.lvl) + lvlAdjustment;
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

	public function level():Float {
		if (lvlMem != null) {
			return lvlMem;
		}

		final lvlEst:Float = estimateLvlFromEnFe(endurance(), ferocity());
		return lvlEst;
	}

	public function hp():Float {
		if (hpMem != null) {
			return hpMem;
		}

		if (acMem != null) {
			return endurance() * playerHitProb(level().iround(), ac());
		}

		return endurance() * Data.PLAYER_HITPROB;
	}

	public function ac():Float {
		if (acMem != null) {
			return acMem;
		}

		if (hpMem != null) {
			return lvlEntry(level().iround()).ac - acAdjustment(hp(), endurance());
		}

		return lvlEntry(level().iround()).ac;
	}

	public function dmg():Float {
		if (dmgMem != null) {
			return dmgMem;
		}

		if (hitMem != null) {
			return ferocity() / creatureHitProb(level().iround(), hitMem);
		}

		return ferocity() / Data.CREATURE_HITPROB;
	}

	public function hit():Float {
		if (hitMem != null) {
			return hitMem;
		}

		if (dmgMem != null) {
			return lvlEntry(level().iround()).hit - hitAdjustment(dmg(), ferocity());
		}

		return lvlEntry(level().iround()).hit;
	}
}
