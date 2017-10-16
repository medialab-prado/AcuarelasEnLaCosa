
public class Data {
  float brightness = 0;
  float contrast= 0;
  float smooth = 0.05;
}


public void initGUI() {

  cp5 = new ControlP5(this);
  // add a vertical slider
  cp5.addSlider("brightness")
    .setPosition(200, 30)
    .setSize(200, 20)
    .setRange(0, 10)
    .setValue(1)
    .setId(1)
    ;

  cp5.addSlider("contrast")
    .setPosition(200, 50)
    .setSize(200, 20)
    .setRange(0, 2)
    .setValue(1)
    .setId(2)
    ;

  cp5.addSlider("smooth")
    .setPosition(200, 80)
    .setSize(200, 20)
    .setRange(0, 1)
    .setValue(1)
    .setId(3)
    ;
}

void controlEvent(ControlEvent theEvent) {
  println("got a control event from controller with id "+theEvent.getController().getId());

  if (theEvent.isFrom(cp5.getController("n1"))) {
    println("this event was triggered by Controller n1");
  }

  switch(theEvent.getController().getId()) {
    case(1):
    data.brightness = theEvent.getController().getValue();
    break;
    case(2):
    data. contrast = theEvent.getController().getValue();
    break;
    case(3):
    data. smooth = theEvent.getController().getValue();
    break;
  }
}