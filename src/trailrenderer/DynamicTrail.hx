package trailrenderer;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BitmapData;
import trailrenderer.shaders.CustomGeometry;

class DynamicTrailShader extends CustomGeometry
{
	@:glFragmentSource('
        #pragma header
        uniform float offsetX;
        uniform float offsetY;
        uniform float numVertices;

        uniform bool trail_hasGradient;
        uniform sampler2D trail_gradientTexture;

		uniform bool useBrightness;
		uniform bool useDissolve;
		uniform bool useErosion;
		uniform bool useFadeAlpha;

		uniform float trail_alpha;

		uniform sampler2D erosionTexture;
		uniform float erosionOffset;
		uniform float alphaFadeOffset;

		uniform bool autoDivide;
		uniform float textureSegments;
		uniform float textureSegmentLength;

		uniform float geometry_totalLength;
		varying float segDist;
        void main() { 
            float alphaV = geometryTextureCoord.x;
			float coordU = geometryTextureCoord.x;

			if (autoDivide)
				coordU = mod(segDist, textureSegmentLength) / textureSegmentLength;
			
            gl_FragColor = flixel_texture2D(texture, vec2(mod(coordU * textureSegments, textureSegments) - offsetX, geometryTextureCoord.y - offsetY));

            if (trail_hasGradient) {
				vec2 alphaVMeasure = vec2(1.0 - alphaV, 1.0 - alphaV);
				if (useBrightness)
					if (useDissolve)
						gl_FragColor *= texture2D(trail_gradientTexture, vec2(1.0 - dot(gl_FragColor.rgb, vec3(0.299, 0.587, 0.114))) + alphaVMeasure);
					else
						gl_FragColor *= texture2D(trail_gradientTexture, vec2(1.0 - dot(gl_FragColor.rgb, vec3(0.299, 0.587, 0.114))));
				else
                	gl_FragColor *= texture2D(trail_gradientTexture, alphaVMeasure);
			}
			if (useFadeAlpha && alphaV <= (1.0 - alphaFadeOffset))
				gl_FragColor *= alphaV / (1.0 - alphaFadeOffset);
			if (useErosion)
				if (alphaV <= erosionOffset)
					gl_FragColor = mix(gl_FragColor * dot(texture2D(erosionTexture, geometryTextureCoord).rgb, vec3(0.299, 0.587, 0.114)), gl_FragColor, alphaV / erosionOffset);
        }
    ')
	public function new()
	{
		super(DynamicTrail.glVersion);
		offsetX.value = [0];
		offsetY.value = [0];
		numVertices.value = [0];
		trail_hasGradient.value = [false];
		useBrightness.value = [false];
		useFadeAlpha.value = [true];
		useDissolve.value = [false];
		useErosion.value = [false];
		erosionOffset.value = [0.8];
		alphaFadeOffset.value = [0];
		autoDivide.value = [false];
		textureSegments.value = [1];
		textureSegmentLength.value = [0];
		trail_alpha.value = [1];
		// default all values so the shader program doesn't freak out
	}
} // the shader that makes it look juicy

class DynamicTrail extends FlxSprite
{
	public static var glVersion:String = null;
	
	public var trailShader:DynamicTrailShader;
	
	/**
	 * Must be a Multiple of 2.
	 */
	public var maxVertices:Int = 256;
	
	/**
	 * aka trail size. 
	 */
	public var trailWidth:Float = 50;
	
	/**
	 * Angle of the trail in degrees 
	 */
	public var rotation(default, set):Float = 0;
	
	/**
	 * Origin / Pivot Point of the trail 
	 */
	public var trailOrigin(default, set):Array<Float> = [0, 0];
	
	/**
	 * (EXPERIMENTAL)
	 * Reduce the size of the trail before removing a segment, great for low poly trails.
	 */
	public var smoothFade:Bool = true;
	
	/**
	 * fade over time. 
	 */
	public var autoFade:Bool = true;
	
	/**
	 * Speed of the fade (autoFade must be enabled).
	 */
	public var fadeSpeed:Float = 60;
	
	/**
	 * X Offset of the trail's texture. 
	 */
	public var offsetX(default, set):Float = 0;
	
	/**
	 * Y Offset of the trail's texture. 
	 */
	public var offsetY(default, set):Float = 0;
	
	/**
	 * speed of the Automatic increment of OffsetX 
	 */
	public var offsetXScrollSpeed:Float = 0;
	
	/**
	 * speed of the Automatic increment of OffsetY 
	 */
	public var offsetYScrollSpeed:Float = 0;
	
	/**
	 * (NOT RECOMMENDED)
	 * Increase the number of segments per addPosition call therefore giving it a smoother look.
	 */
	public var smoothness:Int = 0;
	
	// styles
	
	/**
	 * Color is based on the brightness, using a grayscaled texture is recommended
	 */
	public var useBrightness(default, set):Bool = false;
	
	/**
	 * Color dissolves based on the gradient, must use useBrightness 
	 */
	public var useDissolve(default, set):Bool = false;
	
	/**
	 * Erode the texture at an offset gradually, recommended for fire trails 
	 */
	public var useErosion(default, set):Bool = false;
	
	/**
	 * Fade the alpha gradually.
	 */
	public var useFadeAlpha(default, set):Bool = true;
	
	/**
	 * the UV offset that indicates where the alpha fade will start.
	 */
	public var alphaFadeOffset(default, set):Float = 0;
	
	// erosion
	
	/**
	 * Texture to use for the erosion. 
	 */
	public var erosionTexture(default, set):BitmapData;
	
	/**
	 * the UV offset that indicates where the erosion will start.
	 */
	public var erosionOffset(default, set):Float = 0.8;
	
	// texture style
	
	/**
	 * how many segments to divide the texture into (MANUAL DIVISION).
	 */
	public var textureSegments(default, set):Int = 1; // how many segments to divide the texture into
	
	/**
	 * (EXPERIMENTAL)
	 * Highly recommended for stuff like chains, auto divide the texture based on length, textureSegmentLength must be given a value.
	 */
	public var autoDivide(default, set):Bool = false;
	
	/**
	 * Size of each segment for the auto division. 
	 */
	public var textureSegmentLength(default, set):Float = 0;
	
	/**
	 * transparency of the trail 
	 */
	public var trailAlpha(default, set):Float = 1;
	
	var lastPositionX:Null<Float>;
	var lastPositionY:Null<Float>;
	
	// var _uvtModTracker:Int = 0;
	
	public function new(trailGraphic:BitmapData, width:Float = 50, autoFade:Bool = true, fadeSpeed:Float = 60)
	{
		super();
		makeGraphic(1, 1, 0x00000000); // yes. 1 pixel.
		shader = trailShader = new DynamicTrailShader();
		trailShader.texture.input = trailGraphic;
		trailShader.texture.wrap = REPEAT;
		trailShader.autoUVT = true;
		trailShader.geometry_origin.value = trailOrigin; // link to origin
		
		trailWidth = width;
		this.autoFade = autoFade;
		this.fadeSpeed = fadeSpeed;
	}
	
	/**
	 * Add a position to the trail.
	 * The trail will automatically update its vertices, and move the trail to the specified position.
	 * If the trail has reached its maximum length, it will start removing vertices from the start of the trail.
	 * @param x
	 * @param y 
	 */
	public function addPosition(x:Float, y:Float)
	{
		if (lastPositionX != x || lastPositionY != y)
		{
			if (trailShader.vertices.length >= Math.min(maxVertices, trailShader.max_vertices) * 2)
			{
				trailShader.vertices.splice(0, 4);
				trailShader.uvtData.splice(0, 4);
			}
			
			if (lastPositionX == null)
			{
				lastPositionX = x;
				lastPositionY = y;
			}
			
			var dx:Float = x - lastPositionX;
			var dy:Float = y - lastPositionY;
			var len:Float = FlxMath.vectorLength(dx, dy);
			if (len > 0)
			{
				dx /= len;
				dy /= len;
			}
			
			if (smoothness > 0)
			{
				var olS:Int = smoothness;
				smoothness = 0;
				for (segment in 0...olS)
					addPosition(FlxMath.lerp(lastPositionX, x, segment / (smoothness + 1)), FlxMath.lerp(lastPositionY, y, segment / (smoothness + 1)));
					
				smoothness = olS;
			}
			
			trailShader.vertices.push(x - dy * trailWidth / 2);
			trailShader.vertices.push(y + dx * trailWidth / 2);
			trailShader.vertices.push(x + dy * trailWidth / 2);
			trailShader.vertices.push(y - dx * trailWidth / 2);
			
			// var u:Float = _uvtModTracker / 4;
			
			// trailShader.uvtData.push(u);
			// trailShader.uvtData.push(1);
			// trailShader.uvtData.push(u);
			// trailShader.uvtData.push(0);
			// _uvtModTracker += 4;
			// _uvtModTracker %= (maxVertices * 2);
			
			lastPositionX = x;
			lastPositionY = y;
		}
	}
	
	/**
	 * Add a position to the trail, but instead of just adding a point to the trail,
	 * it will make a drag-like effect. The trail will be stretched between the
	 * last position and the new position, creating a low poly-like, continuous trail.
	 * If the distance between the two points is greater than `distancePerTrail`,
	 * the trail will be divided into multiple points, creating a more detailed trail.
	 * @param x 
	 * @param y 
	 * @param distancePerTrail 
	 */
	public function addDragPosition(x:Float, y:Float, distancePerTrail:Float = 10)
	{
		if (lastPositionX == null || lastPositionY == null)
		{
			addPosition(x, y);
			lastPositionX = lastPositionY = null;
			addPosition(x, y);
			return;
		}
		
		var dx:Float = x - lastPositionX;
		var dy:Float = y - lastPositionY;
		var len:Float = FlxMath.vectorLength(dx, dy);
		if (len > distancePerTrail)
			addPosition(x, y);
		else
		{
			if (len > 0)
			{
				dx /= len;
				dy /= len;
			}
			
			trailShader.vertices[trailShader.vertices.length - 4] = x - dy * trailWidth / 2;
			trailShader.vertices[trailShader.vertices.length - 3] = y + dx * trailWidth / 2;
			trailShader.vertices[trailShader.vertices.length - 2] = x + dy * trailWidth / 2;
			trailShader.vertices[trailShader.vertices.length - 1] = y - dx * trailWidth / 2;
		}
	}
	
	/**
	 * Adds a quadratic bezier curve to the trail. The curve will be drawn
	 * between the points `(x1, y1)` and `(x2, y2)`, with `(controlX, controlY)`
	 * as the control point. The curve will be divided into `segments` points,
	 * which defaults to `8` if not specified.
	 * @param x1 
	 * @param y1 
	 * @param controlX 
	 * @param controlY 
	 * @param x2 
	 * @param y2 
	 * @param segments 
	 */
	public function quadraticBezier(x1:Float, y1:Float, controlX:Float, controlY:Float, x2:Float, y2:Float, segments:Int = 8)
	{
		addPosition(x1, y1);
		
		for (segment in 1...(segments + 1))
		{
			var t:Float = segment / segments;
			var x:Float = Math.pow(1 - t, 2) * x1 + 2 * (1 - t) * t * controlX + Math.pow(t, 2) * x2;
			var y:Float = Math.pow(1 - t, 2) * y1 + 2 * (1 - t) * t * controlY + Math.pow(t, 2) * y2;
			addPosition(x, y);
		}
	}
	
	/**
	 * Adds a cubic bezier curve to the trail. The curve will be drawn
	 * between the points `(x1, y1)` and `(x2, y2)`, with `(controlX1, controlY1)`
	 * and `(controlX2, controlY2)` as the control points. The curve will be divided
	 * into `segments` points, which defaults to `12` if not specified.
	 * @param x1 
	 * @param y1 
	 * @param controlX1 
	 * @param controlY1 
	 * @param controlX2 
	 * @param controlY2 
	 * @param x2 
	 * @param y2 
	 * @param segments 
	 */
	public function cubicBezier(x1:Float, y1:Float, controlX1:Float, controlY1:Float, controlX2:Float, controlY2:Float, x2:Float, y2:Float, segments:Int = 12)
	{
		addPosition(x1, y1);
		
		for (segment in 1...(segments + 1))
		{
			var t:Float = segment / segments;
			var x:Float = Math.pow(1 - t, 3) * x1
				+ 3 * Math.pow(1 - t, 2) * t * controlX1
				+ 3 * (1 - t) * Math.pow(t, 2) * controlX2
				+ Math.pow(t, 3) * x2;
			var y:Float = Math.pow(1 - t, 3) * y1
				+ 3 * Math.pow(1 - t, 2) * t * controlY1
				+ 3 * (1 - t) * Math.pow(t, 2) * controlY2
				+ Math.pow(t, 3) * y2;
				
			addPosition(x, y);
		}
	}
	
	var autoFadeTracker:Float = 0;
	var smoothFadeStart:Array<Float> = [];
	
	override public function update(elapsed:Float)
	{
		if (autoFade)
		{
			if (smoothFade)
			{
				if (autoFadeTracker >= 1)
				{
					autoFadeTracker = 0;
					trailShader.vertices.splice(0, 4);
					trailShader.uvtData.splice(0, 4);
					smoothFadeStart.pop();
				}
				else if (trailShader.vertices.length > 4)
				{
					if (smoothFadeStart.length < 4)
						for (i in 0...4)
							smoothFadeStart[i] = trailShader.vertices[i];
							
					trailShader.vertices[0] = FlxMath.lerp(smoothFadeStart[0], trailShader.vertices[4], autoFadeTracker);
					trailShader.vertices[1] = FlxMath.lerp(smoothFadeStart[1], trailShader.vertices[5], autoFadeTracker);
					trailShader.vertices[2] = FlxMath.lerp(smoothFadeStart[2], trailShader.vertices[6], autoFadeTracker);
					trailShader.vertices[3] = FlxMath.lerp(smoothFadeStart[3], trailShader.vertices[7], autoFadeTracker);
					
					autoFadeTracker += elapsed * fadeSpeed;
				}
			}
			else
			{
				if (autoFadeTracker >= (1 / fadeSpeed) && trailShader.vertices.length > 4)
				{
					autoFadeTracker = 0;
					trailShader.vertices.splice(0, 4);
					trailShader.uvtData.splice(0, 4);
				}
				else
					autoFadeTracker += elapsed;
			}
		}
		if (offsetXScrollSpeed != 0)
			offsetX += offsetXScrollSpeed * elapsed;
		if (offsetYScrollSpeed != 0)
			offsetY += offsetYScrollSpeed * elapsed;
		super.update(elapsed);
	}
	
	/**
	 * Sets the gradient of the trail.
	 * @param colors 
	 * @param rotation 
	 * @param resolution amount of colors in the gradient (default 100)
	 */
	public function setGradient(colors:Array<FlxColor>, rotation:Int = 0, resolution = 100)
	{
		var gradient:BitmapData = FlxGradient.createGradientBitmapData(resolution, resolution, colors, 1, rotation);
		trailShader.trail_gradientTexture.input = gradient;
		trailShader.trail_hasGradient.value = [true];
	}
	
	/**
	 * Removes the gradient of the trail.
	 */
	public function removeGradient()
		trailShader.trail_hasGradient.value = [false];
		
	/**
	 * Set the style of the trail.
	 * @param useBrightness 
	 * @param useFadeAlpha 
	 * @param useDissolve 
	 * @param useErosion 
	 * @param erosionTexture 
	 * @param erosionOffset 
	 * @param alphaFadeOffset 
	 */
	public function setStyle(useBrightness:Bool = false, useFadeAlpha:Bool = true, useDissolve:Bool = false, useErosion:Bool = false,
			erosionTexture:BitmapData = null, erosionOffset:Float = 0.8, alphaFadeOffset:Float = 0)
	{
		this.useDissolve = useDissolve;
		this.useFadeAlpha = useFadeAlpha;
		this.useBrightness = useBrightness;
		this.useErosion = useErosion;
		this.erosionTexture = erosionTexture;
		this.erosionOffset = erosionOffset;
		this.alphaFadeOffset = alphaFadeOffset;
	}
	
	private function set_offsetX(value:Float):Float
	{
		trailShader.offsetX.value = [value];
		return offsetX = value;
	}
	
	private function set_offsetY(value:Float):Float
	{
		trailShader.offsetY.value = [value];
		return offsetY = value;
	}
	
	private function set_useDissolve(value:Bool):Bool
	{
		trailShader.useDissolve.value = [value];
		return useDissolve = value;
	}
	
	private function set_useFadeAlpha(value:Bool):Bool
	{
		trailShader.useFadeAlpha.value = [value];
		return useFadeAlpha = value;
	}
	
	private function set_useBrightness(value:Bool):Bool
	{
		trailShader.useBrightness.value = [value];
		return useBrightness = value;
	}
	
	private function set_rotation(value:Float):Float
	{
		trailShader.rotate(value * Math.PI / 180);
		return rotation = value;
	}
	
	private function set_trailOrigin(value:Array<Float>):Array<Float>
	{
		trailOrigin[0] = value[0];
		trailOrigin[1] = value[1];
		return value;
	}
	
	private function set_erosionTexture(value:BitmapData):BitmapData
	{
		trailShader.erosionTexture.input = value;
		return erosionTexture = value;
	}
	
	private function set_erosionOffset(value:Float):Float
	{
		trailShader.erosionOffset.value = [value];
		return erosionOffset = value;
	}
	
	private function set_useErosion(value:Bool):Bool
	{
		trailShader.useErosion.value = [value];
		return useErosion = value;
	}
	
	private function set_alphaFadeOffset(value:Float):Float
	{
		trailShader.alphaFadeOffset.value = [value];
		return alphaFadeOffset = value;
	}
	
	private function set_autoDivide(value:Bool):Bool
	{
		trailShader.autoDivide.value = [value];
		return autoDivide = value;
	}
	
	private function set_textureSegments(value:Int):Int
	{
		trailShader.textureSegments.value = [value];
		return textureSegments = value;
	}
	
	private function set_textureSegmentLength(value:Float):Float
	{
		trailShader.textureSegmentLength.value = [value];
		return textureSegmentLength = value;
	}
	
	private function set_trailAlpha(value:Float):Float
	{
		trailShader.trail_alpha.value = [value];
		return trailAlpha = value;
	}
}
