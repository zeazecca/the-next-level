// Generated by Haxe 4.0.5
(function ($global) { "use strict";
function $extend(from, fields) {
	var proto = Object.create(from);
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var FloatAdapter = function(input) {
	this.input = input;
};
FloatAdapter.__name__ = true;
FloatAdapter.prototype = {
	get: function() {
		if(this.input.value.length == 0) {
			return null;
		}
		var value = parseFloat(this.input.value);
		if(value != null) {
			return value;
		}
		throw new js__$Boot_HaxeError("could not parse " + Std.string(this.input) + " as float");
	}
	,set: function(val) {
		this.input.placeholder = FloatExtensions.toString(val,1);
	}
};
var CalcResults = function(lvl,hp,ac,dmg,hit) {
	this.lvlMem = lvl;
	this.hpMem = hp;
	this.acMem = ac;
	this.dmgMem = dmg;
	this.hitMem = hit;
};
CalcResults.__name__ = true;
CalcResults.lvlEntry = function(lvl) {
	var entry = Lambda.find(Data.STATS,function(entry1) {
		return entry1.lvl == lvl;
	});
	if(entry == null) {
		throw new js__$Boot_HaxeError("level not in data table: " + lvl);
	}
	return entry;
};
CalcResults.isCloserTo = function(a,b,target) {
	return Math.abs(a - target) < Math.abs(b - target);
};
CalcResults.isSmallerAndCloserTo = function(a,b,target) {
	if(a <= target) {
		return CalcResults.isCloserTo(a,b,target);
	} else {
		return false;
	}
};
CalcResults.estimateLvlFromHp = function(hp) {
	return Lambda.fold(Data.STATS.slice(1),function(entry,best) {
		if(CalcResults.isCloserTo(entry.hp,best.hp,hp)) {
			return entry;
		} else {
			return best;
		}
	},Data.STATS[0]).lvl;
};
CalcResults.estimateLvlFromDmg = function(dmg) {
	return Lambda.fold(Data.STATS.slice(1),function(entry,best) {
		if(CalcResults.isCloserTo(entry.dmg,best.dmg,dmg)) {
			return entry;
		} else {
			return best;
		}
	},Data.STATS[0]).lvl;
};
CalcResults.playerHitProb = function(lvl,ac) {
	return FloatExtensions.clamp(0.6 - (ac - CalcResults.lvlEntry(lvl).ac) * 0.05,0.05,0.95);
};
CalcResults.creatureHitProb = function(lvl,hit) {
	return FloatExtensions.clamp(0.6 + (hit - CalcResults.lvlEntry(lvl).hit) * 0.05,0.05,0.95);
};
CalcResults.estimateLvlFromFe = function(ferocity) {
	return Lambda.fold(Data.STATS.slice(1),function(entry,best) {
		if(CalcResults.isCloserTo(entry.ferocity,best.ferocity,ferocity)) {
			return entry;
		} else {
			return best;
		}
	},Data.STATS[0]).lvl;
};
CalcResults.estimateLvlFromEn = function(endurance) {
	return Lambda.fold(Data.STATS.slice(1),function(entry,best) {
		if(CalcResults.isCloserTo(entry.endurance,best.endurance,endurance)) {
			return entry;
		} else {
			return best;
		}
	},Data.STATS[0]).lvl;
};
CalcResults.estimateLvlFromEnFe = function(endurance,ferocity) {
	var prod = endurance * ferocity;
	var lvl = Lambda.fold(Data.STATS.slice(1),function(entry,best) {
		if(CalcResults.isSmallerAndCloserTo(entry.product,best.product,prod)) {
			return entry;
		} else {
			return best;
		}
	},Data.STATS[0]).lvl;
	var adj = 0.0;
	if(lvl != Data.MAX_LVL) {
		var current = CalcResults.lvlEntry(lvl).product;
		var next = CalcResults.lvlEntry(lvl + 1).product;
		adj = (prod - current) / (next - current);
	}
	return FloatExtensions.clamp(lvl + adj,Data.MIN_LVL,Data.MAX_LVL);
};
CalcResults.acAdjustment = function(hp,endurance) {
	return (FloatExtensions.clamp(hp / endurance,0.05,0.95) - 0.6) / 0.05;
};
CalcResults.hitAdjustment = function(dmg,ferocity) {
	return (0.6 - FloatExtensions.clamp(ferocity / dmg,0.05,0.95)) / 0.05;
};
CalcResults.estimateEn = function(hp,ac,dmg,hit,lvl,lvlAdjustment) {
	if(lvlAdjustment == null) {
		lvlAdjustment = 0;
	}
	if(hp != null && ac != null) {
		lvl = lvl != null ? lvl : CalcResults.estimateLvlFromHp(hp);
		return hp / CalcResults.playerHitProb(lvl,ac);
	} else if(dmg != null && hit != null) {
		var ferocity = CalcResults.estimateFe(hp,ac,dmg,hit,lvl,lvlAdjustment);
		lvl = (lvl != null ? lvl : CalcResults.estimateLvlFromFe(ferocity)) + lvlAdjustment;
		return CalcResults.lvlEntry(lvl).product / ferocity;
	}
	lvl = (lvl != null ? lvl : Data.STATS[0].lvl) + lvlAdjustment;
	return CalcResults.lvlEntry(lvl).endurance;
};
CalcResults.estimateFe = function(hp,ac,dmg,hit,lvl,lvlAdjustment) {
	if(lvlAdjustment == null) {
		lvlAdjustment = 0;
	}
	if(dmg != null && hit != null) {
		lvl = lvl != null ? lvl : CalcResults.estimateLvlFromDmg(dmg);
		return dmg * CalcResults.creatureHitProb(lvl,hit);
	} else if(hp != null && ac != null) {
		var endurance = CalcResults.estimateEn(hp,ac,dmg,hit,lvl,lvlAdjustment);
		lvl = (lvl != null ? lvl : CalcResults.estimateLvlFromEn(endurance)) + lvlAdjustment;
		return CalcResults.lvlEntry(lvl).product / endurance;
	}
	lvl = (lvl != null ? lvl : Data.STATS[0].lvl) + lvlAdjustment;
	return CalcResults.lvlEntry(lvl).ferocity;
};
CalcResults.prototype = {
	endurance: function() {
		if(this.enMem == null) {
			return this.enMem = CalcResults.estimateEn(this.hpMem,this.acMem,this.dmgMem,this.hitMem,this.lvlMem);
		} else {
			return this.enMem;
		}
	}
	,ferocity: function() {
		if(this.feMem == null) {
			return this.feMem = CalcResults.estimateFe(this.hpMem,this.acMem,this.dmgMem,this.hitMem,this.lvlMem);
		} else {
			return this.feMem;
		}
	}
	,level: function() {
		if(this.lvlMem != null) {
			return this.lvlMem;
		}
		return CalcResults.estimateLvlFromEnFe(this.endurance(),this.ferocity());
	}
	,hp: function() {
		if(this.hpMem != null) {
			return this.hpMem;
		}
		if(this.acMem != null) {
			return this.endurance() * CalcResults.playerHitProb(FloatExtensions.iround(this.level()),this.ac());
		}
		return this.endurance() * 0.6;
	}
	,ac: function() {
		if(this.acMem != null) {
			return this.acMem;
		}
		if(this.hpMem != null) {
			return CalcResults.lvlEntry(FloatExtensions.iround(this.level())).ac - CalcResults.acAdjustment(this.hp(),this.endurance());
		}
		return CalcResults.lvlEntry(FloatExtensions.iround(this.level())).ac;
	}
	,dmg: function() {
		if(this.dmgMem != null) {
			return this.dmgMem;
		}
		if(this.hitMem != null) {
			return this.ferocity() / CalcResults.creatureHitProb(FloatExtensions.iround(this.level()),this.hitMem);
		}
		return this.ferocity() / 0.6;
	}
	,hit: function() {
		if(this.hitMem != null) {
			return this.hitMem;
		}
		if(this.dmgMem != null) {
			return CalcResults.lvlEntry(FloatExtensions.iround(this.level())).hit - CalcResults.hitAdjustment(this.dmg(),this.ferocity());
		}
		return CalcResults.lvlEntry(FloatExtensions.iround(this.level())).hit;
	}
};
var XpEntry = function(lvl,hp,ac,dmg,hit) {
	this.lvl = lvl;
	this.hp = hp;
	this.ac = ac;
	this.dmg = dmg;
	this.hit = hit;
	this.endurance = hp / 0.6;
	this.ferocity = dmg * 0.6;
	this.product = this.endurance * this.ferocity;
};
XpEntry.__name__ = true;
var Lambda = function() { };
Lambda.__name__ = true;
Lambda.fold = function(it,f,first) {
	var x = $getIterator(it);
	while(x.hasNext()) first = f(x.next(),first);
	return first;
};
Lambda.find = function(it,f) {
	var v = $getIterator(it);
	while(v.hasNext()) {
		var v1 = v.next();
		if(f(v1)) {
			return v1;
		}
	}
	return null;
};
var Data = function() { };
Data.__name__ = true;
var FloatExtensions = function() { };
FloatExtensions.__name__ = true;
FloatExtensions.clamp = function(val,min,max) {
	return Math.max(min,Math.min(max,val));
};
FloatExtensions.round = function(val,precision) {
	val *= Math.pow(10.0,precision);
	return Math.round(val) / Math.pow(10.0,precision);
};
FloatExtensions.iround = function(val) {
	return Math.round(val) | 0;
};
FloatExtensions.toString = function(val,precision) {
	return Std.string(FloatExtensions.round(val,precision));
};
var HxOverrides = function() { };
HxOverrides.__name__ = true;
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
};
var Main = function() { };
Main.__name__ = true;
Main.main = function() {
	var levelInput = window.document.getElementById("level");
	var hpInput = window.document.getElementById("hp");
	var acInput = window.document.getElementById("ac");
	var dmgInput = window.document.getElementById("dmg");
	var hitInput = window.document.getElementById("hit");
	var level = new FloatAdapter(levelInput);
	var hp = new FloatAdapter(hpInput);
	var ac = new FloatAdapter(acInput);
	var dmg = new FloatAdapter(dmgInput);
	var hit = new FloatAdapter(hitInput);
	var calc = new CalcResults(level.get() == null ? null : level.get() | 0,hp.get(),ac.get(),dmg.get(),hit.get());
	var tmp = calc.level();
	level.set(tmp);
	var tmp1 = calc.hp();
	hp.set(tmp1);
	var tmp2 = calc.ac();
	ac.set(tmp2);
	var tmp3 = calc.dmg();
	dmg.set(tmp3);
	var tmp4 = calc.hit();
	hit.set(tmp4);
	levelInput.addEventListener("change",function() {
		var lvl = level.get();
		var calc1 = hp.get();
		var calc2 = ac.get();
		var calc3 = new CalcResults(lvl == null ? null : lvl | 0,calc1,calc2,dmg.get(),hit.get());
		var tmp5 = calc3.level();
		level.set(tmp5);
		var tmp6 = calc3.hp();
		hp.set(tmp6);
		var tmp7 = calc3.ac();
		ac.set(tmp7);
		var tmp8 = calc3.dmg();
		dmg.set(tmp8);
		var tmp9 = calc3.hit();
		hit.set(tmp9);
		return;
	});
	hpInput.addEventListener("change",function() {
		var lvl1 = level.get();
		var calc4 = hp.get();
		var calc5 = ac.get();
		var calc6 = new CalcResults(lvl1 == null ? null : lvl1 | 0,calc4,calc5,dmg.get(),hit.get());
		var tmp10 = calc6.level();
		level.set(tmp10);
		var tmp11 = calc6.hp();
		hp.set(tmp11);
		var tmp12 = calc6.ac();
		ac.set(tmp12);
		var tmp13 = calc6.dmg();
		dmg.set(tmp13);
		var tmp14 = calc6.hit();
		hit.set(tmp14);
		return;
	});
	acInput.addEventListener("change",function() {
		var lvl2 = level.get();
		var calc7 = hp.get();
		var calc8 = ac.get();
		var calc9 = new CalcResults(lvl2 == null ? null : lvl2 | 0,calc7,calc8,dmg.get(),hit.get());
		var tmp15 = calc9.level();
		level.set(tmp15);
		var tmp16 = calc9.hp();
		hp.set(tmp16);
		var tmp17 = calc9.ac();
		ac.set(tmp17);
		var tmp18 = calc9.dmg();
		dmg.set(tmp18);
		var tmp19 = calc9.hit();
		hit.set(tmp19);
		return;
	});
	dmgInput.addEventListener("change",function() {
		var lvl3 = level.get();
		var calc10 = hp.get();
		var calc11 = ac.get();
		var calc12 = new CalcResults(lvl3 == null ? null : lvl3 | 0,calc10,calc11,dmg.get(),hit.get());
		var tmp20 = calc12.level();
		level.set(tmp20);
		var tmp21 = calc12.hp();
		hp.set(tmp21);
		var tmp22 = calc12.ac();
		ac.set(tmp22);
		var tmp23 = calc12.dmg();
		dmg.set(tmp23);
		var tmp24 = calc12.hit();
		hit.set(tmp24);
		return;
	});
	hitInput.addEventListener("change",function() {
		var lvl4 = level.get();
		var calc13 = hp.get();
		var calc14 = ac.get();
		var calc15 = new CalcResults(lvl4 == null ? null : lvl4 | 0,calc13,calc14,dmg.get(),hit.get());
		var tmp25 = calc15.level();
		level.set(tmp25);
		var tmp26 = calc15.hp();
		hp.set(tmp26);
		var tmp27 = calc15.ac();
		ac.set(tmp27);
		var tmp28 = calc15.dmg();
		dmg.set(tmp28);
		var tmp29 = calc15.hit();
		hit.set(tmp29);
		return;
	});
};
Math.__name__ = true;
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js_Boot.__string_rec(s,"");
};
var js__$Boot_HaxeError = function(val) {
	Error.call(this);
	this.val = val;
	if(Error.captureStackTrace) {
		Error.captureStackTrace(this,js__$Boot_HaxeError);
	}
};
js__$Boot_HaxeError.__name__ = true;
js__$Boot_HaxeError.__super__ = Error;
js__$Boot_HaxeError.prototype = $extend(Error.prototype,{
});
var js_Boot = function() { };
js_Boot.__name__ = true;
js_Boot.__string_rec = function(o,s) {
	if(o == null) {
		return "null";
	}
	if(s.length >= 5) {
		return "<...>";
	}
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) {
		t = "object";
	}
	switch(t) {
	case "function":
		return "<function>";
	case "object":
		if(((o) instanceof Array)) {
			var str = "[";
			s += "\t";
			var _g3 = 0;
			var _g11 = o.length;
			while(_g3 < _g11) {
				var i = _g3++;
				str += (i > 0 ? "," : "") + js_Boot.__string_rec(o[i],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e1 ) {
			var e2 = ((e1) instanceof js__$Boot_HaxeError) ? e1.val : e1;
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") {
				return s2;
			}
		}
		var str1 = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		var k = null;
		for( k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str1.length != 2) {
			str1 += ", \n";
		}
		str1 += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str1 += "\n" + s + "}";
		return str1;
	case "string":
		return o;
	default:
		return String(o);
	}
};
function $getIterator(o) { if( o instanceof Array ) return HxOverrides.iter(o); else return o.iterator(); }
String.__name__ = true;
Array.__name__ = true;
Object.defineProperty(js__$Boot_HaxeError.prototype,"message",{ get : function() {
	return String(this.val);
}});
js_Boot.__toStr = ({ }).toString;
Data.STATS = [new XpEntry(-3,14.81336806,14,1.807830801,5),new XpEntry(-2,16.22723167,14,1.98037942,5),new XpEntry(-1,17.77604167,14,2.169396961,5),new XpEntry(0,19.47267801,14,2.376455304,5),new XpEntry(1,21.33125,14,2.603276353,5),new XpEntry(2,22.53402778,14,4.515669516,5),new XpEntry(3,30.04097222,14,6.428062678,5),new XpEntry(4,32.39097222,15,8.34045584,6),new XpEntry(5,53.70069444,16,10.252849,7),new XpEntry(6,54.80069444,16,12.16524217,7),new XpEntry(7,56.50694444,16,14.07763533,7),new XpEntry(8,59.20694444,17,16.16096866,8),new XpEntry(9,62.99444444,18,18.09472934,9),new XpEntry(10,62.99444444,18,20.24216524,9),new XpEntry(11,79.43541667,18,22.19729345,9),new XpEntry(12,79.43541667,18,27.48575499,9),new XpEntry(13,81.87291667,19,29.71866097,10),new XpEntry(14,89.12916667,19,31.95156695,10),new XpEntry(15,91.98125,19,34.18447293,10),new XpEntry(16,93.78125,19,40.51994302,10),new XpEntry(17,127.835,20,43.00925926,11),new XpEntry(18,127.835,20,45.4985755,11),new XpEntry(19,130.11,20,52.0477208,11),new XpEntry(20,150.9808333,20,55.60541311,11),new XpEntry(21,168.8017033,20,62.16874181,11),new XpEntry(22,188.7260417,20,69.50676638,11),new XpEntry(23,211.0021291,20,77.71092726,11),new XpEntry(24,235.9075521,20,86.88345798,11),new XpEntry(25,263.7526614,20,97.13865908,11),new XpEntry(26,294.8844401,20,108.6043225,11),new XpEntry(27,329.6908268,20,121.4233238,11),new XpEntry(28,368.6055501,20,135.7554031,11),new XpEntry(29,412.1135335,20,151.7791548,11),new XpEntry(30,460.7569377,20,169.6942539,11)];
Data.MIN_LVL = Lambda.fold(Data.STATS.slice(1),function(entry,min) {
	if(entry.lvl < min.lvl) {
		return entry;
	} else {
		return min;
	}
},Data.STATS[0]).lvl;
Data.MAX_LVL = Lambda.fold(Data.STATS.slice(1),function(entry,max) {
	if(entry.lvl > max.lvl) {
		return entry;
	} else {
		return max;
	}
},Data.STATS[0]).lvl;
Main.main();
})({});