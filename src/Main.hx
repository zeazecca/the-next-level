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

		final level:IntAdapter = new IntAdapter(levelInput);
		final hp:RangeAdapter = new RangeAdapter(hpInput);
		final ac:FloatAdapter = new FloatAdapter(acInput);
		final dmg:RangeAdapter = new RangeAdapter(dmgInput);
		final hit:FloatAdapter = new FloatAdapter(hitInput);

		final calc:CalcResults = new CalcResults(level.get(), hp.get(), ac.get(), dmg.get(), hit.get());
		level.set(calc.level());
		hp.set(calc.hp());
		ac.set(calc.ac());
		dmg.set(calc.dmg());
		hit.set(calc.hit());

		levelInput.addEventListener("change", () -> {
			final calc:CalcResults = new CalcResults(level.get(), hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		hpInput.addEventListener("change", () -> {
			final calc:CalcResults = new CalcResults(level.get(), hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		acInput.addEventListener("change", () -> {
			final calc:CalcResults = new CalcResults(level.get(), hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		dmgInput.addEventListener("change", () -> {
			final calc:CalcResults = new CalcResults(level.get(), hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});

		hitInput.addEventListener("change", () -> {
			final calc:CalcResults = new CalcResults(level.get(), hp.get(), ac.get(), dmg.get(), hit.get());
			level.set(calc.level());
			hp.set(calc.hp());
			ac.set(calc.ac());
			dmg.set(calc.dmg());
			hit.set(calc.hit());
		});
	}
}
