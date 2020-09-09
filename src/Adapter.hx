import js.html.InputElement;

@:generic
interface Adapter<T> {
	public function get():Null<T>;
	public function set(val:T):Void;
}

class IntAdapter implements Adapter<Int> {
    private final input: InputElement;

    public function new(input:InputElement) {
        this.input = input;
    }

	public function get():Null<Int> {
        if (input.value.length == 0) {
            return null;
        }

        final value:Null<Int> = Std.parseInt(input.value);
        if (value != null) {
            return value;
        }

        throw "could not parse " + input.value + " in " + input;
    }

	public function set(val:Int):Void {
        input.placeholder = Std.string(val);
    }
}

class FloatAdapter implements Adapter<Float> {
    private final input: InputElement;

    public function new(input:InputElement) {
        this.input = input;
    }

	public function get():Null<Float> {
        if (input.value.length == 0) {
            return null;
        }

        final value:Null<Float> = Std.parseFloat(input.value);
        if (value != null) {
            return value;
        }

        throw "could not parse " + input.value + " in " + input;
    }

	public function set(val:Float):Void {
        input.placeholder = Std.string(val);
    }
}