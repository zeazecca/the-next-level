#if js
import js.Browser;
import js.html.InputElement;
#end

using ingot.Core;

final data: Array<Array<Float>> = [
    [-3.0, 14.81336806, 14.0, 1.807830801, 5.0],
    [-2.0, 16.22723167, 14.0, 1.98037942, 5.0],
    [-1.0, 17.77604167, 14.0, 2.169396961, 5.0],
    [0.0, 19.47267801, 14.0, 2.376455304, 5.0],
    [1.0, 21.33125, 14.0, 2.603276353, 5.0],
    [2.0, 22.53402778, 14.0, 4.515669516, 5.0],
    [3.0, 30.04097222, 14.0, 6.428062678, 5.0],
    [4.0, 32.39097222, 15.0, 8.34045584, 6.0],
    [5.0, 53.70069444, 16.0, 10.252849, 7.0],
    [6.0, 54.80069444, 16.0, 12.16524217, 7.0],
    [7.0, 56.50694444, 16.0, 14.07763533, 7.0],
    [8.0, 59.20694444, 17.0, 16.16096866, 8.0],
    [9.0, 62.99444444, 18.0, 18.09472934, 9.0],
    [10.0, 62.99444444, 18.0, 20.24216524, 9.0],
    [11.0, 79.43541667, 18.0, 22.19729345, 9.0],
    [12.0, 79.43541667, 18.0, 27.48575499, 9.0],
    [13.0, 81.87291667, 19.0, 29.71866097, 10.0],
    [14.0, 89.12916667, 19.0, 31.95156695, 10.0],
    [15.0, 91.98125, 19.0, 34.18447293, 10.0],
    [16.0, 93.78125, 19.0, 40.51994302, 10.0],
    [17.0, 127.835, 20.0, 43.00925926, 11.0],
    [18.0, 127.835, 20.0, 45.4985755, 11.0],
    [19.0, 130.11, 20.0, 52.0477208, 11.0],
    [20.0, 150.9808333, 20.0, 55.60541311, 11.0],
    [21.0, 168.8017033, 20.0, 62.16874181, 11.0],
    [22.0, 188.7260417, 20.0, 69.50676638, 11.0],
    [23.0, 211.0021291, 20.0, 77.71092726, 11.0],
    [24.0, 235.9075521, 20.0, 86.88345798, 11.0],
    [25.0, 263.7526614, 20.0, 97.13865908, 11.0],
    [26.0, 294.8844401, 20.0, 108.6043225, 11.0],
    [27.0, 329.6908268, 20.0, 121.4233238, 11.0],
    [29.0, 412.1135335, 20.0, 151.7791548, 11.0],
    [30.0, 460.7569377, 20.0, 169.6942539, 11.0]
];

final LVL: Int = 0;
final HP: Int = 1;
final AC: Int = 2;
final DMG: Int = 3;
final HIT: Int = 4;
final DEFAULT_PLAYER_HITPROB: Float = 0.6;
final DEFAULT_CREATURE_HITPROB: Float = 0.6;
final MIN_HITPROB: Float = 0.05;
final MAX_HITPROB: Float = 0.95;
final HITPROB_INCREMENTS: Float = 0.05;

function closestIndex(type: Array<Float> -> Float, target: Float): Int {
    return data.iterator()
        .indexed()
        .fold((entry, best) -> (type(entry.value) - target).abs() < (type(data[best]) - target).abs() ? entry.key : best, 0);
}

function defaultEndurance(entry: Array<Float>): Float {
    return entry[HP] / DEFAULT_PLAYER_HITPROB;
}

function defaultFerocity(entry: Array<Float>): Float {
    return entry[DMG] * DEFAULT_CREATURE_HITPROB;
}

function prod(entry: Array<Float>): Float {
    return defaultEndurance(entry) * defaultFerocity(entry);
}

function playerHitprob(entry: Array<Float>, ac: Maybe<Float>): Float {
    return ac.mapOr(ac -> (DEFAULT_PLAYER_HITPROB + (entry[AC] - ac) * HITPROB_INCREMENTS).clamp(MIN_HITPROB, MAX_HITPROB), DEFAULT_PLAYER_HITPROB);
}

function computeAcFromHp(lvlEntry: Array<Float>, endurance: Float, hp: Float) {
    return lvlEntry[AC] + (DEFAULT_PLAYER_HITPROB - (hp / endurance).clamp(MIN_HITPROB, MAX_HITPROB)) / HITPROB_INCREMENTS;
}

function computeHitFromDmg(lvlEntry: Array<Float>, ferocity: Float, dmg: Float) {
    return lvlEntry[HIT] + ((ferocity / dmg).clamp(MIN_HITPROB, MAX_HITPROB) - DEFAULT_CREATURE_HITPROB) / HITPROB_INCREMENTS;
}

function creatureHitprob(entry: Array<Float>, hit: Maybe<Float>): Float {
    return hit.mapOr(hit -> (DEFAULT_CREATURE_HITPROB + (hit - entry[HIT]) * HITPROB_INCREMENTS).clamp(MIN_HITPROB, MAX_HITPROB), DEFAULT_CREATURE_HITPROB);
}

function computeEndurance(lvlEntry: Array<Float>, hp: Maybe<Float>, ac: Maybe<Float>, dmg: Maybe<Float>, hit: Maybe<Float>): Float {
    return switch [hp, ac, dmg, hit] {
        case [Just(hp), Just(ac), _, _]: hp / playerHitprob(lvlEntry, Just(ac));
        case [_, _, Just(_), Just(_)]: prod(lvlEntry) / computeFerocity(lvlEntry, hp, ac, dmg, hit);
        case _: defaultEndurance(lvlEntry);
    }
}

function computeFerocity(lvlEntry: Array<Float>, hp: Maybe<Float>, ac: Maybe<Float>, dmg: Maybe<Float>, hit: Maybe<Float>): Float {
    return switch [hp, ac, dmg, hit] {
        case [_, _, Just(dmg), Just(hit)]: dmg * creatureHitprob(lvlEntry, Just(hit));
        case [Just(_), Just(_), _, _]: prod(lvlEntry) / computeEndurance(lvlEntry, hp, ac, dmg, hit);
        case _: defaultFerocity(lvlEntry);
    }
}

function interpolateFromLvl(lvl: Float, hp: Maybe<Float>, ac: Maybe<Float>, dmg: Maybe<Float>, hit: Maybe<Float>): Array<Float> {
    final lvlEntry = data[closestIndex(entry -> entry[LVL], lvl)];
    final endurance = computeEndurance(lvlEntry, hp, ac, dmg, hit);
    final ferocity = computeFerocity(lvlEntry, hp, ac, dmg, hit);

    final hp = hp.unwrapOrElse(() -> endurance * playerHitprob(lvlEntry, ac));
    final ac = ac.unwrapOrElse(computeAcFromHp.bind(lvlEntry, endurance, hp));
    final dmg = dmg.unwrapOrElse(() -> ferocity / creatureHitprob(lvlEntry, hit));
    final hit = hit.unwrapOrElse(computeHitFromDmg.bind(lvlEntry, ferocity, dmg));
    return [lvl, hp, ac, dmg, hit];
}

function computeProd(lvl: Float, hp: Maybe<Float>, ac: Maybe<Float>, dmg: Maybe<Float>, hit: Maybe<Float>): Float {
    final entry = data[closestIndex(entry -> entry[LVL], lvl)];
    return computeEndurance(entry, hp, ac, dmg, hit) * computeFerocity(entry, hp, ac, dmg, hit);
}

function computeLvl(lvl: Maybe<Float>, hp: Maybe<Float>, ac: Maybe<Float>, dmg: Maybe<Float>, hit: Maybe<Float>): Float {
    return switch lvl {
        case Just(lvl): lvl;
        case None:
            final idx = data.iterator()
                .indexed()
                .fold((entry, best: { idx: Int, err: Float }) -> {
                    final values = interpolateFromLvl(entry.value[LVL], hp, ac, dmg, hit);
                    final err = (HP...values.length).fold((i, acc) -> acc + (1 - values[i] / entry.value[i]).pow(2.0), 0.0);
                    err < best.err ? { idx: entry.key, err: err } : best;
                }, { idx: 0, err: Math.POSITIVE_INFINITY })
                .idx;
            data[idx][LVL];
    }
}

inline function interpolate(lvl: Maybe<Float>, hp: Maybe<Float>, ac: Maybe<Float>, dmg: Maybe<Float>, hit: Maybe<Float>): Array<Float> {
    return interpolateFromLvl(computeLvl(lvl, hp, ac, dmg, hit), hp, ac, dmg, hit);
}

#if js
class FloatAdapter {
    private final input: InputElement;

    public function new(input: InputElement) {
        this.input = input;
    }

    public function get(): Maybe<Float> {
        return input.value.toFloat();
    }

    public function set(f: Float): Void {
        input.placeholder = f.toStr(1);
    }
}

function calculator(lvl: FloatAdapter, hp: FloatAdapter, ac: FloatAdapter, dmg: FloatAdapter, hit: FloatAdapter): Void {
    final outputs = interpolate(lvl.get(), hp.get(), ac.get(), dmg.get(), hit.get());
    lvl.set(outputs[LVL]);
    hp.set(outputs[HP]);
    ac.set(outputs[AC]);
    dmg.set(outputs[DMG]);
    hit.set(outputs[HIT]);
}
#end

function main(): Void {
    #if eval
    trace(interpolate(None, Just(70), Just(12), Just(7.5), Just(12)));
    #elseif js
    final lvlInput = cast Browser.document.getElementById("level");
    final hpInput = cast Browser.document.getElementById("hp");
    final acInput = cast Browser.document.getElementById("ac");
    final dmgInput = cast Browser.document.getElementById("dmg");
    final hitInput = cast Browser.document.getElementById("hit");

    final lvl = new FloatAdapter(cast Browser.document.getElementById("level"));
    final hp = new FloatAdapter(cast Browser.document.getElementById("hp"));
    final ac = new FloatAdapter(cast Browser.document.getElementById("ac"));
    final dmg = new FloatAdapter(cast Browser.document.getElementById("dmg"));
    final hit = new FloatAdapter(cast Browser.document.getElementById("hit"));
    calculator(lvl, hp, ac, dmg, hit);

    final calculator = calculator.bind(lvl, hp, ac, dmg, hit);
    lvlInput.addEventListener("change", calculator);
    hpInput.addEventListener("change", calculator);
    acInput.addEventListener("change", calculator);
    dmgInput.addEventListener("change", calculator);
    hitInput.addEventListener("change", calculator);
    #end
}
