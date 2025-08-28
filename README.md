<img width="1000" height="300" alt="rn" src="https://github.com/user-attachments/assets/2c740fee-f485-407d-b6df-bcd3e926c88c" />

# DESCRIPTION:
A Haxeflixel Trail Renderer that allows you to create dynamic (ribbon-like) trails with a variety of style options that adds beauty to your trails.
All with the help of Geometry shaders and fragment shaders!
Geometry shaders are used to manipulate the vertices of the sprite efficiently (depends on your GPU).

## HOW TO INSTALL:
run haxelib git trailrenderer https://github.com/Blossomical/Trail-Renderer in your terminal.

put `<haxelib name="trailrenderer" />` in your project.xml

# EXAMPLES:
### 1. Basic flame trail
```hx
trail = new DynamicTrail(BitmapData.fromFile('assets/images/trail.png'), 50, false);
trail.offsetXScrollSpeed = -0.5;
trail.blend = ADD;
trail.setGradient([0xffffee00, 0xffff9100, 0xffe91607, 0xffa10f47, 0xff3f092f]);
add(trail);
trail.quadraticBezier(100, 100, 300, -200, 1000, 600, 12);
```
![trail1](https://github.com/user-attachments/assets/ffac6a92-d3ba-489e-95c8-45c00bc17a78)

### 2. Flame trail with useBrightness enabled
```hx
trail = new DynamicTrail(BitmapData.fromFile('assets/images/trail.png'), 50, false);
trail.offsetXScrollSpeed = -0.5;
trail.blend = ADD;
trail.setGradient([0xffffee00, 0xffff9100, 0xffe91607, 0xffa10f47, 0xff3f092f]);
trail.setStyle(true, true, false);
add(trail);
```
![trail2](https://github.com/user-attachments/assets/cd3201c7-40a9-4957-8cec-df6e36f5211b)

### 3. Flame trail with an erosion texture
```hx
trail = new DynamicTrail(BitmapData.fromFile('assets/images/trail.png'), 100, false);
trail.offsetXScrollSpeed = -1;
trail.blend = ADD;
trail.setGradient([0xffffee00, 0xffff9100, 0xffe91607, 0xffa10f47, 0xff3f092f]);
trail.setStyle(true, true, true, true, BitmapData.fromFile('assets/images/fire2.png'), 0.8);
add(trail);
```
![trail3](https://github.com/user-attachments/assets/0da1fbd5-7235-497b-a206-412fcfc3038e)

### 4. Chain trail with auto division enabled
```hx
trail = new DynamicTrail(BitmapData.fromFile('assets/images/chain.png'), 50, false);
trail.offsetXScrollSpeed = -1;
trail.blend = ADD;
trail.setGradient([0xffffee00, 0xffff9100, 0xffe91607, 0xffa10f47, 0xff3f092f]);
trail.setStyle(true, true, true, true);
trail.autoDivide = true;
trail.textureSegmentLength = 250;
add(trail);
trail.quadraticBezier(400, 400, 200, -200, 800, 400, 30);
```
![trail3](https://github.com/user-attachments/assets/15ac462e-4c6d-4394-beb3-a72b1895309f)
