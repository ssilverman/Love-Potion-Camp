/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/21319*@* */
/* !do not delete the line above, required for linking your tweak if you re-upload */
//Yuriy Flyud. Feb.19.2011.Tunnel Applet

import java.awt.geom.Area;
import java.awt.geom.PathIterator;
import java.awt.geom.GeneralPath;

class Tunnel extends Drawer {

  final float NOISE_FALLOFF = 0.5f;
  final int NUMBER_OF_CIRCLES = 4;
  final int NUMBER_OF_GLOWS = 21;
  final public int NUMBER_OF_LAYERS = 20;//65;

  
  Tunnel(Pixels p, Settings s) {
    super(p, s, P3D);
  }

  String getName() { return "Tunnel"; }

  LayerCollection lCol = new LayerCollection(NUMBER_OF_CIRCLES);
  GlowCollection glowCol = new GlowCollection(NUMBER_OF_GLOWS);
  
  int colorIndex = (int)random(1000);
  
  //help Variable
  final int layerDev = lCol.DEPTH / NUMBER_OF_LAYERS;
  
  public PImage im;
  
  void setup() {
    noCursor();
    pg.strokeWeight(2);
    im = loadImage("light.png");
  }
  
  void draw() {
    pg.noFill();
    pg.strokeWeight(2);
    noiseDetail(1, NOISE_FALLOFF);
    colorMode(RGB,255);
    pg.colorMode(RGB,255);

    lCol.nextStep();
    performCamera();
    //draw Light Glows
    if (lCol.list.size() > NUMBER_OF_LAYERS) {
      glowCol.nextStep(lCol);
      glowCol.drawIt(lCol);
    }
    //draw Tunnel
    pg.smooth();
    drawTunnel();
    pg.noSmooth();
    //make delay effect
    pg.camera();
    pg.noStroke();
    pg.fill(0, 50);
    pg.rect(0, 0, width, height);
    //"Clean" lCol of layers
    if (lCol.list.size() > NUMBER_OF_LAYERS)
      lCol.list.remove(0);
    colorIndex += 1;
  }
  
  private void performCamera()
  {
    float X_OFFSET = -100;
    float Y_OFFSET = -50;
    //sorry for this...
    if(lCol.list.size()>5)
      pg.camera(lCol.list.get(0).getCenter().x, lCol.list.get(0).getCenter().y, 0,
                lCol.list.get(5).getCenter().x + X_OFFSET, lCol.list.get(5).getCenter().y + Y_OFFSET, -lCol.DEPTH/ 2,
                0, 1, 0);
    else
      pg.camera(lCol.list.get(0).getCenter().x, lCol.list.get(0).getCenter().y, 0,
                lCol.list.get(0).getCenter().x + X_OFFSET, lCol.list.get(0).getCenter().y + Y_OFFSET, -lCol.DEPTH/ 2,
                0, 1, 0);
  }
  
  public void drawTunnel() {
    int enumerator = 0;
    for (CircleLayer layer : lCol.list) {
      enumerator++;
      for (List<PVector> l : layer.getLayer()) {
        pg.stroke(getColorForLayer(NUMBER_OF_LAYERS - enumerator, 1));
        pg.beginShape();
        for (PVector p : l) {
          pg.vertex(p.x, p.y, p.z);
          p.z += layerDev;
        }
        pg.endShape(CLOSE);
      }
    }
  }
  
  public int getColorForLayer(int layerNumber, int transCoef)
  {
    float layerRange = (getNumColors()/1.0) / NUMBER_OF_LAYERS + 1;
    layerRange = 2;
    color result = getColor(round((layerRange + transCoef) * layerNumber) % getNumColors());
    float alpha;
    alpha = 50 * transCoef;
    assert(alpha >= 0 && alpha <= 255.0) : "invalid alpha: " + alpha + " layerNumber: " + layerNumber;
    result = replaceAlpha(result, alpha);
    return result;

  }
  
  //Just paints Light Glows flying along the tunnel
  public class GlowCollection {
    public List<Glow> list;
    
    public GlowCollection(int numGlows) {
      this.list = new ArrayList<Glow>();
      for (int i = 0; i < numGlows; i++)
        list.add(new Glow((int)random(2), 10, 225, 0.3f));
    }
    
    public void nextStep(LayerCollection col) {
      for (Glow r : list)
        r.update(col);
    }
    
    public void drawIt( LayerCollection col) {
      for (Glow r : list)
        r.drawIt(col);
    }
  }
  
  class Glow {
    float curLayerNum;
    int curCircle;
    
    int speed;
    PVector dev;
    int maxSpeed;
    
    public Glow(int ccurCircle, int cmaxSpeed, int rad, float oval) {
      this.curLayerNum = 0;
      this.curCircle = ccurCircle;
      
      this.dev = new PVector();
      this.maxSpeed = cmaxSpeed;
      this.speed = (int)random(1,maxSpeed);
      
      dev.x = random(-rad,rad);
      dev.y = random(-rad,rad) * sin(map(dev.x, -(float) rad, (float) rad, -PI, 0));
    }
    
    public void update(LayerCollection col) {
      float factor = settings.getParam(settings.keySpeed) + 0.1;
      curLayerNum += speed * factor;
      if (curLayerNum > col.list.size() - 1) {
        curLayerNum = 0;
        this.speed = (int)random(1,maxSpeed);
      }
    }
    
    public void drawIt(LayerCollection col) {
      int layerNum = round(curLayerNum);

      //pg.tint(getColorForLayer(NUMBER_OF_LAYERS - layerNum, 5));
      pg.pushMatrix();
      
      //hard to read, but easy to understand
      pg.translate(col.list.get(layerNum).getOneCenter(curCircle).x + dev.x,
                   col.list.get(layerNum).getOneCenter(curCircle).y + dev.y,
                   col.list.get(layerNum).getLayer().get(0).get(0).z);
      
      float imgScale = 1.5;
      pg.image(im, 0, 0, im.width * imgScale, im.height * imgScale);

      pg.popMatrix();
    }
  }
  
  
  
  public class LayerCollection {
    public final float BORDERS_WIDTH = 800;
    public final float BORDERS_HEIGHT = 600;
    
    public final int CIRCLE_RADIUS = 220;
    public final int CIRCLE_DETAIL = 5;
    public final float CIRCLE_OVAL = 0.7f;
    public final int DEPTH = 1000;
    public final float ROT_DEV = PI / 100;
    
    public List<CircleLayer> list = new ArrayList<CircleLayer>();
    
    private  CircleShape[] circles;
    private float[] coords = new float[6];
    private float rotAngle=0;
    
    public LayerCollection(int numCircles) {
      circles = new CircleShape[numCircles];
      for (int i = 0; i < circles.length; i++)
        circles[i] = new CircleShape();
    }
    
    public void nextStep() {
      refreshCircles(BORDERS_WIDTH, BORDERS_WIDTH);
      list.add(getShape());
    }
    
    public void refreshCircles(float w, float h) {
      for (int i = 0; i < circles.length; i++) {
        circles[i].generateCenter(w, h);
      }
      rotAngle += ROT_DEV;
    }
    
    public CircleLayer getShape() {
      CircleLayer layer = new CircleLayer(circles.length);
      Area area = circles[0].getShape(CIRCLE_RADIUS, CIRCLE_DETAIL,CIRCLE_OVAL,rotAngle);
      layer.initCenter(0, circles[0].center);
      
      for (int i = 1; i < circles.length; i++) {
        area.add(circles[i].getShape(CIRCLE_RADIUS, CIRCLE_DETAIL, CIRCLE_OVAL,rotAngle));
        layer.initCenter(i, circles[i].center);
      }
      
      for (PathIterator i = area.getPathIterator(null); !i.isDone(); i.next()) {
        int type = i.currentSegment(coords);
        switch (type) {
          case PathIterator.SEG_MOVETO:
            layer.addShape();
            layer.addPoint(new PVector(coords[0], coords[1], -DEPTH));
            break;
          case PathIterator.SEG_LINETO:
            layer.addPoint(new PVector(coords[0], coords[1], -DEPTH));
            break;
          case PathIterator.SEG_CLOSE:
            break;
          default:
            // throw new Exception("error in constructing new Shape");
        }
      }
      return layer;
    }
  }
  
  //Represents circle as instance of GeneralPath, and moves it (noise()) in 2D(XY) space
  public class CircleShape {
    
    private PVector center;
    private GeneralPath shape = new GeneralPath();
    
    
    //Noise parameters
    PVector offset;
    PVector increment;
    
    public CircleShape() {
      center = new PVector(0, 0, 0);
      offset = new PVector(0, 0);
      increment = new PVector(random(0.15,0.25),random(0.15,0.25));
    }
    
    public void generateCenter(float w, float h) {
      offset.x += increment.x;
      offset.y += increment.y;
      
      float noiseX = noise(offset.x * 0.05f);
      float noiseY = noise(offset.y * 0.05f);

      if (settings.isBeat(0)) {
        noiseX *= 0.75;
      }
      if (settings.isBeat(2)) {
        noiseY *= 0.75;
      }
      
      center.x = w / 2 - noiseX * w;
      center.y = h / 2 - noiseY * h;
    }
    
    public Area getShape(float rad, float det, float oval, float rot) {
      shape.reset();
      shape.moveTo(center.x + rad * cos(rot), center.y + rad * sin(rot) * 0.3f);
      for (int i = 1; i < det; i++) {
        shape.lineTo(
                     center.x + rad * cos(rot + TWO_PI / det * i),
                     center.y + rad * sin(rot + TWO_PI / det * i) * oval);
      }
      shape.closePath();
      return new Area(shape);
    }
  }
  
  //One layer of a tunnel. Keeps a list of Areas(represented as list of points), and centers of each CirclesShape.
  public class CircleLayer {
    private List<List<PVector>> list = new ArrayList<List<PVector>>();
    private PVector[] centers;
    
    public CircleLayer(int numCenters) {
      centers = new PVector[numCenters];
    }
    
    public void initCenter(int num, PVector center) {
      this.centers[num] = new PVector(center.x, center.y, center.z);
    }
    
    public PVector getCenter() {
      return centers[0];
    }
    
    public PVector getOneCenter(int num) {
      return centers[num];
    }
    
    public void addShape() {
      list.add(new ArrayList<PVector>());
    }
    
    public List<List<PVector>> getLayer() {
      return list;
    }
    
    public void addPoint(PVector p) {
      list.get(list.size() - 1).add(p);
    }
    
    public void finalize() throws Throwable {
      list.clear();
      super.finalize();
    }
  }
  
  
}