import js.html.InputElement;
using Extensions;

class FloatAdapter  {
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

        throw 'could not parse ${input} as float';
    }

	public function set(val:Float):Void {
        input.placeholder = val.toString(1);
    }
}
