package trailrenderer.shaders;

import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;

typedef TDrawData<T> =
{
	public var data:Array<T>;
	public var shaderArray:Float32Array;
	public var length:Int;
	@:optional public dynamic function changeCallback(index:Int, value:T):Void;
}

abstract DrawData<T>(TDrawData<T>)
{
	public var length(get, never):Int;
	public var changeCallback(get, set):(index:Int, value:T) -> Void;
	public var data(get, set):Array<T>;
	public var shaderArray(get, never):Float32Array;
	
	public function new(data:Array<T>, length:Int = 256)
	{
		var data:Array<T> = data ?? [];
		this = {
			data: data,
			length: length,
			shaderArray: new Float32Array(data)
		};
	}
	
	public function push(value:T):T
	{
		if (length >= this.length)
			return value;
		this.data.push(value);
		this.shaderArray[this.data.length - 1] = cast value;
		if (this.changeCallback != null)
			this.changeCallback(this.data.length - 1, value);
		return value;
	}
	
	public function remove(x:T):Bool
	{
		var index:Int = this.data.indexOf(x);
		if (index == -1)
			return false;
			
		this.data.remove(x);
		this.shaderArray[index] = cast 0;
		
		if (this.changeCallback != null)
			this.changeCallback(index, cast 0);
		return true;
	}
	
	public function clear()
	{
		this.data = [];
		this.shaderArray = new Float32Array(this.data);
		if (this.changeCallback != null)
			this.changeCallback(0, cast 0);
	}
	
	public function pop():Null<T>
	{
		var value:T = this.data.pop();
		this.shaderArray[this.data.length] = cast 0;
		if (this.changeCallback != null)
			this.changeCallback(this.data.length, cast 0);
		return value;
	}
	
	public function shift():Null<T>
	{
		var value:T = this.data.shift();
		this.shaderArray[0] = cast 0;
		if (this.changeCallback != null)
			this.changeCallback(0, cast 0);
		return value;
	}
	
	public function splice(pos:Int, len:Int):Array<T>
	{
		var value:Array<T> = this.data.splice(pos, len);
		for (i in 0...(len - pos))
			this.shaderArray[pos + i] = cast 0;
			
		if (this.changeCallback != null)
			this.changeCallback(pos, cast 0);
		return value;
	}
	
	@:from public static function fromArray<T>(data:Array<T>):DrawData<T>
		return new DrawData<T>(data);
		
	@:to public function toArray():Array<T>
		return this.data;
		
	@:arrayAccess public function get(index:Int):T
		return this.data[index] ?? cast 0;
		
	@:arrayAccess public function set(index:Int, value:T):T
	{
		if (index >= this.length)
			return value;
		this.data[index] = value;
		this.shaderArray[index] = cast value;
		if (this.changeCallback != null)
			this.changeCallback(index, value);
		return value;
	}
	
	private function get_length():Int
		return this.data.length;
		
	private function set_changeCallback(value:(index:Int, value:T) -> Void)
		return this.changeCallback = value;
		
	private function get_changeCallback():(index:Int, value:T) -> Void
		return this.changeCallback;
		
	private function get_data():Array<T>
		return this.data;
		
	private function set_data(value:Array<T>):Array<T>
	{
		this.data = value;
		this.shaderArray = new Float32Array(value);
		if (this.changeCallback != null)
			this.changeCallback(0, cast 0);
		return value;
	}
	
	private function get_shaderArray():Float32Array
		return this.shaderArray;
}
