import nub.primitives.*;
import nub.core.*;
import nub.processing.*;

// 1. Nub objects
PShader shader;
Scene scene;
Node node, nodeHint;
Vector v1, v2, v3;
Vector v1_node, v2_node, v3_node;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;

// 2. Model color to render to
boolean cmy;
boolean triangleHint = false;
boolean gridHint = true;
boolean debug = true;
boolean shadeHint = false;

// 3. P2D or P3D
String renderer = P3D;

// 4. Window dimension
int dim = 10;

void settings() {
  size(int(pow(2, dim)), int(pow(2, dim)), renderer);
}

void setup() {
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fit(1);

  spinningTask = new TimingTask() {
    @Override
    public void execute() {
      scene.eye().orbit(scene.is2D() ? new Vector(0, 0, 1) :
        yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100);
    }
  };

  nodeHint = new Node() {
    @Override
    public void graphics(PGraphics pg) {
      pg.noStroke();
      pg.beginShape(TRIANGLES);
      pg.fill(255, 0, 0);
      pg.vertex(v1.x(), v1.y());
      pg.fill(0, 255, 0);
      pg.vertex(v2.x(), v2.y());
      pg.fill(0, 0, 255);
      pg.vertex(v3.x(), v3.y());
      pg.endShape();
    }
  };
  
  node = new Node();
  node.setScaling(width/pow(2, n));
  
  // init the triangle that's gonna be rasterized
  randomizeTriangle();
  //shader = loadShader("frag.glsl", "vert.glsl");
  // same as:
  shader = loadShader("frag.glsl");
  // don't forget to ask why?
  if (triangleHint)
    shader(shader);
  else
    resetShader();
}

/*
void draw() {
  background(0);
  scene.drawAxes();
  scene.render();
}
*/

// /*
void draw() {
  background(0); 
  if (gridHint) {
    stroke(0, 255, 0);
    scene.drawGrid(scene.radius(), (int)pow(2, n));
  }
  if (triangleHint)
    scene.render();
  else {
    push();
    scene.applyTransformation(node);
    triangleRaster();
    pop();
  }
}
// */

void keyPressed() {
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't') {
    triangleHint = !triangleHint;
    if (triangleHint)
      shader(shader);
    else
      resetShader();
  }
  if (key == 's')
    shadeHint = !shadeHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 8 ? n+1 : 2;
    node.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 8;
    node.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run();
  if (key == 'y')
    yDirection = !yDirection;  
  if (key == 'a')
    max_depth = (max_depth  == 4 ? 0 : 4);
  if (key == 'c') {
    cmy = !cmy;
    shader.set("cmy", cmy);
  }
}

void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
}

int max_depth = 3;

int GetNumberSubPixelsIn(Vector down_left, Vector up_right, int cur_depth) {

  if (cur_depth == max_depth)
    return IsPointInsideTriangle( new Vector((up_right.x()+down_left.x())/2, (up_right.y()+down_left.y())/2), 
      v1_node, v2_node, v3_node) ? 1 : 0;

  int num_inter = 0;
  Vector vec1 = new Vector(down_left.x(), (up_right.y()+down_left.y())/2.0); 
  Vector vec2 = new Vector((up_right.x()+down_left.x())/2.0, up_right.y()); 
  num_inter += GetNumberSubPixelsIn(vec1, vec2, cur_depth+1);

  vec1 = new Vector((up_right.x() + down_left.x())/2.0, (up_right.y()+down_left.y())/2.0); 
  vec2 = new Vector(up_right.x(), up_right.y()); 
  num_inter += GetNumberSubPixelsIn(vec1, vec2, cur_depth+1);

  vec1 = new Vector( down_left.x(), down_left.y()); 
  vec2 = new Vector((up_right.x() + down_left.x())/2, (up_right.y()+down_left.y())/2.0); 
  num_inter += GetNumberSubPixelsIn(vec1, vec2, cur_depth+1);

  vec1 = new Vector( (up_right.x() + down_left.x())/2, down_left.y()); 
  vec2 = new Vector(up_right.x(), (up_right.y()+down_left.y())/2.0); 
  num_inter += GetNumberSubPixelsIn(vec1, vec2, cur_depth+1);


  return num_inter;
}


float GetInterPercent(int i, int j) {
  float total = (float) Math.pow(4, max_depth);

  Vector down_left = new Vector( (float) i - 0.5, (float) j - 0.5);
  Vector up_right = new Vector( (float) i + 0.5, (float) j + 0.5);

  float num_in = GetNumberSubPixelsIn(down_left, up_right, 0);

  return num_in/total;
}

float cross_z(Vector a, Vector b) {
  return Vector.cross(a, b, null).z();
}
int norm_sign(float f) {
  return f < 0 ? -1 : 1;
}

boolean IsPointInsideTriangle(Vector p, Vector a, Vector b, Vector c) { 
  int s1 = norm_sign(cross_z(Vector.subtract(a, p), Vector.subtract(a, b)));
  int s2 = norm_sign(cross_z(Vector.subtract(b, p), Vector.subtract(b, c)));
  int s3 = norm_sign(cross_z(Vector.subtract(c, p), Vector.subtract(c, a)));
  return (s1 <= 0 && s2 <= 0 && s3 <= 0) || (s1>=0 && s2 >=0 && s3 >= 0);
}

color GetColor(Vector p, Vector a, Vector b, Vector c) {
  // vertex a = red, vertex b = green, vertex c = blue 
  float two_triangle_area = Vector.cross(Vector.subtract(a, b), Vector.subtract(a, c), null).magnitude();
  float red_level = Vector.cross(Vector.subtract(b, p), Vector.subtract(b, c), null).magnitude()/two_triangle_area; 
  float green_level = Vector.cross(Vector.subtract(c, p), Vector.subtract(c, a), null).magnitude()/two_triangle_area;
  float blue_level = Vector.cross(Vector.subtract(a, p), Vector.subtract(a, b), null).magnitude()/two_triangle_area; 
  color to_return = color(255.0*red_level, 255.0*green_level, 255.0 * blue_level, 150);
  return to_return;
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the node system which has a dimension of 2^n
void triangleRaster() {
  v1_node = new Vector(node.location(v1).x(), node.location(v1).y());
  v2_node = new Vector(node.location(v2).x(), node.location(v2).y());
  v3_node = new Vector(node.location(v3).x(), node.location(v3).y());

  int low_x = Math.min(round(node.location(v1).x()), Math.min(round(node.location(v2).x()), round(node.location(v3).x())));
  int low_y = Math.min(round(node.location(v1).y()), Math.min(round(node.location(v2).y()), round(node.location(v3).y())));
  int gre_x = Math.max(round(node.location(v1).x()), Math.max(round(node.location(v2).x()), round(node.location(v3).x())));
  int gre_y = Math.max(round(node.location(v1).y()), Math.max(round(node.location(v2).y()), round(node.location(v3).y())));

  push();
  noStroke();

  for (int i=low_x-1; i <= gre_x +1; i++) {
    for (int j=low_y-1; j<= gre_y + 1; j++) {
      float opacity = GetInterPercent(i, j);
      if (opacity > 0) {
        Vector p = new Vector(i, j);
        color c = GetColor(p, v1_node, v2_node, v3_node);
        fill(red(c), green(c), blue(c), opacity*255);
        square(i, j, 1);
      }
    }
  }
  pop();
  // node.location converts points from world to node
  // here we convert v1 to illustrate the idea
  if (debug) {
    push();
    noStroke();
    fill(255, 0, 0, 125);
    square(round(node.location(v1).x()), round(node.location(v1).y()), 1);
    pop();
  }
}
