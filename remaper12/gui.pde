
public class Data {
  float brightness = 1;
  float contrast= 1;
  float smooth = 0.05;
  float threshold = 500;
}

RadioButton r1;
public void initGUI() {

  cp5 = new ControlP5(this);
  // add a vertical slider
  cp5.addSlider("brightness")
    .setPosition(200, 30)
    .setSize(200, 20)
    .setRange(0, 10)
    .setValue(data.brightness)
    .setId(1)
    ;

  cp5.addSlider("contrast")
    .setPosition(200, 50)
    .setSize(200, 20)
    .setRange(0, 4)
    .setValue(data.contrast)
    .setId(2)
    ;

  cp5.addSlider("smooth")
    .setPosition(200, 80)
    .setSize(200, 20)
    .setRange(0, 1)
    .setValue(data.smooth)
    .setId(3)
    ;
    
    
    cp5.addSlider("threshold")
    .setPosition(600, 80)
    .setSize(200, 20)
    .setRange(100, 1000)
    .setValue(data.threshold)
    .setId(4)
    ;

  r1 = cp5.addRadioButton("MODOS")
    .setPosition(500, 40)
    .setSize(40, 20)
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .setItemsPerRow(5)
    .setSpacingColumn(50)
    .addItem("MODE CONF", 0)
    .addItem("MODE PLAY", 1)
    .addItem("MODE WAITTING", 3);
  ;
}

void controlEvent(ControlEvent theEvent) {
//  println("got a control event from controller with id "+theEvent.getController().getId());

  if (theEvent.isFrom(r1)) {
    
      mode = (int)theEvent.getValue();
    
  } else {

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
       case(4):
      data. threshold = theEvent.getController().getValue();
      break;
      
    }
  }
}