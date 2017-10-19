
public void drawReposo() {

  background(0);

  fill(255);
  

  cosa.setColor(255);

  render.render(cosa, g);

  List<Particula> particulasParaBorrar = new ArrayList();
 // println("redner");
  for (int i = 0; i<particulas.size(); i++) {
    Particula p = particulas.get(i);
    if (!p.move()) {
      particulasParaBorrar.add(p);
    }

    p.render(g);
  }
  //println("añadiendo particulas");
  particulas.removeAll(particulasParaBorrar);

  if (mousePressed && frameCount % 20 == 0) {
   
  }
}

public void addParticulas(Cell cell, Point point, int i,int old) {
  //vertices contíguos
  int ianterior = i-1;
  int iposterior = i+1;
  //miramos no nos salimos, hacemos lista circular
  if (ianterior < 0)
    ianterior = cell.polygon.size()-1;
  iposterior = iposterior % cell.polygon.size();
  //ya tenemos las posiciones anterior y posterior
  Point nextVertex = cell.polygon.get(iposterior);
  Point prevVertex = cell.polygon.get(ianterior);
  //ahora calculamos los vetores de movimiento
  PVector pos = new PVector(point.x, point.y);
  PVector move = PVector.sub(new PVector(nextVertex.x, nextVertex.y), pos);
  PVector move2 = PVector.sub(new PVector(prevVertex.x, prevVertex.y), pos);
  move.normalize();
  move.div(5);
  move2.normalize();

  Particula particula = new Particula();
  
  particula.init(pos, new PVector(nextVertex.x, nextVertex.y), move, color(255, 0, 0));
  particula.life = old;
  particulas.add(particula);

// Particula particula2 = new Particula();
 // particula2.init(pos, new PVector(prevVertex.x, prevVertex.y), move2, color(255, 0, 0));
 // particula2.life = old;
 // particulas.add(particula2);
}