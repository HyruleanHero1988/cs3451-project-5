/**
 * Robert Kernan
 * Qiqin Xie
 * Raymond Garrison
 */

import processing.opengl.*;
import javax.media.opengl.*; 
import javax.media.opengl.glu.*; 
import java.nio.*;

GL gl;
GLU glu;

// save file
String filename = "data/start.pts";

// view
Vector vI;
Vector vJ;
Vector vK;
Point vQ;
Point vF;
Point vE;
Vector vU;
// display help
boolean show_help = false;
// shading mode
boolean smooth_shading = false;
// display mode
boolean show_mesh = false;
boolean show_tnorm = false;
boolean show_vnorm = false;
// animate
boolean animate = false;
float curr_anim_time = 0;
float frame_rate = 1.0 / 60.0;
float max_anim_time = 1;
// edit mode
boolean mode_edit = false;
Point selected = null;
// shapes
int curr_shape = 0;
int num_shapes = 4;
int num_sides = 6;
ShapeFrame[] shapes = new ShapeFrame[num_shapes];
ShapeMorph morph;

void initView() {
  vQ = new Point(0, 0, 0);
  vI = new Vector(1, 0, 0);
  vJ = new Vector(0, 1, 0);
  vK = new Vector(0, 0, 1);
  vF = new Point(0, 0, 0);
  vE = new Point(0, 0, 3000);
  vU = new Vector(0, 1, 0);
  setFrame(vQ, vI, vJ, vK);
}

void setup() {
  size(1024, 768, OPENGL); 
  setColors();
  sphereDetail(12);
  rectMode(CENTER);
  glu = ((PGraphicsOpenGL)g).glu;
  PGraphicsOpenGL pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  pgl.endGL();
  // load font
  textFont(loadFont("Courier-14.vlw"), 12);
  // init view
  initView();
  // init
  for (int i = 0; i < num_shapes; i++) {
    shapes[i] = new ShapeFrame(num_sides);
  }
  morph = new ShapeMorph(shapes[0].corner_table, shapes[1].corner_table);
  shapes[curr_shape].rotateAxis(radians(90), vI, vJ);
  try {
    loadScene(filename);
    println("loaded scene from file: " + filename);
  }
  catch (IOException ioe) {
    println(ioe.toString());
    println("ERROR: couldn't load from file: " + filename);
  }
}

void draw() {
  // check animation time
  if (curr_anim_time > max_anim_time) {
    curr_anim_time = 0;
  }
  else if (curr_anim_time < 0) {
    curr_anim_time = 0;
  }
  // draw
  hint(DISABLE_DEPTH_TEST);
  background(white);
  // ui
  camera();
  lights();
  fill(black);
  int header_line = 0;
  int footer_line = 0;
  scribeFooter("press '?' to toggle help", footer_line++);
  scribeFooter("display: " + ((show_mesh) ? "SOLID" : "PROFILE") + ", " +
               "shading: " + ((smooth_shading) ? "SMOOTH" : "FLAT"), footer_line++);
  scribeFooter("current shape: " + (curr_shape + 1) + ", animation: " + ((animate) ? "ON " : "OFF") + " (" + nf(curr_anim_time, 1, 2) + "s)", footer_line++);
  if (show_help) {
    scribe("SAVE/LOAD (file:\"" + filename + "\")", header_line++);
    scribe("  save scene: 'W'", header_line++);
    scribe("  load scene: 'L'", header_line++);
    scribe("VIEW", header_line++);
    scribe("  rotate view:  mousedrag", header_line++);
    scribe("  zoom view in/out:  'd' + mousedrag", header_line++);
    scribe("  show mesh:  'm' (toggle)", header_line++);
    scribe("  use smooth shading: 'g' (toggle)", header_line++);
    scribe("  show vertex normals: 'v' (toggle)", header_line++);
    scribe("  show triangle normals: 't' (toggle)", header_line++);
    scribe("EDIT SHAPE (toggle with 'e')", header_line++);
    scribe("  change shape: '1'-'4'", header_line++);
    scribe("  add control point: 'i' + mouseclick", header_line++);
    scribe("  delete control point: 'd' + mouseclick", header_line++);
    scribe("  selelect control point: mouseclick", header_line++);
    scribe("  move selected point: select + mousedrag", header_line++);
    scribe("  make convex: 'C'", header_line++);
    scribe("  move the origin: 'p' + mousedrag", header_line++);
    scribe("  move the axis: 'o' + mousedrag", header_line++);
    scribe("  rotate the shape: 'l' + mousedrag", header_line++);
  }
  else {
    scribe("CS3451-A Fall 2012 - Project 5", header_line++);
  }
  // edit shape
  if (mode_edit) {
    stroke(red);
    fill(red);
    shapes[curr_shape].drawFrame();
    noStroke();
    fill(black);
    scribeFooter("EDITING SHAPE " + (curr_shape + 1) + ", " + 
                 "num sides = " + shapes[curr_shape].num_sides + ", " + 
                 "axis = <" + shapes[curr_shape].axis.x + ", " + shapes[curr_shape].axis.y + ", " + shapes[curr_shape].axis.z + ">", footer_line++);
    noFill();
  }
  // enable z-buffer
  hint(ENABLE_DEPTH_TEST);
  // setup scene lights
  Vector Li = add(new Vector(vE, vF), mult(vJ, 0.1 * (new Vector(vE, vF)).norm()));
  directionalLight(255, 255, 255, Li.x, Li.y, Li.z);
  specular(255, 255, 0);
  shininess(5);
  // move camera
  camera(vE.x, vE.y, vE.z, vF.x, vF.y, vF.z, vU.x, vU.y, vU.z);
  // draw mesh
  if (show_mesh) {
    fill(cyan);
    stroke(black);
    shapes[curr_shape].drawMesh(smooth_shading);
    noFill();
    noStroke();
  }
  else {
    stroke(black);
    shapes[curr_shape].drawOutline();
    noStroke();
  }
  if (show_tnorm) {
    stroke(orange);
    shapes[curr_shape].corner_table.drawTriangleNormals();
    noStroke();
  }
  if (show_vnorm) {
    stroke(orange);
    shapes[curr_shape].corner_table.drawVertexNormals();
    noStroke();
  }
  // update animation
  if (animate) {
    curr_anim_time += frame_rate;
  }
}

void mousePressed() {
  if (mode_edit) {
    if (keyPressed) {
      // add point
      if (key == 'i') {
        shapes[curr_shape].addVertex(getMouse());
        shapes[curr_shape].alignEdge();
        shapes[curr_shape].createOutlineAndMesh();
      }
      // remove point
      if (key == 'd') {
        shapes[curr_shape].deleteClosestVertex(getMouse());
        shapes[curr_shape].alignEdge();
        shapes[curr_shape].createOutlineAndMesh();
      }
    }
    // select point
    else {
      selected = shapes[curr_shape].getClosestVertex(getMouse());
    }
  }
} 

void mouseDragged() {
  if (mode_edit) {
    // convert to convex
    if (keyPressed && key == 'C') {
      // TODO
      shapes[curr_shape].createOutlineAndMesh();
    }
    // move the origin
    else if (keyPressed && key == 'p') {
      shapes[curr_shape].moveBy(add(mult(vI, float(mouseX - pmouseX)), mult(vJ, -float(mouseY - pmouseY))));
      shapes[curr_shape].createOutlineAndMesh();
    }
    // spin current shape
    else if (keyPressed && key == 'l') {
      shapes[curr_shape].spin(-0.1 * float(mouseX - pmouseX));
      shapes[curr_shape].createOutlineAndMesh();
    }
    // rotate current shape axis
    else if (keyPressed && key == 'o') {
      shapes[curr_shape].rotateAxis(-0.1 * float(mouseX - pmouseX), vI, vJ);
      shapes[curr_shape].createOutlineAndMesh();
    }
    // move selected point
    else if (selected != null) {
      selected.add(getMouseDrag());
      shapes[curr_shape].alignEdge();
      shapes[curr_shape].createOutlineAndMesh();
    }
  }
  else if (!animate && keyPressed && key == 't') {
    curr_anim_time += 0.001 * float(mouseX - pmouseX);
  }
  // move view
  else {
    boolean moved = true;
    if (!keyPressed && mousePressed) {
      vE = rotate(vE, PI * float(mouseX - pmouseX) / width, vI, vK, vF);
      vE = rotate(vE, -PI * float(mouseY - pmouseY) / width, vJ, vK, vF);
      moved = true;
    }
    if (keyPressed && key == 'd'&& mousePressed) {
      vE.add(mult(vK, -float(mouseY - pmouseY)));
      moved = true;
    }
    if (moved) {
      setFrame(vQ, vI, vJ, vK);
    }
  }
}

void keyReleased() {
  // switch current shape
  if (key == '1') {
    curr_shape = 0;
  }
  else if (key == '2') {
    curr_shape = 1;
  }
  else if (key == '3') {
    curr_shape = 2;
  }
  else if (key == '4') {
    curr_shape = 3;
  }
  // toggle display mode
  if (key == 'm') {
    show_mesh = !show_mesh;
  }
  // toggle shading mode
  if (key == 'g') {
    smooth_shading = !smooth_shading;
  }
  // toggle edit mode
  if (key == 'e') {
    mode_edit = !mode_edit;
  }
  if (key == ' ') {
    animate = !animate;
  }
  // toggle help dialog
  if (key == '?') {
    show_help = !show_help;
  }
  // toggle triangle normals
  if (key == 't') {
    show_tnorm = !show_tnorm;
  }
  // toggle vertex normals
  if (key == 'v') {
    show_vnorm = !show_vnorm;
  }
  // make convex
  if (key == 'C') {
    shapes[curr_shape].makeConvex();
  }
  // write shapes
  if (key == 'W') {
    try {
      saveScene(filename);
      println("saved scene to file: " + filename);
    }
    catch (IOException ioe) {
      println(ioe);
      println("ERROR: couldn't save to file: " + filename);
    }
  }
  // load shapes
  if (key == 'L') {
    try {
      loadScene(filename);
      println("loaded scene from file: " + filename);
    }
    catch (IOException ioe) {
      println(ioe.toString());
      println("ERROR: couldn't load from file: " + filename);
    }
  }
}

void keyPressed() {
  if (key == ',') {
    shapes[curr_shape].num_sides = (shapes[curr_shape].num_sides - 1 < 3) ? 3 : shapes[curr_shape].num_sides - 1;
    shapes[curr_shape].createOutlineAndMesh();
  }
  if (key == '.') {
    shapes[curr_shape].num_sides++;
    shapes[curr_shape].createOutlineAndMesh();
  }
}
