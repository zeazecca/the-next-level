import Adapter;
import js.Browser;
import js.html.InputElement;

class Main {
	static function main() {
		final levelInput:InputElement = cast Browser.document.getElementById("level");
		final hpInput:InputElement = cast Browser.document.getElementById("hp");
		final acInput:InputElement = cast Browser.document.getElementById("ac");
		final dmgInput:InputElement = cast Browser.document.getElementById("dmg");
		final hitInput:InputElement = cast Browser.document.getElementById("hit");

		final level:FloatAdapter = new FloatAdapter(levelInput);
		final hp:FloatAdapter = new FloatAdapter(hpInput);
		final ac:FloatAdapter = new FloatAdapter(acInput);
		final dmg:FloatAdapter = new FloatAdapter(dmgInput);
		final hit:FloatAdapter = new FloatAdapter(hitInput);

		final calc:CalcResults = new CalcResults(if (level.get() == null) null else Std.int(level.get()), hp.get(), ac.get(), dmg.get(), hit.get());
		level.set(calc.level());
		hp.set(calc.hp());
		ac.set(calc.ac());
		dmg.set(calc.dmg());
		hit.set(calc.hit());

		levelInput.addEventListener("change", () -> {
			final lvl:Null<Float> = level.get();
			final lvlInt:Null<Int> = if (lvl == null) null else Std.int(lvl);
			final calc:CalcResults = new CalcResults(lvlInt, hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		hpInput.addEventListener("change", () -> {
			final lvl:Null<Float> = level.get();
			final lvlInt:Null<Int> = if (lvl == null) null else Std.int(lvl);
			final calc:CalcResults = new CalcResults(lvlInt, hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		acInput.addEventListener("change", () -> {
			final lvl:Null<Float> = level.get();
			final lvlInt:Null<Int> = if (lvl == null) null else Std.int(lvl);
			final calc:CalcResults = new CalcResults(lvlInt, hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		dmgInput.addEventListener("change", () -> {
			final lvl:Null<Float> = level.get();
			final lvlInt:Null<Int> = if (lvl == null) null else Std.int(lvl);
			final calc:CalcResults = new CalcResults(lvlInt, hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		hitInput.addEventListener("change", () -> {
			final lvl:Null<Float> = level.get();
			final lvlInt:Null<Int> = if (lvl == null) null else Std.int(lvl);
			final calc:CalcResults = new CalcResults(lvlInt, hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});
	}
}
