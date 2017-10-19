class Particula {

  PVector pos;
  PVector end;
  PVector move;
  color c;
  int maxLife = 1024*5;
  int life;
  boolean aniadidas = false;
  boolean death = false;

  public void init(PVector pos, PVector end, PVector move, color c) {
    this.pos = pos;
    this.move = move;
    this.end =  end;
    this.c = c;
    life = 0;
  }

  public boolean move() {

    pos.add(move);

    List<Point> vecinos = new ArrayList();

    for (Panel p : cosa.getPanels()) {

      if (p.getCells() != null) {
        // int size = 50 / p.getCells().s;  
        for (Cell cell : p.getCells()) {
          for (int i =0; i<cell.polygon.size(); i++) {
            Point point = cell.polygon.get(i);
            PVector vp = new PVector(point.x, point.y);
            if (PVector.dist(vp, new PVector(pos.x, pos.y)) < 5) {
              //añadimos nueva partícula
              if (!aniadidas && particulas.size() < 200 && life > 100) {
                // addParticulas(cell, point, i, life);
                aniadidas = true;
                return true;
              } else {
              }
            }
          }
        }
      }
    }

    
    life++;
    if (life > maxLife) {
      //  println(frameCount+"muerte por viejo aniadidas"+aniadidas);
      death = true;
    }

    if (PVector.dist(pos, end) < 2) {
      //println(frameCount+"muerte por llegar al fin aniadidas"+aniadidas);
      death =  true;
    }

    float x = PVector.sub(end, pos).x;
    float y = PVector.sub(end, pos).y;
    if (move.x > 0 && x < 0) {
      death = true;
    }

    if (move.x < 0 && x > 0) {
      death = true;
    }

    /* if(move.y < 0 && y < 0){
     death = true; 
     }
     
     if(move.y > 0 && y > 0){
     death = true; 
     }*/

    if (death && !aniadidas) {
      for (Panel p : cosa.getPanels()) {
        if (p.getCells() != null)
          for (Cell cell : p.getCells()) {
            for (int i =0; i<cell.polygon.size(); i++) {
              Point point = cell.polygon.get(i);
              PVector vp = new PVector(point.x, point.y);
              if (PVector.dist(vp, pos) < 5) {
                //añadimos nueva partícula
                if (!aniadidas && particulas.size() < 100 && random(10) > 15) {
                   addParticulas(cell, point, i,life);
                  aniadidas = true;
                }
              }
            }
          }
      }

      return false;
    }

    return true;
  }

  public void render(PGraphics canvas) {
    canvas.stroke(c);
    canvas.strokeWeight(3);
    canvas.fill(c);
    canvas.point(pos.x, pos.y);
    float xdif = PVector.sub(end, pos).x;
   // canvas.text(death+":xvel:"+move.x+" xdif:"+xdif, pos.x, pos.y);
  }
}