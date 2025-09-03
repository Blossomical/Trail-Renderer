package trailrenderer.shaders;

typedef TDrawData<T> =
{
	public var _self(default, null):Array<T>;
	public var data:Array<T>;
	public var length:Int;
	@:optional public dynamic function changeCallback(index:Int, value:T):Void;
}

abstract DrawData<T>(TDrawData<T>)
{
	public var length(get, never):Int;
	public var shaderArray(get, never):Array<T>;
	public var changeCallback(get, set):(index:Int, value:T) -> Void;
	public var data(get, set):Array<T>;
	
	public function new(data:Array<T>, length:Int = 256)
	{
		var data:Array<T> = data ?? [];
		this = {
			data: data,
			_self: [for (i in 0...(length + 1)) data[i] ?? cast 0],
			length: length
		};
	}
	
	public function push(value:T):T
	{
		if (length >= this.length)
			return value;
		this.data.push(value);
		this._self[this.data.length - 1] = value;
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
		if (index < this.data.length)
		{
			this._self.remove(x);
			this._self.push(cast 0);
		}
		else
			this._self[index] = cast 0;
			
		if (this.changeCallback != null)
			this.changeCallback(index, cast 0);
		return true;
	}
	
	public function clear()
	{
		this.data = [];
		for (i in 0...this.data.length)
			this._self[i] = cast 0;
		if (this.changeCallback != null)
			this.changeCallback(0, cast 0);
	}
	
	public function pop():Null<T>
	{
		this._self[this.data.length - 1] = cast 0;
		var value:T = this.data.pop();
		if (this.changeCallback != null)
			this.changeCallback(this.data.length, cast 0);
		return value;
	}
	
	public function shift():Null<T>
	{
		this._self.shift();
		this._self.push(cast 0);
		var value:T = this.data.shift();
		if (this.changeCallback != null)
			this.changeCallback(0, cast 0);
		return value;
	}
	
	public function splice(pos:Int, len:Int):Array<T>
	{
		this._self.splice(pos, len);
		while (this._self.length < this.length)
			this._self.push(cast 0);
		var value:Array<T> = this.data.splice(pos, len);
		if (this.changeCallback != null)
			this.changeCallback(pos, cast 0);
		return value;
	}
	
	@:from public static function fromArray<T>(data:Array<T>):DrawData<T>
		return new DrawData<T>(data);
		
	@:to public function toArray():Array<T>
		return this.data;
		
	@:arrayAccess public function get(index:Int):T
		return this._self[index];
		
	@:arrayAccess public function set(index:Int, value:T):T
	{
		if (index >= this.length)
			return value;
		this.data[index] = this._self[index] = value;
		if (this.changeCallback != null)
			this.changeCallback(index, value);
		return value;
	}
	
	private function get_length():Int
		return this.data.length;
		
	private function get_shaderArray():Array<T>
		return this._self;
		
	private function set_changeCallback(value:(index:Int, value:T) -> Void)
		return this.changeCallback = value;
		
	private function get_changeCallback():(index:Int, value:T) -> Void
		return this.changeCallback;
		
	private function get_data():Array<T>
		return this.data;
		
	private function set_data(value:Array<T>):Array<T>
	{
		for (i in 0...Std.int(Math.min(this.length, Math.max(this.data.length, value.length))))
			this._self[i] = value[i] ?? cast 0;
		this.data = value;
		if (this.changeCallback != null)
			this.changeCallback(0, cast 0);
		return value;
	}
}
