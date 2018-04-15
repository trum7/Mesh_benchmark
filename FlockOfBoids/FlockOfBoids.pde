/**
 * Flock of Boids
 * by Jean Pierre Charalambos.
 * 
 * This example displays the 2D famous artificial life program "Boids", developed by
 * Craig Reynolds in 1986 and then adapted to Processing in 3D by Matt Wetmore in
 * 2010 (https://www.openprocessing.org/sketch/6910#), in 'third person' eye mode.
 * Boids under the mouse will be colored blue. If you click on a boid it will be
 * selected as the scene avatar for the eye to follow it.
 *
 * Press ' ' to switch between the different eye modes.
 * Press 'a' to toggle (start/stop) animation.
 * Press 'p' to print the current frame rate.
 * Press 'm' to change the mesh visual mode.
 * Press 't' to shift timers: sequential and parallel.
 * Press 'v' to toggle boids' wall skipping.
 * Press 's' to call scene.fitBallInterpolation().
 */

import frames.input.*;
import frames.input.event.*;
import frames.primitives.*;
import frames.core.*;
import frames.processing.*;
Interpolator interpolator, eyeInterpolator;

Shape box, sphere;

float[][] camera_position = {{700.0,450.0,1841.1534,0.0,0.0,0.0,1.0},
{700.0,450.0,1841.1534,0.0,0.0,0.0,1.0},
{700.0,450.0,1176.2366,0.0,0.0,0.0,1.0},
{558.9699,429.0232,1166.2828,0.0097923735,-0.06884898,0.008427616,0.99754345},
{301.66406,394.32178,1094.1323,0.023172138,-0.20000842,0.022907088,0.9792523},
{117.90845,395.9538,993.44727,0.017795809,-0.29951322,0.031960174,0.95339066},
{-87.86963,370.68298,802.7822,0.020304227,-0.4266123,0.0479369,0.9029351},
{96.56166,389.2993,650.3383,0.020304227,-0.4266123,0.0479369,0.9029351},
{-26.789734,364.94977,437.58273,0.023654677,-0.56386083,0.06170722,0.8232215},
{-66.762085,315.6216,260.35947,0.04529034,-0.65530527,0.07867021,0.74988997},
{-65.64215,286.75757,77.14983,0.06165967,-0.7380695,0.08506041,0.6664955},
{-14.787903,247.02121,-106.986664,0.08827228,-0.8113573,0.096966885,0.5696532},
{72.48297,234.22243,-271.69666,0.109178044,-0.8711735,0.098378755,0.46846408},
{171.22144,244.86772,-394.49957,0.12329743,-0.9128227,0.091213465,0.37846065},
{244.40366,270.6849,-352.83676,0.1249714,-0.91915023,0.08901636,0.36279628},
{376.84653,325.03308,-460.34552,0.12869379,-0.95902586,0.05914767,0.24537508},
{463.067,363.385,-504.92517,0.12542354,-0.975719,0.039899603,0.17507008},
{584.9826,430.20547,-542.0586,0.11804621,-0.98979014,0.0038628224,0.07978499},
{674.1124,460.97375,-551.2665,0.11386538,-0.99335706,-0.010351352,0.013017292},
{833.42896,463.4065,-538.8985,0.0999382,-0.98989135,-4.599746E-4,-0.10063435}};


Scene scene;
Quaternion qua;
PShape pboid;  // The PShape object
int flockWidth = 1400;
int flockHeight = 900;
int flockDepth = 300;
boolean avoidWalls = true;
String foler_path = "./meshes/";
String mesh_name = "finalfinal";
float scale_value = 1;
String[] pts_file;
String[] faces_file;
String[] connection_file;
PVector[] pts;
String[][] faces;
String[][] connections;
String[][] representation;
// visual modes
// 0. Faces and edges
// 1. Wireframe (only edges)
// 2. Only faces
// 3. Only points
int mode;

//rep = False -> Vertex-Vertex
//rep = True -> Face-Vertex
boolean rep = false;
boolean retained = false;
// 0. Face-Vertex
// 1. Vertex-Vertex
Eye eye;
ArrayList<Boid> flock= new ArrayList();
int initBoidNum = 1000; // amount of boids to start the program with
Node avatar;
boolean animate = true;
PShape pbox, psphere;
color  fill_shape = color(138,43,226,125);
color  stroke_shape = color(0,191,255);
PrintWriter output;

void setup() {
  size(1000, 800, P3D);
  pts_file = loadStrings(foler_path + mesh_name + ".vertices");
  faces_file = loadStrings(foler_path + mesh_name + ".faces");
  connection_file = loadStrings(foler_path + mesh_name + ".vertexvertex");
  getBird();
  scene = new Scene(this);
  qua = new Quaternion();
  scene.setBoundingBox(new Vector(0, 0, 0), new Vector(flockWidth, flockHeight, flockDepth));
  scene.setAnchor(scene.center());
  eye = new Eye(scene);
  scene.setEye(eye);
  scene.setFieldOfView(PI / 3);
  //interactivity defaults to the eye
  scene.setDefaultGrabber(eye);
  scene.fitBall();
  drawBoid(); 
  
  for (int i = 0; i < initBoidNum; i++)
    flock.add(new Boid(new Vector(flockWidth / 2, flockHeight / 2, flockDepth / 2)));
  // create and fill the list of boids

  camerainterpolator();
  output = createWriter("./Benchmarks/Laura/Immediate-VV.txt");
  output.println("FrameCount,FrameRate");

}



void draw() {
  background(0);
  ambientLight(128, 128, 128);
  directionalLight(255, 255, 255, 0, 1, -100);
  walls();
  titles();
  // Calls Node.visit() on all scene nodes.
  scene.traverse();
  if(frameCount <201){
      output.println(frameCount+","+frameRate);
  }else{
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
    //exit(); // Stops the program
  }  
}

void camerainterpolator(){
    
    // interpolation 2. Custom eye interpolations
    eyeInterpolator = new Interpolator(eye);
    // Create an initial path
  
    for (int i = 0; i < camera_position.length; i++) {
      Node node = new OrbitNode(scene);
      node.randomize();
      eyeInterpolator.addKeyFrame(new Frame(new Vector(camera_position[i][0], camera_position[i][1], camera_position[i][2]), new Quaternion(camera_position[i][3], camera_position[i][4], camera_position[i][5], camera_position[i][6])));
    }
    eyeInterpolator.setLoop();
    
    eyeInterpolator.start(); 
    println(eyeInterpolator.duration());
    println(eyeInterpolator.period());
}


void walls() {
  pushStyle();
  noFill();
  stroke(255);

  line(0, 0, 0, 0, flockHeight, 0);
  line(0, 0, flockDepth, 0, flockHeight, flockDepth);
  line(0, 0, 0, flockWidth, 0, 0);
  line(0, 0, flockDepth, flockWidth, 0, flockDepth);

  line(flockWidth, 0, 0, flockWidth, flockHeight, 0);
  line(flockWidth, 0, flockDepth, flockWidth, flockHeight, flockDepth);
  line(0, flockHeight, 0, flockWidth, flockHeight, 0);
  line(0, flockHeight, flockDepth, flockWidth, flockHeight, flockDepth);

  line(0, 0, 0, 0, 0, flockDepth);
  line(0, flockHeight, 0, 0, flockHeight, flockDepth);
  line(flockWidth, 0, 0, flockWidth, 0, flockDepth);
  line(flockWidth, flockHeight, 0, flockWidth, flockHeight, flockDepth);
  popStyle();
}

void getBird(){
  if(pts_file != null && faces_file != null){
    pts = new PVector[pts_file.length];
    for(int i = 1; i < pts_file.length; i++){
      String[] vector = splitTokens(pts_file[i], " ");
      pts[i - 1] = new PVector(float(vector[0])*scale_value, float(vector[1])*scale_value, float(vector[2])*scale_value);      
    }
    faces = new String[faces_file.length-1][];
    for(int i = 1; i <= faces.length; i++){
      faces[i-1] = splitTokens(faces_file[i], " ");
    }
    connections = new String[connection_file.length-1][];
    for(int i = 1; i <= connections.length; i++){
      connections[i-1] = splitTokens(connection_file[i], " ");
    }
  }
}


void keyPressed() {
  switch (key) {
  case('1'):
     eyeInterpolator.addKeyFrame(scene.eye().get());
     println("{" + str(scene.eye().position().x()) + "," + str(scene.eye().position().y()) + "," + str(scene.eye().position().z()) + "," + str(scene.eye().orientation().x()) + "," + str(scene.eye().orientation().y()) + "," + str(scene.eye().orientation().z()) + "," + str(scene.eye().orientation().w()) + "},"  );
     
  case 'a':
    animate = !animate;
    break;
  case 's':
    if (scene.eye().reference() == null)
      scene.fitBallInterpolation();
    break;
  case 't':
    scene.shiftTimers();
    break;
  case 'p':
    println("Frame rate: " + frameRate);
    break;
  case 'v':
    avoidWalls = !avoidWalls;
    break;
  case 'm':
    mode = mode < 3 ? mode+1 : 0;
    break;
  case 'r':
    rep = !rep;
    resetFlock();
    break;  
  case 'q':
    retained = !retained;
    resetFlock();
    break;
  case ' ':
    if (scene.eye().reference() != null) {
      scene.lookAt(scene.center());
      scene.fitBallInterpolation();
      scene.eye().setReference(null);
    } else if (avatar != null) {
      scene.eye().setReference(avatar);
      scene.interpolateTo(avatar);
    }
    break;
  }
}


void resetFlock(){ 
  if (retained)
      drawBoid();   
  for (int i = 0; i < initBoidNum; i++)
    flock.get(i).setPos(new Vector(flockWidth / 2, flockHeight / 2, flockDepth / 2));
}

void drawBoid(){
  int kind =TRIANGLES;
  pushStyle();
  strokeWeight(2);
  stroke(stroke_shape);
  fill(fill_shape);
  // visual modes
  switch(mode) {
  case 1:
    noFill();
    break;
  case 2:
    noStroke();
    break;
  case 3:
    strokeWeight(3);
    kind = POINTS;
    break;
  }
  meshRep();
  pboid = createShape();
  pboid.beginShape();  
  for(int i = 0; i < representation.length; i++){  
    for(int j = 0; j < representation[i].length ; j++){
      pboid.vertex(pts[Integer.parseInt(representation[i][j])].x, pts[Integer.parseInt(representation[i][j])].y, pts[Integer.parseInt(representation[i][j])].z);
    }   
  }
  pboid.endShape();  
  popStyle();
}

void meshRep(){
  if(rep){
    representation = faces;
    fill_shape = color(138,43,226,125);
    stroke_shape = color(0,191,255);
  }else{
    representation = connections; 
    fill_shape = color(255, 0, 0, 125);
    stroke_shape = color(0, 255, 0);
  }
}
void titles(){
  scene.beginScreenCoordinates();
  textSize(20);
  fill(255,140,0);
  text(retained?"Retained":"Immediate", 150, 35);
  text(rep?"Face-Vertex":"Vertex-Vertex", 350, 35);
  text("FPS: "+frameRate, 550, 35);
  scene.endScreenCoordinates();
}
