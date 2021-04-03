#if js
import js.Browser;
import js.html.InputElement;
#end

using ingot.ds.Option;
using ingot.Floats;
using ingot.Strings;
using Lambda;

// lvl hp ac dmg hit    ---
// lvl hp ac dmg        calc end -> fer = prod / end -> hit = dmg / fer
// lvl hp ac     hit    calc end -> fer = prod / end -> dmg = fer / hit
// lvl hp ac            calc end -> fer = prod / end -> hit = lvl default, dmg = fer / hit
// lvl hp    dmg hit    calc fer -> end = prod / fer -> ac = end / hp
// lvl hp    dmg
// lvl hp        hit
// lvl hp
// lvl    ac dmg hit    calc fer -> end = prod / fer -> hp = end * ac
// lvl    ac dmg
// lvl    ac     hit
// lvl    ac
// lvl       dmg hit    calc fer -> end = prod / fer -> ac = lvl default, hp = end * ac
// lvl       dmg
// lvl           hit
// lvl
//     hp ac dmg hit
//     hp ac dmg
//     hp ac     hit
//     hp ac            use hp to estimate lvl -> read end from table -> adjust lvl w/ ac score -> interpolate the rest
//     hp    dmg hit
//     hp    dmg
//     hp        hit
//     hp               match hp to lvl
//        ac dmg hit
//        ac dmg
//        ac     hit
//        ac            match ac to lvl
//           dmg hit    use dmg to estimate lvl -> read fer from table -> adjust lvl w/ hit score -> interpolate the rest
//           dmg        match dmg to lvl
//               hit    match hit to lvl
//                      default (lvl 1)

final data:Array<Array<Float>> = [
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

final LVL:Int = 0;
final HP:Int = 1;
final AC:Int = 2;
final DMG:Int = 3;
final HIT:Int = 4;
final DEFAULT_PLAYER_HITPROB:Float = 0.6;
final DEFAULT_CREATURE_HITPROB:Float = 0.6;
final MIN_HITPROB:Float = 0.05;
final MAX_HITPROB:Float = 0.95;
final HITPROB_INCREMENTS:Float = 0.05;

function closestIndex(type:Int,
        target:Float):Int return data.foldi((entry, bestIndex, i) -> if ((entry[type] - target).abs() < (data[bestIndex][type] - target).abs()) i else
        bestIndex,
        0);

function entryByEndurance(end:Float):Array<Float> return data.fold((entry,
        best:Array<Float>) -> if ((entry[HP] / DEFAULT_PLAYER_HITPROB - end).abs() < (best[HP] / DEFAULT_PLAYER_HITPROB - end).abs()) entry else best,
    data[0]);

function entryByFerocity(fer:Float):Array<Float> return data.fold((entry,
        best:Array<Float>) -> if ((entry[DMG] * DEFAULT_CREATURE_HITPROB - fer).abs() < (best[DMG] * DEFAULT_CREATURE_HITPROB - fer).abs()) entry else best,
    data[0]);

function lvlByProd(prod:Float):Float {
    for (index => entry in data) {
        final lvlProd = entry[HP] / DEFAULT_PLAYER_HITPROB * entry[DMG] * DEFAULT_CREATURE_HITPROB;
        switch lvlProd >= prod {
            case true if (index == 0): return entry[LVL];
            case true:
                final prevProd = data[index - 1][HP] / DEFAULT_PLAYER_HITPROB * data[index - 1][DMG] * DEFAULT_CREATURE_HITPROB;
                final range = lvlProd - prevProd;
                return data[index - 1][LVL] + (prod - prevProd) / range;
            case _:
        }
    }
    return data[data.length - 1][LVL];
}

function defaultEndurance(entry:Array<Float>):Float return entry[HP] / DEFAULT_PLAYER_HITPROB;
function defaultFerocity(entry:Array<Float>):Float return entry[DMG] * DEFAULT_CREATURE_HITPROB;
function prod(entry:Array<Float>):Float return defaultEndurance(entry) * defaultFerocity(entry);

function playerHitprob(entry:Array<Float>, ac:Option<Float>):Float return switch ac {
    case Some(ac): (DEFAULT_PLAYER_HITPROB + (entry[AC] - ac) * HITPROB_INCREMENTS).clamp(MIN_HITPROB, MAX_HITPROB);
    case None: DEFAULT_PLAYER_HITPROB;
}

function computeAcFromHp(lvlEntry:Array<Float>, endurance:Float,
        hp:Float) return lvlEntry[AC] + (DEFAULT_PLAYER_HITPROB - (hp / endurance).clamp(MIN_HITPROB, MAX_HITPROB)) / HITPROB_INCREMENTS;

function computeHitFromDmg(lvlEntry:Array<Float>, ferocity:Float,
        dmg:Float) return lvlEntry[HIT] + ((ferocity / dmg).clamp(MIN_HITPROB, MAX_HITPROB) - DEFAULT_CREATURE_HITPROB) / HITPROB_INCREMENTS;

function creatureHitprob(entry:Array<Float>, hit:Option<Float>):Float return switch hit {
    case Some(hit): (DEFAULT_CREATURE_HITPROB + (hit - entry[HIT]) * HITPROB_INCREMENTS).clamp(MIN_HITPROB, MAX_HITPROB);
    case None: DEFAULT_CREATURE_HITPROB;
}

function computeEndurance(lvlEntry:Array<Float>, hp:Option<Float>, ac:Option<Float>, dmg:Option<Float>,
        hit:Option<Float>):Float return switch [hp, ac, dmg, hit] {
        case [Some(hp), Some(ac), _, _]: hp / playerHitprob(lvlEntry, Some(ac));
        case [_, _, Some(_), Some(_)]: prod(lvlEntry) / computeFerocity(lvlEntry, hp, ac, dmg, hit);
        case _: defaultEndurance(lvlEntry);
    }

function computeFerocity(lvlEntry:Array<Float>, hp:Option<Float>, ac:Option<Float>, dmg:Option<Float>,
        hit:Option<Float>):Float return switch [hp, ac, dmg, hit] {
        case [_, _, Some(dmg), Some(hit)]: dmg * creatureHitprob(lvlEntry, Some(hit));
        case [Some(_), Some(_), _, _]: prod(lvlEntry) / computeEndurance(lvlEntry, hp, ac, dmg, hit);
        case _: defaultFerocity(lvlEntry);
    }

function interpolateFromLvl(lvl:Float, hp:Option<Float>, ac:Option<Float>, dmg:Option<Float>, hit:Option<Float>):Array<Float> {
    final lvlEntry = data[closestIndex(LVL, lvl)];
    final endurance = computeEndurance(lvlEntry, hp, ac, dmg, hit);
    final ferocity = computeFerocity(lvlEntry, hp, ac, dmg, hit);

    final hp = switch hp {
        case Some(hp): hp;
        case None: endurance * playerHitprob(lvlEntry, ac);
    }
    final ac = switch ac {
        case Some(ac): ac;
        case None: computeAcFromHp(lvlEntry, endurance, hp);
    }
    final dmg = switch dmg {
        case Some(dmg): dmg;
        case None: ferocity / creatureHitprob(lvlEntry, hit);
    }
    final hit = switch hit {
        case Some(hit): hit;
        case None: computeHitFromDmg(lvlEntry, ferocity, dmg);
    }

    return [lvl, hp, ac, dmg, hit];
}

function computeProd(estimatedLvl:Float, hp:Option<Float>, ac:Option<Float>, dmg:Option<Float>, hit:Option<Float>):Float {
    final entry = data[closestIndex(LVL, estimatedLvl)];
    final optEndurance = switch [hp, ac, dmg, hit] {
        case [Some(_), Some(_), _, _]: Some(computeEndurance(entry, hp, ac, dmg, hit));
        case [Some(hpVal), _, _, _]: Some(hpVal / DEFAULT_PLAYER_HITPROB);
        case [_, _, _, _]: None;
    }
    final optFerocity = switch [hp, ac, dmg, hit] {
        case [_, _, Some(_), Some(_)]: Some(computeFerocity(entry, hp, ac, dmg, hit));
        case [_, _, Some(dmgVal), _]: Some(dmgVal * DEFAULT_CREATURE_HITPROB);
        case [_, _, _, _]: None;
    }
    var endurance:Float;
    var ferocity:Float;
    switch [optEndurance, optFerocity] {
        case [Some(end), None]:
            endurance = end;
            ferocity = defaultFerocity(entryByEndurance(end));
        case [None, Some(fer)]:
            endurance = defaultEndurance(entryByFerocity(fer));
            ferocity = fer;
        case [None, None]:
            final entry = data[closestIndex(LVL, 1.0)];
            endurance = defaultEndurance(entry);
            ferocity = defaultFerocity(entry);
        case [Some(end), Some(fer)]:
            endurance = end;
            ferocity = fer;
    }
    return endurance * ferocity;
}

function computeLvl(lvl:Option<Float>, hp:Option<Float>, ac:Option<Float>, dmg:Option<Float>, hit:Option<Float>):Float return switch lvl {
    case Some(lvl): lvl;
    case None: lvlByProd(computeProd(1.0, hp, ac, dmg, hit));
}

inline function interpolate(lvl:Option<Float>, hp:Option<Float>, ac:Option<Float>, dmg:Option<Float>,
        hit:Option<Float>):Array<Float> return interpolateFromLvl(computeLvl(lvl, hp, ac, dmg, hit), hp, ac, dmg, hit);

#if js
class FloatAdapter {
    private final input:InputElement;

    public function new(input:InputElement) {
        this.input = input;
    }

    public function get():Option<Float> return input.value.asFloat();

    public function set(f:Float):Void input.placeholder = f.toString(1);
}

function calculator(lvl:FloatAdapter, hp:FloatAdapter, ac:FloatAdapter, dmg:FloatAdapter, hit:FloatAdapter):Void {
    final outputs = interpolate(lvl.get(), hp.get(), ac.get(), dmg.get(), hit.get());
    lvl.set(outputs[LVL]);
    hp.set(outputs[HP]);
    ac.set(outputs[AC]);
    dmg.set(outputs[DMG]);
    hit.set(outputs[HIT]);
}
#end

function main():Void {
    #if js
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
